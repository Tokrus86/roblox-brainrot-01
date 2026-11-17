-- BrainrotData: the cast of "Steal a Brainrot: Meme Meadows".
-- Every brainrot here is an original character of this game: its own name,
-- rarity, money-per-second rate, buy price and the colours its model is
-- built from. Nothing here is copied from any other brainrot game.

local BrainrotData = {}

export type RarityName = "Common" | "Rare" | "Epic" | "Legendary" | "Mythic" | "Brainrot God"

BrainrotData.RARITIES = {
	Common = { order = 1, color = Color3.fromRGB(200, 200, 200), weight = 40 },
	Rare = { order = 2, color = Color3.fromRGB(90, 170, 255), weight = 25 },
	Epic = { order = 3, color = Color3.fromRGB(180, 90, 255), weight = 16 },
	Legendary = { order = 4, color = Color3.fromRGB(255, 175, 0), weight = 10 },
	Mythic = { order = 5, color = Color3.fromRGB(255, 70, 130), weight = 6 },
	["Brainrot God"] = { order = 6, color = Color3.fromRGB(255, 225, 0), weight = 3 },
}

-- A brainrot can be born mutated. The mutation multiplies its income.
-- Chances are rolled per spawn; the Lucky Charm upgrade doubles the
-- non-Normal chances.
BrainrotData.MUTATIONS = {
	{ name = "Normal", mult = 1, chance = 0.80, color = Color3.fromRGB(255, 255, 255) },
	{ name = "Gold", mult = 2, chance = 0.14, color = Color3.fromRGB(255, 215, 0) },
	{ name = "Diamond", mult = 5, chance = 0.05, color = Color3.fromRGB(120, 220, 255) },
	{ name = "Rainbow", mult = 10, chance = 0.01, color = Color3.fromRGB(255, 110, 220) },
}

-- The cast. income is money per second, cost is the buy price on the belt.
BrainrotData.CAST = {
	{ name = "Noodle Cat", rarity = "Common", income = 1, cost = 25, body = Color3.fromRGB(255, 220, 130), accent = Color3.fromRGB(255, 120, 90), scale = 1.0, quirk = "Meows in spaghetti." },
	{ name = "Sir Bananasworth", rarity = "Common", income = 3, cost = 75, body = Color3.fromRGB(255, 235, 90), accent = Color3.fromRGB(120, 70, 20), scale = 1.0, quirk = "Knighted by a fruit bowl." },
	{ name = "DJ Pickle", rarity = "Rare", income = 8, cost = 200, body = Color3.fromRGB(90, 200, 90), accent = Color3.fromRGB(240, 240, 240), scale = 1.05, quirk = "Drops beats, never the jar." },
	{ name = "Captain Toaster", rarity = "Rare", income = 14, cost = 350, body = Color3.fromRGB(200, 200, 205), accent = Color3.fromRGB(255, 90, 60), scale = 1.05, quirk = "Sails the kitchen seas." },
	{ name = "Granny Rocket", rarity = "Epic", income = 25, cost = 750, body = Color3.fromRGB(180, 130, 255), accent = Color3.fromRGB(255, 255, 255), scale = 1.1, quirk = "Knits at Mach 3." },
	{ name = "Professor Wobble", rarity = "Epic", income = 40, cost = 1200, body = Color3.fromRGB(120, 200, 255), accent = Color3.fromRGB(255, 220, 130), scale = 1.1, quirk = "Discovered gravity, then fell over." },
	{ name = "Turbo Hamster", rarity = "Legendary", income = 75, cost = 2500, body = Color3.fromRGB(255, 170, 80), accent = Color3.fromRGB(255, 255, 255), scale = 1.15, quirk = "Runs on pure panic." },
	{ name = "Queen Bubblegum", rarity = "Legendary", income = 120, cost = 4500, body = Color3.fromRGB(255, 130, 200), accent = Color3.fromRGB(255, 235, 0), scale = 1.15, quirk = "Rules the candy aisle." },
	{ name = "Lord Spaghetti", rarity = "Mythic", income = 250, cost = 10000, body = Color3.fromRGB(255, 240, 180), accent = Color3.fromRGB(200, 40, 40), scale = 1.25, quirk = "A duke of durum wheat." },
	{ name = "Mister Moonboots", rarity = "Mythic", income = 400, cost = 18000, body = Color3.fromRGB(150, 160, 200), accent = Color3.fromRGB(90, 220, 255), scale = 1.25, quirk = "Walks on the moon. Slowly." },
	{ name = "The Almighty Dumpling", rarity = "Brainrot God", income = 1000, cost = 50000, body = Color3.fromRGB(255, 250, 230), accent = Color3.fromRGB(255, 180, 0), scale = 1.4, quirk = "Folded by fate itself." },
	{ name = "Emperor Couch Potato", rarity = "Brainrot God", income = 2000, cost = 120000, body = Color3.fromRGB(150, 110, 70), accent = Color3.fromRGB(255, 215, 0), scale = 1.45, quirk = "Has not stood up since 1997." },
}

local nextUid = 0

local function rollRarity()
	local total = 0
	for _, info in pairs(BrainrotData.RARITIES) do
		total += info.weight
	end
	local roll = math.random() * total
	for name, info in pairs(BrainrotData.RARITIES) do
		roll -= info.weight
		if roll <= 0 then
			return name
		end
	end
	return "Common"
end

local function rollMutation(luckMult)
	luckMult = luckMult or 1
	local roll = math.random()
	local acc = 0
	-- Normal shrinks as luck grows; the rest scale up.
	local normalChance = math.max(0.2, BrainrotData.MUTATIONS[1].chance / luckMult)
	acc += normalChance
	if roll <= acc then
		return BrainrotData.MUTATIONS[1]
	end
	for i = 2, #BrainrotData.MUTATIONS do
		local m = BrainrotData.MUTATIONS[i]
		acc += m.chance * luckMult
		if roll <= acc then
			return m
		end
	end
	return BrainrotData.MUTATIONS[1]
end

-- Rolls one brainrot for the conveyor belt. luckMult > 1 comes from the
-- Lucky Charm upgrade and makes rare spawns and mutations more likely.
function BrainrotData.rollSpawn(luckMult)
	local rarity = rollRarity()
	local pool = {}
	for _, def in ipairs(BrainrotData.CAST) do
		if def.rarity == rarity then
			table.insert(pool, def)
		end
	end
	if #pool == 0 then
		pool = BrainrotData.CAST
	end
	local def = pool[math.random(#pool)]
	local mutation = rollMutation(luckMult)
	nextUid += 1
	return {
		uid = nextUid,
		def = def,
		rarity = rarity,
		mutation = mutation.name,
		mutationMult = mutation.mult,
		mutationColor = mutation.color,
		income = def.income * mutation.mult,
		cost = def.cost,
	}
end

function BrainrotData.incomeOf(entry)
	return entry.def.income * entry.mutationMult
end

function BrainrotData.displayName(entry)
	if entry.mutation == "Normal" then
		return entry.def.name
	end
	return entry.mutation .. " " .. entry.def.name
end

function BrainrotData.formatMoney(n)
	if n >= 1000000 then
		return string.format("$%.2fM", n / 1000000)
	elseif n >= 1000 then
		return string.format("$%.1fK", n / 1000)
	else
		return "$" .. tostring(math.floor(n + 0.5))
	end
end

return BrainrotData
