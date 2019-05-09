--
-- Created by IntelliJ IDEA.
-- User: timvroom
-- Date: 11/04/2019
-- Time: 21:16
-- To change this template use File | Settings | File Templates.
--

local crowdcontrol = {}

local buffManager = require "script.crowdcontrol.buffmanager"
local base_config = require "script.crowdcontrol.config"
-- example
local buffManager_opts = {
	active_buff = {
		handcraft = {
			{ value = 10, expires = 2000, source = 'display_name' },
			{ value = 10, starts = 2000, expires = 4000, source = 'display_name' }
		},
		botspeed = {
			{ value = 3, starts = 500, expires = 1000, source = 'display_name' }
		}
	},
}

crowdcontrol.init = function()
	if global.crowdcontrol == nil then
		global.crowdcontrol = {
			config = base_config,
			cooldowns = {},
			state = {
				forces = {},
				players = {},
				setting = {}
			},
			last_items = {}
		}
	end
end

crowdcontrol.get_data = function()
	return global.crowdcontrol
end

-- remote.call('tvc_api.crowdcontrol', 'apply', {type='force', field='manual_crafting_speed_modifier', value=1, config_type='handcraft'})
crowdcontrol.add_interfaces = function(prefix)
	prefix = prefix or 'tvc_api.crowdcontrol'

	remote.add_interface(prefix, {
		log = function()
			game.print(serpent.block(global.crowdcontrol))
		end,
		apply = function(buff)
			crowdcontrol.apply(buff)
		end,
		add_config = function(name, entry)
			local config = global.crowdcontrol.config
			if config[name] ~= nil then
				config[name] = util.merge({ config[name], entry })
			else
				config[name] = entry
			end
		end
	})
end

crowdcontrol.on_entity_damaged = function(event)
	local entity = event.entity
	if entity.type == 'player' then
		local buff = buffManager.get_player_buff(entity.player, 'damage_mod')
		if buff < -75 then
			buff = -75
		elseif buff > 0 then

		end
		local dmg = 0
		if buff < 0 then
			dmg = (event.final_damage_amount * (-1 * buff) / 100)
		elseif buff > 0 then
			dmg = 0 - (event.final_damage_amount * (buff) / 100)
		end
		--entity.damage(dmg, event.force, 'scripted')


		--entity.health = entity.health - dmg
	end
end

crowdcontrol.apply = function(update)
	buffManager.add_buff(update)
end

-- update = { duration = x, calc = '', target = 'force|player' }
crowdcontrol.update = function(event)
	if (event.tick % (60 * 2) == 0) then
		buffManager.activate_buffs(event)
	end
end

crowdcontrol.add_interfaces()
Event.on_init(crowdcontrol.init)
Event.on_configuration_changed(function(event)
	if event.name:find('tvc_api_base') then
		if global.crowdcontrol.config then
			global.crowdcontrol.config = util.merge({ base_config, global.crowdcontrol.config })
		end
	end
end)
Event.register(defines.events.on_entity_damaged, crowdcontrol.on_entity_damaged)
Event.register(defines.events.on_tick, crowdcontrol.update)

return crowdcontrol
