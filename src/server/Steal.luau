-- Steal: the other half of the game. Click a brainrot on somebody else's
-- base to snatch it, carry it home over your head, and set it down on your
-- own base. Slap a carrier to make them drop it. A locked base cannot be
-- stolen from, and a dropped brainrot walks home by itself after a while.

local BaseManager = require(script.Parent:WaitForChild("BaseManager"))
local BrainrotData = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotData"))
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local Net = require(script.Parent:WaitForChild("Net"))
local State = require(script.Parent:WaitForChild("State"))

local Steal = {}

local ctx = nil
local dropped = {} -- [uid] = { entry, model, fromPlayer, returnAt }

function Steal.init(context)
	ctx = context
	-- Dropped brainrots walk home on their own when their timer runs out.
	task.spawn(function()
		while true do
			task.wait(1)
			local now = os.clock()
			for uid, item in pairs(dropped) do
				if now >= item.returnAt then
					dropped[uid] = nil
					local home = item.fromPlayer and State.get(item.fromPlayer)
					if home and home.base and State.freeSlotIndex(home) then
						if item.model then
							item.model:Destroy()
						end
						BaseManager.placeOnSlot(home, item.entry, Steal.onBaseBrainrotClicked)
						if item.fromPlayer then
							ctx.economy.notify(item.fromPlayer, "Your " .. BrainrotData.displayName(item.entry) .. " walked home by itself.")
						end
					else
						if item.model then
							item.model:Destroy()
						end
					end
				end
			end
		end
	end)
end

-- The click handler for brainrots standing on a base: stealing.
function Steal.onBaseBrainrotClicked(player, entry)
	-- Find who owns this brainrot.
	local ownerPlayer = nil
	local ownerState = nil
	for p, state in pairs(State.all()) do
		local found = State.findOwned(state, entry.uid)
		if found then
			ownerPlayer = p
			ownerState = state
			break
		end
	end
	if not ownerState then
		return
	end
	if ownerPlayer == player then
		ctx.economy.notify(player, "That one is already yours!")
		return
	end
	Steal.trySteal(player, ownerPlayer, ownerState, entry)
end

local function attachCarry(player, _entry, model)
	local character = player.Character
	if not character then
		return false
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local body = model.PrimaryPart
	body.Anchored = false
	model:PivotTo(root.CFrame * CFrame.new(0, 4.5, 0))
	local weld = Instance.new("WeldConstraint")
	weld.Name = "CarryWeld"
	weld.Part0 = root
	weld.Part1 = body
	weld.Parent = body
	return true
end

function Steal.trySteal(thief, ownerPlayer, ownerState, entry)
	local thiefState = State.get(thief)
	if not thiefState then
		return
	end
	if thiefState.carrying then
		ctx.economy.notify(thief, "Your hands are full! Put down what you carry first.")
		return
	end
	if State.isLocked(ownerState) then
		ctx.economy.notify(thief, "That base is locked! Come back when the gate is green.")
		return
	end
	-- Take it off the owner's base and put it over the thief's head.
	local taken = BaseManager.removeModel(ownerState, entry.uid)
	if not taken then
		return
	end
	-- removeModel destroys the old model; rebuild it fresh for the carry.
	local model = require(script.Parent:WaitForChild("BrainrotFactory")).build(entry, Vector3.new(0, 10, 0))
	model.Parent = game:GetService("Workspace")
	if not attachCarry(thief, entry, model) then
		model:Destroy()
		BaseManager.placeOnSlot(ownerState, entry, Steal.onBaseBrainrotClicked)
		return
	end
	thiefState.carrying = { entry = entry, model = model, fromPlayer = ownerPlayer }
	ctx.economy.notify(thief, "You stole " .. BrainrotData.displayName(entry) .. "! Run it home to your base!")
	ctx.economy.notify(ownerPlayer, thief.DisplayName .. " stole your " .. BrainrotData.displayName(entry) .. "! Slap them to get it back!")
	ctx.economy.pushUpdate(thief)
	ctx.economy.pushUpdate(ownerPlayer)
end

-- Sets a carried brainrot down on the carrier's own base, if they are
-- standing on it and have a free slot.
function Steal.placeCarried(player)
	local state = State.get(player)
	if not state or not state.carrying then
		return false
	end
	if not state.base then
		return false
	end
	local character = player.Character
	if not character then
		return false
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))
	if not WorldBuilder.isInsideBase(state.base, root.Position) then
		return false
	end
	if not State.freeSlotIndex(state) then
		ctx.economy.notify(player, "Your base is full! Buy more slots in the Shop.")
		return false
	end
	local carried = state.carrying
	state.carrying = nil
	if carried.model then
		carried.model:Destroy()
	end
	BaseManager.placeOnSlot(state, carried.entry, Steal.onBaseBrainrotClicked)
	ctx.economy.notify(player, BrainrotData.displayName(carried.entry) .. " is safe at home now!")
	ctx.economy.pushUpdate(player)
	return true
end

-- Drops what a player carries (slapped, swept away, or left the game).
-- The brainrot lands where they stand and can be picked up by anyone.
function Steal.dropCarried(player, reason)
	local state = State.get(player)
	if not state or not state.carrying then
		return
	end
	local carried = state.carrying
	state.carrying = nil
	local model = carried.model
	if model then
		local body = model.PrimaryPart
		local weld = body:FindFirstChild("CarryWeld")
		if weld then
			weld:Destroy()
		end
		body.Anchored = true
		local character = player.Character
		local at = Vector3.new(0, 1.5 * carried.entry.def.scale, 0)
		if character then
			local root = character:FindFirstChild("HumanoidRootPart")
			if root then
				at = Vector3.new(root.Position.X, 1.5 * carried.entry.def.scale, root.Position.Z)
			end
		end
		model:PivotTo(CFrame.new(at))
		model.Parent = game:GetService("Workspace")
		dropped[carried.entry.uid] = {
			entry = carried.entry,
			model = model,
			fromPlayer = carried.fromPlayer,
			returnAt = os.clock() + Config.CARRY_RETURN_SECONDS,
		}
		local click = body:FindFirstChildOfClass("ClickDetector")
		if click then
			click.MouseClick:Connect(function(clicker)
				Steal.pickupDropped(clicker, carried.entry.uid)
			end)
		end
	end
	if reason then
		ctx.economy.notify(player, reason)
	end
	ctx.economy.pushUpdate(player)
end

-- Picks a dropped brainrot off the ground and carries it.
function Steal.pickupDropped(player, uid)
	local item = dropped[uid]
	if not item then
		return
	end
	local state = State.get(player)
	if not state or state.carrying then
		return
	end
	dropped[uid] = nil
	local model = item.model
	if not attachCarry(player, item.entry, model) then
		-- No character to carry it: put it back on the ground to be picked up.
		dropped[uid] = item
		return
	end
	state.carrying = { entry = item.entry, model = model, fromPlayer = item.fromPlayer }
	ctx.economy.notify(player, "Picked up " .. BrainrotData.displayName(item.entry) .. "! Get it home!")
	ctx.economy.pushUpdate(player)
end

-- Slap! Knocks a carried brainrot out of the nearest carrier in range and
-- sends them flying a little. Slap power grows with the slap upgrade.
function Steal.slap(attacker)
	local attackerState = State.get(attacker)
	if not attackerState then
		return
	end
	local character = attacker.Character
	if not character then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local best = nil
	local bestDist = Config.SLAP_RANGE
	for player, state in pairs(State.all()) do
		if player ~= attacker and state.carrying then
			local other = player.Character
			if other then
				local otherRoot = other:FindFirstChild("HumanoidRootPart")
				if otherRoot then
					local dist = (otherRoot.Position - root.Position).Magnitude
					if dist <= bestDist then
						best = player
						bestDist = dist
					end
				end
			end
		end
	end
	if not best then
		ctx.economy.notify(attacker, "No thief in slap range!")
		return
	end
	local victimRoot = best.Character:FindFirstChild("HumanoidRootPart")
	if victimRoot then
		local away = (victimRoot.Position - root.Position).Unit
		local power = Config.SLAP_BASE_KNOCKBACK + attackerState.slapLevel * 8
		victimRoot.AssemblyLinearVelocity = away * power + Vector3.new(0, power * 0.6, 0)
	end
	Steal.dropCarried(best, "You got SLAPPED! Your brainrot dropped!")
	ctx.economy.notify(attacker, "SLAP! " .. best.DisplayName .. " dropped the brainrot!")
end

return Steal
