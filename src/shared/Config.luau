-- Config: every tuning number for "Steal a Brainrot: Meme Meadows" in one place.
-- Nothing gameplay-critical is hard-coded in the game modules; they read it here.

local Config = {}

-- Economy
Config.TICK_SECONDS = 1 -- money ticks once a second
Config.START_CASH = 100
Config.BASE_SLOTS_START = 8
Config.MAX_SLOTS = 12
Config.REBIRTH_BASE_COST = 25000 -- rebirth n costs base * n
Config.REBIRTH_REFUND = 0.25 -- selling your brainrots back on rebirth refunds 25% of their cost

-- Conveyor belt (the brainrot parade along the north edge of the map)
Config.BELT_SPAWN_SECONDS = 6
Config.BELT_MAX_ACTIVE = 12
Config.BELT_SPEED = 6 -- studs per second
Config.BELT_Y = 3
Config.BELT_START_X = -80
Config.BELT_FINISH_X = 80
Config.BELT_Z = -70

-- Bases (four plots; the first four players claim one each)
Config.BASE_CENTERS = {
	Vector3.new(-60, 0, 55),
	Vector3.new(60, 0, 55),
	Vector3.new(-60, 0, 0),
	Vector3.new(60, 0, 0),
}
Config.BASE_SIZE = 18
Config.BASE_COLORS = {
	Color3.fromRGB(90, 170, 255),
	Color3.fromRGB(255, 120, 120),
	Color3.fromRGB(120, 220, 120),
	Color3.fromRGB(255, 200, 90),
}
Config.SLOT_SPACING_X = 4
Config.SLOT_SPACING_Z = 6

-- Stealing, slapping and locks
Config.SLAP_RANGE = 12 -- studs; a slap lands on a carrier this close
Config.SLAP_BASE_KNOCKBACK = 18
Config.CARRY_RETURN_SECONDS = 20 -- a dropped brainrot walks home after this long
Config.LOCK_SECONDS = 30
Config.LOCK_COOLDOWN_SECONDS = 90

-- Events
Config.TSUNAMI_EVERY_SECONDS = 120
Config.TSUNAMI_WARN_SECONDS = 10
Config.TSUNAMI_SWEEP_SECONDS = 8
Config.GOLDEN_HOUR_EVERY_SECONDS = 300
Config.GOLDEN_HOUR_SECONDS = 60
Config.GOLDEN_HOUR_MULT = 2

-- Shop (prices are cash; slot and slap prices scale with what you own)
Config.UPGRADE_SLOT_BASE = 500
Config.UPGRADE_SLAP_BASE = 300
Config.UPGRADE_SPEED_COST = 800
Config.UPGRADE_SPEED_SECONDS = 60
Config.UPGRADE_LUCK_COST = 1000
Config.UPGRADE_LUCK_SECONDS = 120
Config.LUCK_MULT = 2

-- Player
Config.SPAWN_POINT = Vector3.new(0, 1, 25)
Config.WALK_SPEED = 16
Config.SPEED_BOOST_SPEED = 24

return Config
