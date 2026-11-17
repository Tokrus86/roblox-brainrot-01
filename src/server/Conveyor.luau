-- Conveyor: the brainrot parade. Brainrots are born at the west gate, walk
-- east along the belt, and vanish through the east gate if nobody buys them.
-- Clicking one buys it (see Economy.tryBuy). A Lucky Charm anywhere online
-- makes the parade roll rarer spawns.

local BrainrotData = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotData"))
local BrainrotFactory = require(script.Parent:WaitForChild("BrainrotFactory"))
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local State = require(script.Parent:WaitForChild("State"))

local Conveyor = {}

local ctx = nil
local active = {} -- [uid] = { entry, model, x }
local beltFolder = nil

function Conveyor.init(context, world)
	ctx = context
	beltFolder = Instance.new("Folder")
	beltFolder.Name = "BeltBrainrots"
	beltFolder.Parent = world.folder
end

function Conveyor.peek(uid)
	local item = active[uid]
	if item then
		return item.entry
	end
	return nil
end

-- Takes a brainrot off the belt (it was just bought) and hands its entry over.
function Conveyor.take(uid)
	local item = active[uid]
	if not item then
		return nil
	end
	active[uid] = nil
	if item.model then
		item.model:Destroy()
	end
	return item.entry
end

local function spawnOne()
	local count = 0
	for _ in pairs(active) do
		count += 1
	end
	if count >= Config.BELT_MAX_ACTIVE then
		return
	end
	-- If any player online runs a Lucky Charm, the whole parade gets luckier.
	local luck = 1
	for _, state in pairs(State.all()) do
		if State.hasLuck(state) then
			luck = Config.LUCK_MULT
			break
		end
	end
	local entry = BrainrotData.rollSpawn(luck)
	local model = BrainrotFactory.build(entry, Vector3.new(Config.BELT_START_X, Config.BELT_Y, Config.BELT_Z))
	model.Parent = beltFolder
	active[entry.uid] = { entry = entry, model = model, x = Config.BELT_START_X }

	local click = model.PrimaryPart:FindFirstChildOfClass("ClickDetector")
	if click then
		click.MouseClick:Connect(function(player)
			ctx.economy.tryBuy(player, entry.uid)
		end)
	end
end

function Conveyor.start()
	-- The parade never stops: a new brainrot every few seconds.
	task.spawn(function()
		while true do
			task.wait(Config.BELT_SPAWN_SECONDS)
			spawnOne()
		end
	end)

	-- The walk east, one Heartbeat at a time.
	game:GetService("RunService").Heartbeat:Connect(function(dt)
		for uid, item in pairs(active) do
			item.x += Config.BELT_SPEED * dt
			if item.x >= Config.BELT_FINISH_X then
				if item.model then
					item.model:Destroy()
				end
				active[uid] = nil
			else
				item.model:PivotTo(CFrame.new(item.x, Config.BELT_Y, Config.BELT_Z))
			end
		end
	end)
end

return Conveyor
