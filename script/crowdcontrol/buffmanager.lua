--
-- Created by IntelliJ IDEA.
-- User: timvroom
-- Date: 11/04/2019
-- Time: 22:24
-- To change this template use File | Settings | File Templates.
--
local buffManager = {
}

buffManager.get_data = function()
	return global.crowdcontrol
end
--
-- field = 'manual_crafting_speed_modifier',
-- config_type = 'handcraft'
-- target = 'force',
-- type_target = 'player'
-- duration = 3600
-- display_name = 'display_name'
-- value = -1
-- calc = function(orig_value, current_value, target)...

-- /c remote.call('tvc_api.crowdcontrol', 'apply', {type = 'force', type_target = 'player', field = 'manual_crafting_speed_modifier', config_type = 'handcraft', value=-1, duration=3200, display_name="test"})
buffManager.add_buff = function(buff)
	local data = buffManager.get_data()
	local target_table = false
	local target_setting
	if (buff.type == 'force') then
		target_table = 'forces'
	elseif (buff.type == 'player') then
		target_table = 'players'
	elseif buff.type == 'setting' then
		target_setting = buff.type_target
	end

	if target_table then
		for _, target in pairs(game[target_table]) do
			if target.valid then
				if (buff.type_target and target.name == buff.type_target) or buff.type_target == nil then
					buffManager._process_add(data.state[target_table], target, buff)
				end
			end
		end
	elseif target_setting then
		local setting = settings.global
		if setting[target_setting] then
			buffManager._process_add(data.state.setting, setting[target_setting], buff)
		end
	end
end

buffManager._process_add = function(data, target, buff)
	if data[target.name] == nil then
		data[target.name] = {
			name = target.name,
			buffs = {}
		}
	end

	if data[target.name].buffs[buff.config_type] == nil then
		data[target.name].buffs[buff.config_type] = { field = buff.field, list = {} }
	end

	local current_value = 0
	if pcall(function()
		return target[buff.field]
	end) then
		current_value = target[buff.field]
		if type(current_value) == 'table' and current_value.value ~= nil then
			current_value = current_value.value
		end
	end
	local update_value = buff.value
	local current_buffs = data[target.name].buffs[buff.config_type]
	local orig_value = buffManager.without_buff(current_value, current_buffs)

	if buff.calc ~= nil and type(buff.calc) == 'function' then
		update_value, current_value, orig_value = buff.calc(current_value, orig_value, target)
	end

	buffManager._add_buff_to_list(current_buffs.list, buff, { value = update_value }, current_value, orig_value)
end

buffManager._add_buff_to_list = function(list, buff, insert, current_value, orig_value)
	local tick = game.tick
	local config = buffManager.get_data().config[buff.config_type]

	insert.active = false
	insert.duration = buff.duration
	insert.source = buff.display_name

	if (buffManager._validate_buff(config, current_value, orig_value, insert)) then
		insert.start = tick
	end

	table.insert(list, insert)
end

buffManager.get_last_added_list = function()
	return global.crowdcontrol.last_items
end

buffManager.add_last_added_list = function(entry)
	local list = global.crowdcontrol.last_items

	table.insert(list, 1, entry)
	if #list > 5 then
		for i=6, #list, 1 do
			table.remove(list, i)
		end
	end
end

buffManager.activate_buffs = function(event)
	local data = buffManager.get_data()
	local tick = event.tick
	for target, t in pairs(data.state) do
		for _, row in pairs(t) do
			local target_table
			if target == 'setting' then
				target_table = settings.global[row.name]
			else
				target_table = game[target][row.name]
			end
			for buff_type, buff in pairs(row.buffs) do
				for idx, line in pairs(buff.list) do
					local current_value = 0
					if pcall(function()
						return target_table[buff.field]
					end) then
						current_value = target_table[buff.field]
					end
					local orig_value = buffManager.without_buff(current_value, buff)
					local config = data.config[buff_type]

					-- Check for can start
					if line.active == false and buffManager._validate_buff(config, current_value, orig_value, line) then
						line.start = tick
					end

					if line.start and line.start <= tick and line.active == false then
						if config.apply_function ~= nil then
							if type(config.apply_function) == 'function' then
								config.apply_function(config, target_table, tick, { current = current_value, new = line.value })
							else
								buffManager[config.apply_function](config, target_table, tick, { current = current_value, new = line.value })
							end
						else
							target_table[buff.field] = current_value + line.value
						end
						line.expires = tick + line.duration
						line.active = true
					end

					if line.expires and line.expires < tick then
						if config.apply_function == nil then
							target_table[buff.field] = current_value - line.value
						end
						line.active = false
						table.remove(buff.list, idx)
					end
				end
			end
		end
	end
end

buffManager._validate_buff = function(config, current_value, orig_value, insert)
	local target_value = current_value + insert.value

	if config.min ~= nil and target_value < config.min then
		return false
	end
	if config.max ~= nil and target_value > config.max then
		return false
	end

	if config.stackable == false then
		if (current_value - orig_value < 0 and insert.value < 0) then
			return false
		elseif (current_value - orig_value > 0 and insert.value > 0) then
			return false
		end
	end

	local cooldowns = buffManager.get_data().cooldowns
	local tick = game.tick

	if config.cooldown and config.apply_function and cooldowns[config.apply_function] > tick then
		return false
	end

	return true
end

buffManager.get_player_buff = function(player, buffname)
	local data = buffManager.get_data()
	if data.state.players[player.name] then
		if data.state.players[player.name].buffs[buffname] then
			local diff = 0
			for _, v in pairs(data.state.players[player.name].buffs[buffname].list) do
				if v.active then
					diff = diff + v.value
				end
			end
			return diff
		end
	end

	return 0
end

buffManager._calculate_current_active_buffs = function()
	local current_active = {};
	for target, t in pairs(data.state) do
		for _, row in pairs(t) do
			local target_table
			if target == 'setting' then
				target_table = settings.global[row.name]
			else
				target_table = game[target][row.name]
			end
			for buff_type, buff in pairs(row.buffs) do
				local active_list = table.filter(buff.list, function(v)
					return v.active;
				end);

				for idx, line in pairs(active_list) do
					if current_active[buff_type] == nil then
						current_active[buff_type] = 0
					end

					current_active[buff_type] = current_active[buff_type] + line.value
				end
			end
		end
	end

	buffManager.get_data().current_active = current_active;
end

buffManager.without_buff = function(current_value, fields)
	local new_value = current_value + 0
	for _, row in pairs(fields.list) do
		if (row.active) then
			new_value = new_value + (1 - row.value)
		end
	end
	return new_value
end

buffManager.empty = function(config, target, tick)
end

buffManager.random_teleport = function(config, target, tick)

end

buffManager.apply_setting = function(config, target, tick, entry)
	target.value = entry.value + entry.new
end

buffManager.fakedeath = function(config, target, tick)
	-- fake death

	local cooldowns = buffManager.get_data().cooldowns
	cooldowns.fakedeath = tick + config.cooldown
end

return buffManager
