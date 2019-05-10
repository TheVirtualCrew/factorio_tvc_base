local gui = {}

gui.create_frame = function(player)

end

gui.update_tables = function()
	for _, player in pairs(game.players) do
		gui.update_player_table(player)
	end
end

gui.update_player_table = function(player)

	if player and player.valid and player.gui then
		local guitable = gui.get_table(player)
		if (guitable and guitable.valid) then

		end

	end
end

gui.get_table = function(player)
	if not player.gui then
		return
	end
	local frame = player.gui.left
	local info_frame

	if frame == nil or not frame.valid then
		return
	end

	local name_prefix = s28.prefix .. 'info_table'
	local setting = settings.get_player_settings(player)[s28.settings.show_table].value
	if not setting then
		local flow = frame[name_prefix .. "_flow"]
		if flow and flow.valid then
			flow.destroy();
		end

		return
	end

	local flow = frame[name_prefix .. "_flow"]
	if flow == nil or not flow.valid then
		if flow then
			flow.destroy()
		end
		flow = frame.add {
			type = "flow",
			name = name_prefix .. "_flow",
			direction = "vertical",
		}
		flow.style.horizontally_stretchable = false
	end

	info_frame = flow[name_prefix .. "_frame"]
	if info_frame == nil or not info_frame.valid then
		if info_frame then
			info_frame.destroy()
		end
		info_frame = flow.add {
			type = "frame",
			name = name_prefix .. "_frame",
			direction = "vertical",
			style = mod_gui.frame_style,
			caption = "TVC API",
		}
		info_frame.style.horizontally_stretchable = false
	end

	local table = info_frame[name_prefix]
	if table == nil then
		table = info_frame.add {
			type = 'table',
			column_count = 3,
			name = name_prefix,
		}
		table.style.column_alignments[1] = "right"
		table.add { type = 'label', name = s28.gui.amount_member .. '_label', caption = { s28.gui.amount_member .. '_label' }, style = 'bold_label' }
		table.add { type = 'label', name = s28.gui.amount_member .. '_value', caption = '0 / 0' }
		table.add { type = 'button', name = s28.gui.amount_member .. '_button', caption = '+', enabled = false, style = "search_button" }
	end

	return table
end

return gui;
