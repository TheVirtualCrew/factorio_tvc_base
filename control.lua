-- [[
-- Api base mod
-- ]]

require "util"

Event = require('__stdlib__/stdlib/event/event')
api = require "script.api"
statistics = require("script.statistics")
local output_file = 'tvc_api.json'
events = {}

local function init_globals()
	global.config = global.config or {
		export_statistics = false,
		store_requests = {
			donation = true,
			member = true,
			follow = false,
			raid = false,
			host = false,
			merch = false,
			subgift = false,
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
			merch = {},
			subgift = {},
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

	return msg;
end

function raise_event(event_name, event_data, between)
	local responses
	between = between or function() end
	for interface_name, interface_functions in pairs(remote.interfaces) do
		if interface_functions[event_name] then
			local cur_response = remote.call(interface_name, event_name, event_data)
			if cur_response ~= nil then
				responses = cur_response
				between(event_data, cur_response)
			end
		end
	end
	return responses
end

init_globals()

Event.on_init(function()
	init_globals()
end)
Event.on_load(function()
	api.setup_events(true)
end);

Event.on_event(defines.events.on_tick, function(event)
	if global.config.export_statistics == 1 and event.tick ~= 0 and event.tick % 60 == 0 then
		write_external('statistics', statistics:store_results(event.tick), "tvc_statistics.txt")
	end
end)

Event.on_event(defines.events.on_pre_player_died, function(event)
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

	local copy = table.deepcopy(event)
	copy.cause_name = cause
	cause = raise_event('tvc_api_on_death', copy, function(e, b) e.cause_name = b end) or cause

	if global.data.deathcount[player_name][cause] == nil then
		global.data.deathcount[player_name][cause] = 0
	end

	global.data.deathcount[player_name][cause] = global.data.deathcount[player_name][cause] + 1
end)

remote.add_interface("tvc_api", {
	get_events = function()
		return events
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
	merch = function(message)
		api.on_merch(message);
	end,
	subgift = function(message)
		api.on_subgift(message);
	end,
	get_deathcount_list = function()
		return write_external('deathcount', global.data.deathcount)
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
			global.config.store_requests[type] = bool
		end
	end,
	get_stored_requests = function(type)
		if global.config.store_requests[type] then
			return write_external('get_stored_requests', global.data.requests[type])
		elseif type == 'all' then
			return write_external('get_stored_requests', global.data.requests)
		end

		return write_external('get_stored_requests', nil)
	end,
	clear_statistics_from_tick = function(tick)
		api.remove_stored_requests_since_tick(tick);
	end,
	collect_statistics = function()
		if global.config.export_statistics == 2 then
			return write_external('collect_statistics', statistics:store_results(game.tick))
		end
	end,
	write_out = function(command, value)
		if type(value) == 'function' then
			value = value();
		end

		return write_external(command, value);
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
				if game.is_valid_sound_path("api_console_message") then
					game.play_sound({ path = 'api_console_message' });
				end
			elseif rcon then
				write_external('in_game_message', 'Player not found; ' .. msg.to_player)
			end
		else
			game.print(msg.name .. ": " .. msg.msg, color)
			if game.is_valid_sound_path("api_console_message") then
				game.play_sound({ path = 'api_console_message' });
			end
		end
	end,
})
