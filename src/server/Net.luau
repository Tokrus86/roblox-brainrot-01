-- Net: the RemoteEvents the server and the client talk through.
-- Created once at startup, under ReplicatedStorage/Remotes.
--
--   StateUpdate (server -> client): the HUD numbers, every money tick.
--   Notify      (server -> client): one toast line ("Bought DJ Pickle!").
--   EventAlert  (server -> client): tsunami warnings, Golden Hour, rebirths.
--   PlayerAction (client -> server): "lock", "rebirth", "slap", "buyUpgrade".

local Net = {}

local remotes = nil

function Net.init()
	local storage = game:GetService("ReplicatedStorage")
	local folder = Instance.new("Folder")
	folder.Name = "Remotes"
	folder.Parent = storage

	remotes = {}
	for _, name in ipairs({ "StateUpdate", "Notify", "EventAlert", "PlayerAction" }) do
		local event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = folder
		remotes[name] = event
	end
	return remotes
end

function Net.get()
	return remotes
end

return Net
