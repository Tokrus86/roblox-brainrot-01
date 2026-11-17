-- BaseManager: puts brainrot models on base slots and takes them off again.
-- A base has eight slot pads; a bought brainrot stands on the first free one.
-- The lock gate over the entrance turns red while the base is locked.

local BrainrotFactory = require(script.Parent:WaitForChild("BrainrotFactory"))
local State = require(script.Parent:WaitForChild("State"))

local BaseManager = {}

local ownedFolder = nil

function BaseManager.init(world)
	ownedFolder = Instance.new("Folder")
	ownedFolder.Name = "OwnedBrainrots"
	ownedFolder.Parent = world.folder
end

-- Places a brainrot on the first free slot of the owner's base.
-- onClick, when given, is called as onClick(player, entry) when anyone
-- clicks the model (buying uses the belt's own wiring; this is stealing).
-- Returns true when the brainrot was placed.
function BaseManager.placeOnSlot(state, entry, onClick)
	local base = state.base
	if not base then
		return false
	end
	local slot = State.freeSlotIndex(state)
	if not slot then
		return false
	end
	local pos = base.slots[slot]
	local model = BrainrotFactory.build(entry, pos)
	model.Parent = ownedFolder
	entry.slot = slot
	entry.model = model
	table.insert(state.owned, entry)

	if onClick then
		local click = model.PrimaryPart:FindFirstChildOfClass("ClickDetector")
		if click then
			click.MouseClick:Connect(function(player)
				onClick(player, entry)
			end)
		end
	end
	return true
end

-- Takes a brainrot off its slot and destroys its model.
function BaseManager.removeModel(state, uid)
	local entry = State.findOwned(state, uid)
	if not entry then
		return nil
	end
	if entry.model then
		entry.model:Destroy()
	end
	State.removeOwned(state, uid)
	return entry
end

-- Clears every brainrot a player owns (rebirth sells them all).
function BaseManager.clearAll(state)
	for _, entry in ipairs(state.owned) do
		if entry.model then
			entry.model:Destroy()
		end
	end
	table.clear(state.owned)
end

function BaseManager.setLockVisual(base, locked)
	local gate = base.lockGate
	if locked then
		gate.Color = Color3.fromRGB(255, 60, 60)
		gate.Transparency = 0.15
		gate.CanCollide = true
	else
		gate.Color = Color3.fromRGB(90, 220, 90)
		gate.Transparency = 0.55
		gate.CanCollide = false
	end
end

return BaseManager
