-- State: the single source of truth for every player's game state.
-- Money, brainrots, rebirths, upgrades, locks and what a player is carrying
-- live here and nowhere else; the other server modules read and change it
-- through these functions, so the game can never disagree with itself.

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local State = {}

local players = {} -- [Player] = state table

function State.create(player)
	local state = {
		player = player,
		cash = Config.START_CASH,
		rebirths = 0,
		owned = {}, -- array of brainrot entries standing on the player's base
		slots = Config.BASE_SLOTS_START,
		lockUntil = 0, -- os.clock() time the base lock ends, 0 = not locked
		lockReadyAt = 0, -- os.clock() time the lock button is usable again
		slapLevel = 0,
		speedUntil = 0,
		luckUntil = 0,
		carrying = nil, -- { entry, fromPlayer, model, returnAt } or nil
		base = nil, -- the base plot this player owns, set by init
	}
	players[player] = state
	return state
end

function State.get(player)
	return players[player]
end

function State.remove(player)
	players[player] = nil
end

function State.all()
	return players
end

-- The permanent income multiplier from rebirths: x2 per rebirth.
function State.rebirthMult(state)
	return 2 ^ state.rebirths
end

function State.isLocked(state)
	return os.clock() < state.lockUntil
end

function State.lockSecondsLeft(state)
	return math.max(0, state.lockUntil - os.clock())
end

function State.hasLuck(state)
	return os.clock() < state.luckUntil
end

function State.luckMult(state)
	if State.hasLuck(state) then
		return Config.LUCK_MULT
	end
	return 1
end

function State.speedActive(state)
	return os.clock() < state.speedUntil
end

function State.incomePerSecond(state, goldenHourMult)
	local total = 0
	for _, entry in ipairs(state.owned) do
		total += entry.income
	end
	return total * State.rebirthMult(state) * goldenHourMult
end

function State.freeSlotIndex(state)
	for i = 1, state.slots do
		local taken = false
		for _, entry in ipairs(state.owned) do
			if entry.slot == i then
				taken = true
				break
			end
		end
		if not taken then
			return i
		end
	end
	return nil
end

function State.findOwned(state, uid)
	for i, entry in ipairs(state.owned) do
		if entry.uid == uid then
			return entry, i
		end
	end
	return nil, nil
end

function State.removeOwned(state, uid)
	local _, i = State.findOwned(state, uid)
	if i then
		table.remove(state.owned, i)
		return true
	end
	return false
end

return State
