-- Hud: the whole interface over the 3D world. Cash and income up top,
-- your base's brainrots down the side, and the buttons that run the game:
-- Lock, Slap, Rebirth and the Shop. The client only ever asks the server
-- to do things (PlayerAction); the server validates every one of them.
-- F slaps, L locks your base.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local stateUpdate = remotes:WaitForChild("StateUpdate")
local notifyEvent = remotes:WaitForChild("Notify")
local eventAlert = remotes:WaitForChild("EventAlert")
local playerAction = remotes:WaitForChild("PlayerAction")

local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))

local gui = Instance.new("ScreenGui")
gui.Name = "MemeMeadowsHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function makeLabel(name, parent, position, size, text, textSize, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = position
	label.Size = size
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextSize = textSize
	label.TextColor3 = color
	label.Font = Enum.Font.SourceSansBold
	label.TextStrokeTransparency = 0.3
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

local function makeButton(name, parent, position, size, text, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Position = position
	button.Size = size
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Text = text
	button.TextSize = 20
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.SourceSansBold
	button.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button
	return button
end

-- Top-left: the money.
local moneyFrame = Instance.new("Frame")
moneyFrame.Name = "Money"
moneyFrame.Position = UDim2.new(0, 16, 0, 16)
moneyFrame.Size = UDim2.new(0, 280, 0, 110)
moneyFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
moneyFrame.BackgroundTransparency = 0.25
moneyFrame.BorderSizePixel = 0
moneyFrame.Parent = gui

local cashLabel = makeLabel("Cash", moneyFrame, UDim2.new(0, 12, 0, 8), UDim2.new(1, -24, 0, 36), "$100", 32, Color3.fromRGB(255, 235, 0))
local incomeLabel = makeLabel("Income", moneyFrame, UDim2.new(0, 12, 0, 46), UDim2.new(1, -24, 0, 26), "$0/s", 22, Color3.fromRGB(140, 255, 140))
local rebirthLabel = makeLabel("Rebirths", moneyFrame, UDim2.new(0, 12, 0, 74), UDim2.new(1, -24, 0, 26), "Rebirths: 0 (income x1)", 20, Color3.fromRGB(200, 200, 255))

-- Top-centre: event banner, hidden unless something is happening.
local banner = makeLabel("Banner", gui, UDim2.new(0.5, -300, 0, 16), UDim2.new(0, 600, 0, 44), "", 26, Color3.fromRGB(255, 255, 255))
banner.TextXAlignment = Enum.TextXAlignment.Center
banner.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
banner.BackgroundTransparency = 0.25
banner.Visible = false

-- Centre toast for one-line news ("Bought DJ Pickle!").
local toast = makeLabel("Toast", gui, UDim2.new(0.5, -300, 0, 70), UDim2.new(0, 600, 0, 32), "", 22, Color3.fromRGB(255, 255, 255))
toast.TextXAlignment = Enum.TextXAlignment.Center
toast.Visible = false

-- Carrying: what you have over your head right now.
local carryingLabel = makeLabel("Carrying", gui, UDim2.new(0.5, -200, 1, -130), UDim2.new(0, 400, 0, 30), "", 22, Color3.fromRGB(255, 200, 90))
carryingLabel.TextXAlignment = Enum.TextXAlignment.Center
carryingLabel.Visible = false

-- Right side: the brainrots standing on your base.
local baseFrame = Instance.new("Frame")
baseFrame.Name = "MyBase"
baseFrame.Position = UDim2.new(1, -236, 0, 16)
baseFrame.Size = UDim2.new(0, 220, 0, 300)
baseFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
baseFrame.BackgroundTransparency = 0.25
baseFrame.BorderSizePixel = 0
baseFrame.Parent = gui
makeLabel("BaseTitle", baseFrame, UDim2.new(0, 12, 0, 8), UDim2.new(1, -24, 0, 28), "MY BASE", 24, Color3.fromRGB(255, 255, 255))
local baseList = Instance.new("Frame")
baseList.Name = "BaseList"
baseList.Position = UDim2.new(0, 12, 0, 42)
baseList.Size = UDim2.new(1, -24, 1, -54)
baseList.BackgroundTransparency = 1
baseList.Parent = baseFrame

-- Bottom-centre: the action buttons.
local buttons = Instance.new("Frame")
buttons.Name = "Buttons"
buttons.AnchorPoint = Vector2.new(0.5, 1)
buttons.Position = UDim2.new(0.5, 0, 1, -16)
buttons.Size = UDim2.new(0, 440, 0, 52)
buttons.BackgroundTransparency = 1
buttons.Parent = gui

local lockButton = makeButton("Lock", buttons, UDim2.new(0, 0, 0, 0), UDim2.new(0, 100, 1, 0), "LOCK (L)", Color3.fromRGB(60, 160, 80))
local slapButton = makeButton("Slap", buttons, UDim2.new(0, 110, 0, 0), UDim2.new(0, 100, 1, 0), "SLAP! (F)", Color3.fromRGB(220, 80, 80))
local rebirthButton = makeButton("Rebirth", buttons, UDim2.new(0, 220, 0, 0), UDim2.new(0, 100, 1, 0), "REBIRTH", Color3.fromRGB(150, 90, 220))
local shopButton = makeButton("Shop", buttons, UDim2.new(0, 330, 0, 0), UDim2.new(0, 100, 1, 0), "SHOP", Color3.fromRGB(230, 150, 40))

-- The shop panel, hidden until opened.
local shopFrame = Instance.new("Frame")
shopFrame.Name = "Shop"
shopFrame.AnchorPoint = Vector2.new(0.5, 1)
shopFrame.Position = UDim2.new(0.5, 0, 1, -80)
shopFrame.Size = UDim2.new(0, 460, 0, 200)
shopFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
shopFrame.BackgroundTransparency = 0.15
shopFrame.BorderSizePixel = 0
shopFrame.Visible = false
shopFrame.Parent = gui
makeLabel("ShopTitle", shopFrame, UDim2.new(0, 12, 0, 8), UDim2.new(1, -24, 0, 28), "SHOP - spend your cash", 24, Color3.fromRGB(255, 235, 0))
local shopClose = makeButton("Close", shopFrame, UDim2.new(1, -92, 0, 8), UDim2.new(0, 80, 0, 30), "CLOSE", Color3.fromRGB(120, 120, 120))

local shopButtons = {}
local shopDefs = {
	{ key = "slot", title = "Extra Base Slot" },
	{ key = "slap", title = "Slap Power +1" },
	{ key = "speed", title = "Speed Boost (60s)" },
	{ key = "luck", title = "Lucky Charm (2m)" },
}
for i, def in ipairs(shopDefs) do
	local button = makeButton("Shop_" .. def.key, shopFrame, UDim2.new(0, 12, 0, 44 + (i - 1) * 38), UDim2.new(1, -24, 0, 32), def.title, Color3.fromRGB(70, 90, 140))
	button.TextSize = 18
	button.TextXAlignment = Enum.TextXAlignment.Left
	shopButtons[def.key] = { button = button, title = def.title }
	button.MouseButton1Click:Connect(function()
		playerAction:FireServer("buyUpgrade", def.key)
	end)
end

lockButton.MouseButton1Click:Connect(function()
	playerAction:FireServer("lock")
end)
slapButton.MouseButton1Click:Connect(function()
	playerAction:FireServer("slap")
end)
rebirthButton.MouseButton1Click:Connect(function()
	playerAction:FireServer("rebirth")
end)
shopButton.MouseButton1Click:Connect(function()
	shopFrame.Visible = not shopFrame.Visible
end)
shopClose.MouseButton1Click:Connect(function()
	shopFrame.Visible = false
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.F then
		playerAction:FireServer("slap")
	elseif input.KeyCode == Enum.KeyCode.L then
		playerAction:FireServer("lock")
	end
end)

local function refreshShop(shop)
	if not shop then
		return
	end
	for key, info in pairs(shopButtons) do
		local cost = shop[key]
		if cost then
			info.button.Text = "  " .. info.title .. "  -  " .. BrainrotData.formatMoney(cost)
		end
	end
end

stateUpdate.OnClientEvent:Connect(function(snap)
	cashLabel.Text = BrainrotData.formatMoney(snap.cash)
	local incomeText = BrainrotData.formatMoney(snap.income) .. "/s"
	if snap.goldenHour then
		incomeText ..= "  (GOLDEN HOUR x2!)"
	end
	incomeLabel.Text = incomeText
	rebirthLabel.Text = "Rebirths: " .. snap.rebirths .. " (income x" .. (2 ^ snap.rebirths) .. ")"

	if snap.lockLeft > 0 then
		lockButton.Text = "LOCKED " .. snap.lockLeft .. "s"
	elseif snap.lockReadyIn > 0 then
		lockButton.Text = "LOCK (" .. snap.lockReadyIn .. "s)"
	else
		lockButton.Text = "LOCK (L)"
	end

	if snap.carrying then
		carryingLabel.Text = "Carrying: " .. snap.carrying .. " - get it home to your base!"
		carryingLabel.Visible = true
	else
		carryingLabel.Visible = false
	end

	-- Rebuild the base list.
	for _, child in ipairs(baseList:GetChildren()) do
		child:Destroy()
	end
	for i, owned in ipairs(snap.owned) do
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0, 24)
		label.Position = UDim2.new(0, 0, 0, (i - 1) * 26)
		label.BackgroundTransparency = 1
		label.Text = owned.name .. "  " .. BrainrotData.formatMoney(owned.income) .. "/s"
		local rarityInfo = BrainrotData.RARITIES[owned.rarity]
		label.TextColor3 = rarityInfo and rarityInfo.color or Color3.fromRGB(255, 255, 255)
		label.TextSize = 18
		label.Font = Enum.Font.SourceSansBold
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = baseList
	end
	if #snap.owned == 0 then
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0, 48)
		label.BackgroundTransparency = 1
		label.Text = "Empty! Click a brainrot\non the belt to buy it."
		label.TextColor3 = Color3.fromRGB(200, 200, 200)
		label.TextSize = 18
		label.Font = Enum.Font.SourceSans
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = baseList
	end

	refreshShop(snap.shop)
end)

local toastTween = nil
notifyEvent.OnClientEvent:Connect(function(text)
	toast.Text = text
	toast.Visible = true
	toast.TextTransparency = 0
	if toastTween then
		toastTween:Cancel()
	end
	task.delay(2.5, function()
		toastTween = TweenService:Create(toast, TweenInfo.new(0.6), { TextTransparency = 1 })
		toastTween:Play()
		toastTween.Completed:Wait()
		toast.Visible = false
	end)
end)

eventAlert.OnClientEvent:Connect(function(alert)
	if alert.type == "tsunami_warn" then
		banner.Text = "TSUNAMI IN " .. alert.seconds .. "s! GET TO YOUR BASE!"
		banner.TextColor3 = Color3.fromRGB(120, 200, 255)
		banner.Visible = true
	elseif alert.type == "tsunami_now" then
		banner.Text = "TSUNAMI! STAY IN YOUR BASE!"
		banner.TextColor3 = Color3.fromRGB(120, 200, 255)
		banner.Visible = true
	elseif alert.type == "tsunami_over" then
		banner.Visible = false
	elseif alert.type == "golden_start" then
		banner.Text = "GOLDEN HOUR! Double income for " .. alert.seconds .. "s!"
		banner.TextColor3 = Color3.fromRGB(255, 215, 0)
		banner.Visible = true
		task.delay(alert.seconds, function()
			if banner.Text:find("GOLDEN HOUR") then
				banner.Visible = false
			end
		end)
	elseif alert.type == "golden_end" then
		banner.Visible = false
	end
end)
