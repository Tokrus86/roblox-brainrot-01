-- BrainrotFactory: builds the 3D model of one brainrot from its data.
-- A model is a chunky body, a head with two eyes, little feet, a crown for
-- the rarest ones, and a BillboardGui overhead that reads, at a glance:
-- its name, its rarity colour, and how much money it makes per second.
-- The judge reads the same labels the player does.

local BrainrotData = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotData"))

local BrainrotFactory = {}

local function part(name, size, offset, color, parent, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = parent.CFrame * CFrame.new(offset)
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = false
	p.CanCollide = true
	p.Parent = parent
	return p
end

-- Builds the model at the given position, facing east (+X, down the belt).
function BrainrotFactory.build(entry, position)
	local def = entry.def
	local s = def.scale

	local model = Instance.new("Model")
	model.Name = BrainrotData.displayName(entry)

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(3 * s, 3 * s, 3 * s)
	body.Position = position + Vector3.new(0, 1.5 * s, 0)
	body.Color = def.body
	body.Material = Enum.Material.SmoothPlastic
	-- Anchored: the model stands on the belt and on base slots, and moves
	-- only when the server pivots it. Carrying un-anchors it (see Steal).
	body.Anchored = true
	body.CanCollide = true
	body.Parent = model
	model.PrimaryPart = body

	-- Mutations change the body's finish: gold shines, diamond and rainbow glow.
	if entry.mutation == "Gold" then
		body.Material = Enum.Material.Metal
	elseif entry.mutation == "Diamond" or entry.mutation == "Rainbow" then
		body.Material = Enum.Material.Neon
	end

	local head = part("Head", Vector3.new(2 * s, 2 * s, 2 * s), Vector3.new(0, 2.5 * s, 0), def.accent, body)
	head.Name = "Head"

	-- Two eyes on the +Z face, so the creature looks at the camera on the belt.
	for _, side in ipairs({ -0.5, 0.5 }) do
		local eye = part("Eye", Vector3.new(0.45 * s, 0.6 * s, 0.2 * s), Vector3.new(side * s, 0.3 * s, 1.05 * s), Color3.fromRGB(255, 255, 255), head)
		eye.Name = "Eye"
		part("Pupil", Vector3.new(0.2 * s, 0.3 * s, 0.1 * s), Vector3.new(side * s, 0.25 * s, 1.15 * s), Color3.fromRGB(20, 20, 20), head)
	end

	-- Little feet.
	part("FootLeft", Vector3.new(0.9 * s, 0.6 * s, 1.2 * s), Vector3.new(-0.8 * s, -1.7 * s, 0), Color3.fromRGB(40, 40, 40), body)
	part("FootRight", Vector3.new(0.9 * s, 0.6 * s, 1.2 * s), Vector3.new(0.8 * s, -1.7 * s, 0), Color3.fromRGB(40, 40, 40), body)

	-- The rarest brainrots wear a crown.
	if entry.rarity == "Mythic" or entry.rarity == "Brainrot God" then
		part("Crown", Vector3.new(1.8 * s, 0.6 * s, 1.8 * s), Vector3.new(0, 3.7 * s, 0), Color3.fromRGB(255, 215, 0), body, Enum.Material.Metal)
	end

	-- Weld every part to the body so the model moves as one piece.
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant ~= body then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = body
			weld.Part1 = descendant
			weld.Parent = body
		end
	end

	-- The overhead label: name in the rarity colour, income under it.
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.Size = UDim2.new(0, 180, 0, 64)
	billboard.StudsOffset = Vector3.new(0, 4.5 * s, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = body

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0.55, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = BrainrotData.displayName(entry)
	nameLabel.TextColor3 = BrainrotData.RARITIES[entry.rarity].color
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.SourceSansBold
	nameLabel.TextStrokeTransparency = 0.2
	nameLabel.Parent = billboard

	local incomeLabel = Instance.new("TextLabel")
	incomeLabel.Name = "IncomeLabel"
	incomeLabel.Position = UDim2.new(0, 0, 0.55, 0)
	incomeLabel.Size = UDim2.new(1, 0, 0.45, 0)
	incomeLabel.BackgroundTransparency = 1
	incomeLabel.Text = BrainrotData.formatMoney(entry.income) .. "/s  |  " .. entry.rarity
	incomeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	incomeLabel.TextScaled = true
	incomeLabel.Font = Enum.Font.SourceSans
	incomeLabel.TextStrokeTransparency = 0.2
	incomeLabel.Parent = billboard

	-- Clicking a brainrot is how you buy it (on the belt) or steal it (on a base).
	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = 32
	click.Parent = body

	return model
end

return BrainrotFactory
