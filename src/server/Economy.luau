-- Economy: money, buying, rebirths and the shop.
-- Every money change is validated here on the server; the client only asks,
-- it never decides. A purchase that fails tells the player why.

local BrainrotData = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotData"))
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local BaseManager = require(script.Parent:WaitForChild("BaseManager"))
local Net = require(script.Parent:WaitForChild("Net"))
local State = require(script.Parent:WaitForChild("State"))

local Economy = {}

local ctx = nil

function Economy.init(context)
	ctx = context
end

-- The HUD snapshot the client renders, sent once a second and after every
-- action that changes money.
function Economy.snapshot(state)
	local owned = {}
	for _, entry in ipairs(state.owned) do
		table.insert(owned, {
			name = BrainrotData.displayName(entry),
			rarity = entry.rarity,
			income = entry.income,
		})
	end
	return {
		cash = math.floor(state.cash),
		income = State.incomePerSecond(state, ctx.events.isGoldenHour() and Config.GOLDEN_HOUR_MULT or 1),
		rebirths = state.rebirths,
		slots = state.slots,
		owned = owned,
		lockLeft = math.ceil(State.lockSecondsLeft(state)),
		lockReadyIn = math.max(0, math.ceil(state.lockReadyAt - os.clock())),
		slapLevel = state.slapLevel,
		speedLeft = math.max(0, math.ceil(state.speedUntil - os.clock())),
		luckLeft = math.max(0, math.ceil(state.luckUntil - os.clock())),
		goldenHour = ctx.events.isGoldenHour(),
		carrying = state.carrying and BrainrotData.displayName(state.carrying.entry) or nil,
		shop = {
			slot = Economy.upgradeCost(state, "slot"),
			slap = Economy.upgradeCost(state, "slap"),
			speed = Economy.upgradeCost(state, "speed"),
			luck = Economy.upgradeCost(state, "luck"),
		},
	}
end

function Economy.pushUpdate(player)
	local state = State.get(player)
	if not state then
		return
	end
	Net.get().StateUpdate:FireClient(player, Economy.snapshot(state))
end

function Economy.notify(player, text)
	Net.get().Notify:FireClient(player, text)
end

-- The money tick: every owned brainrot pays its rate, times the rebirth
-- multiplier, times the Golden Hour multiplier while one runs.
function Economy.startTickLoop()
	task.spawn(function()
		while true do
			task.wait(Config.TICK_SECONDS)
			local golden = ctx.events.isGoldenHour() and Config.GOLDEN_HOUR_MULT or 1
			for player, state in pairs(State.all()) do
				state.cash += State.incomePerSecond(state, golden)
				-- Speed boosts wear off; put the player back to normal speed.
				local character = player.Character
				if character then
					local humanoid = character:FindFirstChildOfClass("Humanoid")
					if humanoid then
						local want = State.speedActive(state) and Config.SPEED_BOOST_SPEED or Config.WALK_SPEED
						if humanoid.WalkSpeed ~= want then
							humanoid.WalkSpeed = want
						end
					end
				end
				Economy.pushUpdate(player)
			end
		end
	end)
end

-- Buys a brainrot off the belt. The belt hands the entry over; if any check
-- fails the brainrot stays on the belt and the player is told why.
function Economy.tryBuy(player, beltUid)
	local state = State.get(player)
	if not state then
		return
	end
	local entry = ctx.conveyor.peek(beltUid)
	if not entry then
		Economy.notify(player, "That brainrot already walked away!")
		return
	end
	if not state.base then
		Economy.notify(player, "All bases are taken! Wait for a free base.")
		return
	end
	if state.cash < entry.cost then
		Economy.notify(player, "Not enough cash! Need " .. BrainrotData.formatMoney(entry.cost) .. ".")
		return
	end
	if not State.freeSlotIndex(state) then
		Economy.notify(player, "Your base is full! Buy more slots in the Shop.")
		return
	end
	-- All checks passed: take it off the belt, take the cash, put it on a slot.
	ctx.conveyor.take(beltUid)
	state.cash -= entry.cost
	local placed = BaseManager.placeOnSlot(state, entry, ctx.steal.onBaseBrainrotClicked)
	if not placed then
		-- Should not happen (the slot check passed), but never eat the cash.
		state.cash += entry.cost
		Economy.notify(player, "Something went wrong placing it. Cash refunded!")
		return
	end
	Economy.notify(player, "Bought " .. BrainrotData.displayName(entry) .. " for " .. BrainrotData.formatMoney(entry.cost) .. "!")
	Economy.pushUpdate(player)
end

function Economy.rebirthCost(state)
	return Config.REBIRTH_BASE_COST * (state.rebirths + 1)
end

-- Rebirth: sell every brainrot (25% refund), reset cash, keep a permanent
-- x2 income multiplier per rebirth.
function Economy.tryRebirth(player)
	local state = State.get(player)
	if not state then
		return
	end
	local cost = Economy.rebirthCost(state)
	if state.cash < cost then
		Economy.notify(player, "Rebirth needs " .. BrainrotData.formatMoney(cost) .. " cash.")
		return
	end
	if state.carrying then
		Economy.notify(player, "Put down what you are carrying first!")
		return
	end
	local refund = 0
	for _, entry in ipairs(state.owned) do
		refund += entry.cost * Config.REBIRTH_REFUND
	end
	BaseManager.clearAll(state)
	state.cash = Config.START_CASH + refund
	state.rebirths += 1
	Net.get().EventAlert:FireClient(player, { type = "rebirth", rebirths = state.rebirths })
	Economy.notify(player, "REBIRTH #" .. state.rebirths .. "! Income is now x" .. State.rebirthMult(state) .. " forever.")
	Economy.pushUpdate(player)
end

function Economy.upgradeCost(state, kind)
	if kind == "slot" then
		return Config.UPGRADE_SLOT_BASE * state.slots
	elseif kind == "slap" then
		return Config.UPGRADE_SLAP_BASE * (state.slapLevel + 1)
	elseif kind == "speed" then
		return Config.UPGRADE_SPEED_COST
	elseif kind == "luck" then
		return Config.UPGRADE_LUCK_COST
	end
	return nil
end

function Economy.buyUpgrade(player, kind)
	local state = State.get(player)
	if not state then
		return
	end
	local cost = Economy.upgradeCost(state, kind)
	if not cost then
		return
	end
	if state.cash < cost then
		Economy.notify(player, "Not enough cash for that upgrade!")
		return
	end
	if kind == "slot" then
		if state.slots >= Config.MAX_SLOTS then
			Economy.notify(player, "Your base already has the maximum slots!")
			return
		end
		state.cash -= cost
		state.slots += 1
		Economy.notify(player, "Bought an extra base slot! (" .. state.slots .. "/" .. Config.MAX_SLOTS .. ")")
	elseif kind == "slap" then
		state.cash -= cost
		state.slapLevel += 1
		Economy.notify(player, "Slap power up! Level " .. state.slapLevel .. ".")
	elseif kind == "speed" then
		state.cash -= cost
		state.speedUntil = os.clock() + Config.UPGRADE_SPEED_SECONDS
		Economy.notify(player, "Speed boost! 60 seconds of fast feet.")
	elseif kind == "luck" then
		state.cash -= cost
		state.luckUntil = os.clock() + Config.UPGRADE_LUCK_SECONDS
		Economy.notify(player, "Lucky Charm! Better spawns for 2 minutes.")
	end
	Economy.pushUpdate(player)
end

-- Locks the player's own base for 30 seconds; nobody can steal from it
-- while the gate is red. 90 seconds of cooldown after it ends.
function Economy.tryLock(player)
	local state = State.get(player)
	if not state or not state.base then
		return
	end
	local now = os.clock()
	if State.isLocked(state) then
		Economy.notify(player, "Your base is already locked!")
		return
	end
	if now < state.lockReadyAt then
		Economy.notify(player, "Lock is recharging: " .. math.ceil(state.lockReadyAt - now) .. "s left.")
		return
	end
	state.lockUntil = now + Config.LOCK_SECONDS
	state.lockReadyAt = state.lockUntil + Config.LOCK_COOLDOWN_SECONDS
	BaseManager.setLockVisual(state.base, true)
	Economy.notify(player, "Base locked for " .. Config.LOCK_SECONDS .. "s! Nobody can steal from you.")
	task.delay(Config.LOCK_SECONDS, function()
		if state.base then
			BaseManager.setLockVisual(state.base, false)
		end
		Economy.pushUpdate(player)
	end)
	Economy.pushUpdate(player)
end

return Economy
