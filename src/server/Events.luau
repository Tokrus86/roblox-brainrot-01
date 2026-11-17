-- Events: the two things that break the routine and force a dash home.
-- A tsunami wave sweeps the map every two minutes: ten seconds of warning,
-- then a wall of water rolls from north to south, and anyone caught outside
-- their own base is swept back to spawn (and drops whatever they carry).
-- Golden Hour runs every five minutes: one minute of double income.

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local Net = require(script.Parent:WaitForChild("Net"))
local State = require(script.Parent:WaitForChild("State"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))

local Events = {}

local ctx = nil
local goldenHour = false

function Events.init(context)
	ctx = context
end

function Events.isGoldenHour()
	return goldenHour
end

local function sweepPlayer(player, state)
	-- Home is safe: only players outside their own base get swept.
	if state.base then
		local character = player.Character
		if character then
			local root = character:FindFirstChild("HumanoidRootPart")
			if root and WorldBuilder.isInsideBase(state.base, root.Position) then
				return
			end
		end
	end
	ctx.steal.dropCarried(player, nil)
	local character = player.Character
	if character then
		local root = character:FindFirstChild("HumanoidRootPart")
		if root then
			root.CFrame = CFrame.new(ctx.world.spawn + Vector3.new(0, 2, 0))
			root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		end
	end
	ctx.economy.notify(player, "The tsunami swept you back to spawn!")
end

local function runTsunami()
	local wave = Instance.new("Part")
	wave.Name = "TsunamiWave"
	wave.Size = Vector3.new(220, 30, 4)
	wave.Position = Vector3.new(0, 12, -110)
	wave.Color = Color3.fromRGB(60, 140, 255)
	wave.Material = Enum.Material.Neon
	wave.Transparency = 0.35
	wave.Anchored = true
	wave.CanCollide = false
	wave.Parent = game:GetService("Workspace")

	local tween = game:GetService("TweenService"):Create(
		wave,
		TweenInfo.new(Config.TSUNAMI_SWEEP_SECONDS, Enum.EasingStyle.Linear),
		{ Position = Vector3.new(0, 12, 110) }
	)
	tween:Play()

	-- While the wave rolls, anyone it touches outside their base gets swept.
	local start = os.clock()
	while os.clock() - start < Config.TSUNAMI_SWEEP_SECONDS + 0.5 do
		task.wait(0.2)
		local z = wave.Position.Z
		for player, state in pairs(State.all()) do
			local character = player.Character
			if character then
				local root = character:FindFirstChild("HumanoidRootPart")
				if root and math.abs(root.Position.Z - z) < 6 then
					sweepPlayer(player, state)
				end
			end
		end
	end
	wave:Destroy()
end

function Events.start()
	-- The tsunami: warn, wait, sweep, repeat.
	task.spawn(function()
		while true do
			task.wait(Config.TSUNAMI_EVERY_SECONDS)
			Net.get().EventAlert:FireAllClients({ type = "tsunami_warn", seconds = Config.TSUNAMI_WARN_SECONDS })
			task.wait(Config.TSUNAMI_WARN_SECONDS)
			Net.get().EventAlert:FireAllClients({ type = "tsunami_now" })
			runTsunami()
			Net.get().EventAlert:FireAllClients({ type = "tsunami_over" })
		end
	end)

	-- Golden Hour: a minute of double income, every five minutes.
	task.spawn(function()
		while true do
			task.wait(Config.GOLDEN_HOUR_EVERY_SECONDS)
			goldenHour = true
			Net.get().EventAlert:FireAllClients({ type = "golden_start", seconds = Config.GOLDEN_HOUR_SECONDS })
			task.wait(Config.GOLDEN_HOUR_SECONDS)
			goldenHour = false
			Net.get().EventAlert:FireAllClients({ type = "golden_end" })
		end
	end)
end

return Events
