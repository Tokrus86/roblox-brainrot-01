-- Effects: the feedback the player feels. A full-screen flash when the
-- tsunami hits or a rebirth lands, and a burst of confetti cubes when a
-- rebirth is celebrated. All cosmetic, all client-side, all cheap.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local eventAlert = remotes:WaitForChild("EventAlert")

local gui = Instance.new("ScreenGui")
gui.Name = "MemeMeadowsEffects"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100
gui.Parent = player:WaitForChild("PlayerGui")

local flash = Instance.new("Frame")
flash.Name = "Flash"
flash.Size = UDim2.fromScale(1, 1)
flash.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
flash.BackgroundTransparency = 1
flash.BorderSizePixel = 0
flash.Parent = gui

local function doFlash(color, peak)
	flash.BackgroundColor3 = color
	flash.BackgroundTransparency = 1 - peak
	local tween = TweenService:Create(flash, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 })
	tween:Play()
end

local function confetti()
	local character = player.Character
	if not character then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local colors = {
		Color3.fromRGB(255, 215, 0),
		Color3.fromRGB(255, 110, 220),
		Color3.fromRGB(120, 220, 255),
		Color3.fromRGB(140, 255, 140),
	}
	for _ = 1, 40 do
		local cube = Instance.new("Part")
		cube.Size = Vector3.new(0.5, 0.5, 0.5)
		cube.Color = colors[math.random(#colors)]
		cube.Material = Enum.Material.Neon
		cube.Anchored = false
		cube.CanCollide = false
		cube.CFrame = root.CFrame * CFrame.new(math.random(-6, 6), math.random(4, 10), math.random(-6, 6))
		cube.AssemblyLinearVelocity = Vector3.new(math.random(-8, 8), math.random(2, 12), math.random(-8, 8))
		cube.Parent = workspace
		Debris:AddItem(cube, 2.5)
	end
end

eventAlert.OnClientEvent:Connect(function(alert)
	if alert.type == "tsunami_now" then
		doFlash(Color3.fromRGB(60, 140, 255), 0.45)
	elseif alert.type == "rebirth" then
		doFlash(Color3.fromRGB(255, 215, 0), 0.55)
		confetti()
	end
end)
