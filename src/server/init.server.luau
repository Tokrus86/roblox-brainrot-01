-- init: wires "Steal a Brainrot: Meme Meadows" together when the server starts.
-- The world is built, the remotes are created, every player gets a base and
-- a state, and the parade, the money tick and the events start running.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BaseManager = require(script:WaitForChild("BaseManager"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Conveyor = require(script:WaitForChild("Conveyor"))
local Economy = require(script:WaitForChild("Economy"))
local Events = require(script:WaitForChild("Events"))
local Net = require(script:WaitForChild("Net"))
local State = require(script:WaitForChild("State"))
local Steal = require(script:WaitForChild("Steal"))
local WorldBuilder = require(script:WaitForChild("WorldBuilder"))

Net.init()
local world = WorldBuilder.build()
BaseManager.init(world)

local ctx = {
	world = world,
	net = Net.get(),
	economy = Economy,
	conveyor = Conveyor,
	steal = Steal,
	events = Events,
}
Economy.init(ctx)
Conveyor.init(ctx, world)
Steal.init(ctx)
Events.init(ctx)

-- The base pads are also how a thief brings a stolen brainrot home: step
-- on your own pad while carrying and it is set down on a free slot.
local lastPlaceAttempt = {}
for _, base in ipairs(world.bases) do
	base.pad.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player then
			return
		end
		local now = os.clock()
		if lastPlaceAttempt[player] and now - lastPlaceAttempt[player] < 1 then
			return
		end
		lastPlaceAttempt[player] = now
		local state = State.get(player)
		if state and state.base == base then
			Steal.placeCarried(player)
		end
	end)
end

local function onCharacterAdded(player, character)
	local humanoid = character:WaitForChild("Humanoid")
	local state = State.get(player)
	if state and State.speedActive(state) then
		humanoid.WalkSpeed = Config.SPEED_BOOST_SPEED
	else
		humanoid.WalkSpeed = Config.WALK_SPEED
	end
end

local function onPlayerAdded(player)
	local state = State.create(player)
	state.base = WorldBuilder.claimBase(world.bases, player)
	if state.base then
		Economy.notify(player, "Welcome to Meme Meadows! This is your base. Buy brainrots off the belt!")
	else
		Economy.notify(player, "Welcome to Meme Meadows! All bases are taken right now - you can still watch the parade.")
	end
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	Economy.pushUpdate(player)
end

local function onPlayerRemoving(player)
	local state = State.get(player)
	if state then
		-- Anything they were carrying drops where they stood.
		Steal.dropCarried(player, nil)
		BaseManager.clearAll(state)
		if state.base then
			state.base.owner = nil
			BaseManager.setLockVisual(state.base, false)
		end
	end
	State.remove(player)
	lastPlaceAttempt[player] = nil
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

-- The client only asks; the server decides. Every action is validated here.
Net.get().PlayerAction.OnServerEvent:Connect(function(player, action, arg)
	if action == "lock" then
		Economy.tryLock(player)
	elseif action == "rebirth" then
		Economy.tryRebirth(player)
	elseif action == "slap" then
		Steal.slap(player)
	elseif action == "buyUpgrade" then
		Economy.buyUpgrade(player, arg)
	end
end)

Conveyor.start()
Economy.startTickLoop()
Events.start()

print("Meme Meadows is open: the brainrot parade has begun.")
