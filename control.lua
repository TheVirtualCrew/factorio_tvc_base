-- [[
-- Api base mod
-- ]]

require "util"

Event = require('__stdlib__/stdlib/event/event')
api = require "script.api"
require "script.crowdcontrol"
local output_file = 'tvc_api.json'

local function init_globals()
	global.events = global.events or {}
	global.config = global.config or {
		export_statistics = false,
		store_requests = {
			donation = true,
			member = true,
			follow = false,
			raid = false,
			host = false
		}
	}

	global.data = global.data or {
		deathcount = {},
		requests = {
			donation = {},
			member = {},
			follow = {},
			raid = {},
			host = {},
		}
	}

	api.setup_events()
end

local function write_external(command, msg, out_file)
	local output = { command = command, msg = msg }
	if rcon and out_file == nil then
		rcon.print(game.table_to_json(output))
	else
		out_file = out_file or output_file
		game.write_file(out_file, game.table_to_json(output), false, 0)
	end
end

local publish = function(output)
	if rcon then
		local type_out = type(output)
		if type_out == 'table' then
			rcon.print(game.table_to_json(output))
		elseif type_out == 'boolean' or type_out == 'number' or type_out == 'string' or type_out == 'nil' then
			rcon.print(output)
		end
	end

	return output
end

init_globals()

Event.on_init(function()
	init_globals()
end)

Event.on_event(defines.events.on_tick, function(event)
	if global.config.export_statistics == 1 and event.tick ~= 0 and event.tick % 60 == 0 then
		write_external('statistics', statistics:store_results(event.tick), "tvc_statistics.txt")
	end
end)

Event.on_event(defines.events.on_player_died, function(event)
	local cause = 'other'
	local player_name = game.players[event.player_index].name
	local train_types = { locomotive = 1, ["cargo-wagon"] = 1, ["artillery-wagon"] = 1, ["fluid-wagon"] = 1 }

	if event.cause then
		local v = event.cause
		if train_types[v.type] then
			cause = 'train'
		elseif v.type == 'player' and v.player ~= nil and v.player.name == player_name then
			cause = "suicide"
		elseif v.force and v.force.name == 'enemy' then
			cause = 'biter'
		end
	end

	if not global.data.deathcount[player_name] or type(global.data.deathcount[player_name]) ~= 'table' then
		global.data.deathcount[player_name] = {
			suicide = 0,
			train = 0,
			biter = 0,
			other = 0,
		}
	end

	global.data.deathcount[player_name][cause] = global.data.deathcount[player_name][cause] + 1
end)

remote.add_interface("tvc_api", {
	get_events = function()
		return global.events
	end,
	donation = function(message)
		api.on_donation(message)
	end,
	member = function(message)
		api.on_member(message)
	end,
	follow = function(message)
		api.on_follow(message)
	end,
	host = function(message)
		api.on_host(message)
	end,
	raid = function(message)
		api.on_raid(message)
	end,
	get_deathcount_list = function()
		return publish(global.data.deathcount)
	end,
	-- [[
	-- Setting for enabling/disabling the statistics export
	-- 0 = disabled
	-- 1 = write to file (most consistent)
	-- 2 = enable it, but wait for remote to call to collect the statistics
	-- ]]
	set_statistics_export = function(setting)
		global.config.export_statistics = setting
	end,
	set_store_requests = function(type, bool)
		if global.config.store_requests[type] ~= nil then
			global.config.store_requests = bool
		end
	end,
	get_stored_requests = function(type)
		if global.config.store_requests[type] then
			return publish(global.data.requests[type])
		elseif type == 'all' then
			return publish(global.data.requests)
		end

		return publish(nil)
	end,
	collect_statistics = function()
		if global.config.export_statistics == 2 then
			return publish(statistics:store_results(game.tick))
		end
	end,
	message_to_game_chat = function(msg, color)
		-- Use chat color if available
		if type(color) == 'string' and color:len() > 0 then
			color = util.color(color)
		else
			color = false
		end
		color = color or { r = 0.83499997854233, g = 0.66600000858307, b = 0.076999999582767, a = 0.5 }

		if msg.to_player then
			local player = game.players[msg.to_player]
			if player and player.valid then
				player.print(msg.name .. ": " .. msg.msg, color)
			elseif rcon then
				publish('Player not found; ' .. msg.to_player)
			end
		else
			game.print(msg.name .. ": " .. msg.msg, color)
		end
	end,
})
