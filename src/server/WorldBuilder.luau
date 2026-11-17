-- WorldBuilder: builds the whole 3D world at runtime, from data, when the
-- server starts. The place file itself only holds the ground and the spawn
-- point; everything else -- the belt, the four bases, the trees, the shop
-- stall -- is built here so the world lives in authored code, not in a
-- Studio save.
--
-- Layout (studs, ground top at y = 0):
--   belt runs east along z = -70, from x = -80 to x = +80
--   bases sit south of the walkway at (+/-60, 0 / 55)
--   players spawn at (0, 1, 25), between the belt and the bases

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local WorldBuilder = {}

local function part(name, size, position, color, parent, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = position
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = true
	p.Parent = parent
	return p
end

local function buildBelt(world)
	local belt = Instance.new("Folder")
	belt.Name = "Belt"
	belt.Parent = world

	-- The walkway the brainrots parade along.
	part("BeltBase", Vector3.new(168, 1, 8), Vector3.new(0, Config.BELT_Y - 0.5, Config.BELT_Z), Color3.fromRGB(60, 60, 70), belt, Enum.Material.Metal)
	part("BeltRailNorth", Vector3.new(168, 1.5, 0.6), Vector3.new(0, Config.BELT_Y + 0.7, Config.BELT_Z - 4), Color3.fromRGB(255, 215, 0), belt, Enum.Material.Neon)
	part("BeltRailSouth", Vector3.new(168, 1.5, 0.6), Vector3.new(0, Config.BELT_Y + 0.7, Config.BELT_Z + 4), Color3.fromRGB(255, 215, 0), belt, Enum.Material.Neon)

	-- The gate a brainrot walks out of, and the gate it vanishes through.
	for _, x in ipairs({ Config.BELT_START_X - 4, Config.BELT_FINISH_X + 4 }) do
		local gate = part("Gate", Vector3.new(1, 8, 10), Vector3.new(x, Config.BELT_Y + 4, Config.BELT_Z), Color3.fromRGB(255, 90, 90), belt)
		gate.Transparency = 0.4
	end

	-- A sign over the middle of the belt so the parade reads at a glance.
	local sign = part("BeltSign", Vector3.new(30, 4, 0.6), Vector3.new(0, 12, Config.BELT_Z), Color3.fromRGB(30, 30, 40), belt)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.Parent = sign
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "BRAINROT PARADE - click one to buy it!"
	label.TextColor3 = Color3.fromRGB(255, 235, 0)
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.Parent = gui
end

local function buildBase(world, index, center, color)
	local base = Instance.new("Folder")
	base.Name = "Base" .. index
	base.Parent = world

	local half = Config.BASE_SIZE / 2
	part("Pad", Vector3.new(Config.BASE_SIZE, 1, Config.BASE_SIZE), center + Vector3.new(0, 0.5, 0), color, base, Enum.Material.Grass)
	-- Low walls on the north and west sides; the south side stays open.
	part("WallNorth", Vector3.new(Config.BASE_SIZE, 3, 1), center + Vector3.new(0, 1.5, -half), Color3.fromRGB(240, 240, 240), base)
	part("WallWest", Vector3.new(1, 3, Config.BASE_SIZE), center + Vector3.new(-half, 1.5, 0), Color3.fromRGB(240, 240, 240), base)

	-- The lock gate across the open side: green while anyone may walk in,
	-- red and solid while the base is locked.
	local gate = part("LockGate", Vector3.new(Config.BASE_SIZE, 3, 1), center + Vector3.new(0, 1.5, half), Color3.fromRGB(90, 220, 90), base, Enum.Material.Neon)
	gate.Transparency = 0.55
	gate.CanCollide = false
	gate.Name = "LockGate"

	-- Eight slot pads in two rows of four; a bought brainrot stands on one.
	local slots = {}
	for i = 1, 8 do
		local row = math.floor((i - 1) / 4)
		local col = (i - 1) % 4
		local pos = center + Vector3.new(-6 + col * Config.SLOT_SPACING_X, 1.2, -4 + row * Config.SLOT_SPACING_Z)
		local pad = part("Slot" .. i, Vector3.new(3, 0.4, 3), pos, Color3.fromRGB(255, 255, 255), base, Enum.Material.Neon)
		pad.Transparency = 0.5
		table.insert(slots, pos + Vector3.new(0, 0.2, 0))
	end

	-- A pole sign naming the base, so a thief knows whose home this is.
	local pole = part("SignPole", Vector3.new(0.6, 8, 0.6), center + Vector3.new(0, 4, -half - 1), Color3.fromRGB(120, 80, 40), base)
	local board = part("SignBoard", Vector3.new(10, 3, 0.6), center + Vector3.new(0, 8.5, -half - 1), Color3.fromRGB(30, 30, 40), base)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "BASE " .. index
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.Parent = gui
	pole.Name = "SignPole"

	return {
		index = index,
		center = center,
		color = color,
		folder = base,
		pad = base:FindFirstChild("Pad"),
		lockGate = gate,
		slots = slots,
		owner = nil, -- the Player who claimed this base, or nil
	}
end

local function buildDecor(world)
	local decor = Instance.new("Folder")
	decor.Name = "Decor"
	decor.Parent = world

	-- Trees around the edges: a trunk and a leafy ball.
	local treeSpots = {
		Vector3.new(-95, 0, -85), Vector3.new(95, 0, -85), Vector3.new(-95, 0, 85),
		Vector3.new(95, 0, 85), Vector3.new(-40, 0, 88), Vector3.new(40, 0, 88),
		Vector3.new(-95, 0, 10), Vector3.new(95, 0, 10),
	}
	for i, spot in ipairs(treeSpots) do
		part("TreeTrunk" .. i, Vector3.new(1.5, 6, 1.5), spot + Vector3.new(0, 3, 0), Color3.fromRGB(120, 80, 40), decor)
		local leaves = part("TreeTop" .. i, Vector3.new(6, 6, 6), spot + Vector3.new(0, 8, 0), Color3.fromRGB(60, 180, 80), decor)
		leaves.Shape = Enum.PartType.Ball
	end

	-- Rocks to trip over (gently: they are small).
	for i, spot in ipairs({ Vector3.new(-30, 0, -45), Vector3.new(30, 0, -45), Vector3.new(0, 0, 80), Vector3.new(-85, 0, 30) }) do
		local rock = part("Rock" .. i, Vector3.new(3, 2, 3), spot + Vector3.new(0, 1, 0), Color3.fromRGB(130, 130, 130), decor)
		rock.Shape = Enum.PartType.Ball
	end

	-- Lamps that light the walkway at dusk.
	for i, spot in ipairs({ Vector3.new(-20, 0, -55), Vector3.new(20, 0, -55), Vector3.new(-20, 0, 40), Vector3.new(20, 0, 40) }) do
		part("LampPost" .. i, Vector3.new(0.6, 7, 0.6), spot + Vector3.new(0, 3.5, 0), Color3.fromRGB(60, 60, 60), decor)
		local bulb = part("LampBulb" .. i, Vector3.new(1.6, 1.6, 1.6), spot + Vector3.new(0, 7.5, 0), Color3.fromRGB(255, 240, 170), decor, Enum.Material.Neon)
		bulb.Shape = Enum.PartType.Ball
		local light = Instance.new("PointLight")
		light.Range = 18
		light.Brightness = 1.5
		light.Parent = bulb
	end

	-- The shop stall: a striped awning near the spawn where upgrades live.
	local stall = Instance.new("Folder")
	stall.Name = "ShopStall"
	stall.Parent = decor
	part("StallBase", Vector3.new(10, 1, 8), Vector3.new(0, 0.5, -42), Color3.fromRGB(150, 110, 70), stall)
	part("StallAwning", Vector3.new(11, 0.6, 9), Vector3.new(0, 5, -42), Color3.fromRGB(255, 90, 90), stall)
	local sign = part("ShopSign", Vector3.new(9, 2.5, 0.6), Vector3.new(0, 6.5, -42), Color3.fromRGB(30, 30, 40), stall)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.Parent = sign
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "SHOP - press the Shop button!"
	label.TextColor3 = Color3.fromRGB(255, 235, 0)
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.Parent = gui
end

-- Builds the world and returns the handles the other modules play with.
function WorldBuilder.build()
	local world = Instance.new("Folder")
	world.Name = "MemeMeadows"
	world.Parent = game:GetService("Workspace")

	buildBelt(world)

	local bases = {}
	for i, center in ipairs(Config.BASE_CENTERS) do
		bases[i] = buildBase(world, i, center, Config.BASE_COLORS[i])
	end

	buildDecor(world)

	return {
		folder = world,
		bases = bases,
		spawn = Config.SPAWN_POINT,
	}
end

-- The axis-aligned rectangle of a base, used for "is this player home?"
function WorldBuilder.isInsideBase(base, position)
	local half = Config.BASE_SIZE / 2
	return math.abs(position.X - base.center.X) <= half
		and math.abs(position.Z - base.center.Z) <= half
end

-- Finds the base a player owns, or nil.
function WorldBuilder.baseOf(bases, player)
	for _, base in ipairs(bases) do
		if base.owner == player then
			return base
		end
	end
	return nil
end

-- Claims the first free base for a player who just joined.
function WorldBuilder.claimBase(bases, player)
	for _, base in ipairs(bases) do
		if base.owner == nil then
			base.owner = player
			return base
		end
	end
	return nil
end

return WorldBuilder
