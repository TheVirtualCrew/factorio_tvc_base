commands.add_command("tvc_debug", {""}, function(e)
  -- asdf
end)

local function get_gui_root(player)
  return player.gui.screen
  --return player.gui.top
end

local monetary_types = {
  [1] = {name = "Bits (Twitch)", type = "bits", api = "donation"},
  [2] = {name = "Donation", type = "donation", api = "donation"},
  [3] = {name = "Channel Points", type = "channel_point", api = "channel_point", reward = "Sample"}
  --[4] = {name = "Superchat (YouTube)", type = "???", api = "donation"}
}
local sub_types = {
  [1] = {name = "Sub (Twitch)", type = "subscription", api = "member"},
  [2] = {name = "Patreon", type = "pledge", api = "member"},
  [3] = {name = "Giftsub", type = "subMysteryGift", api = "subgift"},
  --[4] = {name = "Sub (YouTube)", type = "???", api = "member"}
}
local sub_tiers = {
  [1] = {name = "Tier 1", level = 1000, amount = 5},
  [2] = {name = "Tier 2", level = 2000, amount = 10},
  [3] = {name = "Tier 3", level = 3000, amount = 25}
}
local misc_types = {
  [1] = {name = "Follow (Twitch)", type = "follow", api = "follow"},
  [2] = {name = "Host", type = "host", api = "host", viewers = true},
  [3] = {name = "Raid", type = "raid", api = "raid", raiders = true},
  --[4] = {name = "Follow (YouTube)", type = "???", api = "???"}
}



local debug_ui = {}

debug_ui.hide_window = function(player)
	local root = get_gui_root(player)
	if root.tvc_debug_ui then
		root.tvc_debug_ui.destroy()
	end
end

debug_ui.show_window = function(player) 
  local root = get_gui_root(player)
  
  if not root.tvc_debug_ui then
    local tvc_debug_ui = root.add({
      type = "frame",
      name = "tvc_debug_ui",
      direction =  "vertical",
    })

    local flow = tvc_debug_ui.add({
      type = "flow",
      name = "tvc_debug_ui_flow"
    })
    flow.style.horizontally_stretchable = "on"

    flow.add({
      type = "label",
      name = "tvc_debug_ui_title",
      caption = "TVC Debug",
      style = "frame_title"
    }).drag_target = tvc_debug_ui

    local widget = flow.add({
      type = "empty-widget",
      style = "draggable_space_header",
			name = "tvc_debug_ui_drag"
    })
    widget.drag_target = tvc_debug_ui
    widget.style.horizontally_stretchable = "on"
    widget.style.minimal_width = 24
    widget.style.natural_height = 24

    flow.add({
      type = "sprite-button",
      sprite = "utility/close_white",
      style = "frame_action_button",
      name = "tvc_debug_ui_close"
    })

    local table = tvc_debug_ui.add({
      type = "table",
      name = "tvc_debug_ui_table",
      column_count = "6",
      vertical_centering = "false"
    })


    -- monetary stuff (bits / donations / superchat)
    table.add({
      type = "label",
      caption = "Monetary"
    })
    local monetary_type = table.add({
      type = "drop-down",
      name = "tvc_debug_ui_monetary_type"
    })
    for i, result in ipairs(monetary_types) do
      monetary_type.add_item(result["name"])
    end
    monetary_type.selected_index = 1
    table.add({
      type = "textfield",
      name = "tvc_debug_ui_monetary_amount",
      text = "1"
    }).style.width = 50
    table.add({
      type = "textfield",
      name = "tvc_debug_ui_monetary_from",
      text = "from"
    }).style.width = 100
    table.add({
      type = "textfield",
      name = "tvc_debug_ui_monetary_message",
      text = "message"
    }).style.width = 200
    table.add({
      type = "button",
      name = "tvc_debug_ui_monetary_send",
      caption = "send"
    }).style.width = 60


    -- sub stuff (sub / patreon / giftsub)
    table.add({
      type = "label",
      caption = "Subs"
    })
    local sub_type = table.add({
      type = "drop-down",
      name = "tvc_debug_ui_sub_type"
    })
    for i, result in ipairs(sub_types) do
      sub_type.add_item(result["name"])
    end
    sub_type.selected_index = 1
    local sub_tier = table.add({
      type = "drop-down",
      name = "tvc_debug_ui_sub_tier",
    })
    for i, result in ipairs(sub_tiers) do
      sub_tier.add_item(result["name"])
    end
    sub_tier.selected_index = 1
    table.add({
      type = "textfield",
      name = "tvc_debug_ui_sub_from",
      text = "from"
    }).style.width = 100
    table.add({
      type = "textfield",
      name = "tvc_debug_ui_sub_message",
      text = "message"
    }).style.width = 200
    table.add({
      type = "button",
      name = "tvc_debug_ui_sub_send",
      caption = "send"
    }).style.width = 60


    -- misc (follow, host, raid)
    table.add({
      type = "label",
      caption = "Misc"
    })
    local misc_type = table.add({
      type = "drop-down",
      name = "tvc_debug_ui_misc_type"
    })
    for i, result in ipairs(misc_types) do
      misc_type.add_item(result["name"])
    end
    misc_type.selected_index = 1
    table.add({
      type = "textfield",
      name = "tvc_debug_ui_misc_amount",
      text = 50
    }).style.width = 50
    table.add({
      type = "textfield",
      name = "tvc_debug_ui_misc_from",
      text = "from"
    }).style.width = 100
    table.add({
      type = "textfield",
      name = "tvc_debug_ui_misc_message",
      text = "message"
    }).style.width = 200
    table.add({
      type = "button",
      name = "tvc_debug_ui_misc_send",
      caption = "send"
    }).style.width = 60


		tvc_debug_ui.force_auto_center()
  end
end

debug_ui.monetary_action = function(player)
  local root = get_gui_root(player).tvc_debug_ui.tvc_debug_ui_table
  local index = root.tvc_debug_ui_monetary_type.selected_index
  local api = monetary_types[index]["api"]

  if remote.interfaces["tvc_api"][api] then
    local type = monetary_types[index]["type"]
    local name = root.tvc_debug_ui_monetary_from.text
    local amount = root.tvc_debug_ui_monetary_amount.text
    local message = root.tvc_debug_ui_monetary_message.text
    local reward
    if type == "channel_point" then
      reward = monetary_types[index]["reward"]
    end

    message = message or "test message"
    remote.call("tvc_api", api, {
      id = "test-123",
      name = name,
      display_name = name,
      amount = amount,
      emotes = nil,
      message = message,
      reward = reward,
      reward_name = reward,
      _id = "id123",
      event_id = "id123",
      type = type,
      currency = "USD",
      ["for"] = "twitch_account",
      streamer_source = "nilaus"
    })
  end
end

debug_ui.sub_action = function(player)
  local root = get_gui_root(player).tvc_debug_ui.tvc_debug_ui_table
  local index = root.tvc_debug_ui_sub_type.selected_index
  local api = sub_types[index]["api"]

  if remote.interfaces["tvc_api"][api] then
    local type = sub_types[index]["type"]
    local name = root.tvc_debug_ui_sub_from.text
    local tier = root.tvc_debug_ui_sub_tier.selected_index
    local amount 
    local sub_plan
    local message = root.tvc_debug_ui_sub_message.text
    local gifter
    local sub_type

    if type == "pledge" then
      sub_plan = "undefined"
      amount = sub_tiers[tier]["amount"]
    else
      sub_plan = sub_tiers[tier]["level"]
    end

    if api == "subgift" then
      gifter = name
      sub_type = "submysterygift"
      amount = 5
    end

    message = message or "test message"
    remote.call("tvc_api", api, {
      id = "test-123",
      name = name,
      display_name = name,
      gifter = gifter,
      gifter_display_name = gifter,
      amount = amount,
      sub_plan = sub_plan,
      emotes = nil,
      message = message,
      _id = "id123",
      event_id = "id123",
      type = type,
      sub_type = sub_type,
      currency = "USD",
      ["for"] = "twitch_account",
      streamer_source = "nilaus"
    })
  end
end

debug_ui.misc_action = function(player)
  local root = get_gui_root(player).tvc_debug_ui.tvc_debug_ui_table
  local index = root.tvc_debug_ui_misc_type.selected_index
  local api = misc_types[index]["api"]

  if remote.interfaces["tvc_api"][api] then
    local type = misc_types[index]["type"]
    local name = root.tvc_debug_ui_misc_from.text
    local nr = root.tvc_debug_ui_misc_amount.text
    local viewers
    local raiders
    local message = root.tvc_debug_ui_sub_message.text

    if misc_types[index]["viewers"] then
      viewers = nr
    end
    if misc_types[index]["raiders"] then
      raiders = nr
    end

    message = message or "test message"
    remote.call("tvc_api", api, {
      id = "test-123",
      name = name,
      display_name = name,
      emotes = nil,
      message = message,
      viewers = viewers,
      raiders = raiders,
      _id = "id123",
      event_id = "id123",
      type = type,
      ["for"] = "twitch_account",
      streamer_source = "nilaus"
    })
  end
end

debug_ui.toggle_window = function(player)
  local root = get_gui_root(player)
	if root and root.tvc_debug_ui then
		debug_ui.hide_window(player)
	else
		debug_ui.show_window(player)
	end
end

debug_ui.events = {
  [defines.events.on_console_command] = function(event)
    local player = game.players[event.player_index]
    if event.command == "tvc_debug" then
      debug_ui.toggle_window(player)
    end
  end,
  [defines.events.on_gui_click] = function(event)
    local player = game.players[event.player_index]
    local event_name = event.element.name
    if event_name == "tvc_debug_ui_close" then
      debug_ui.hide_window(player)
    elseif event_name == "tvc_debug_ui_monetary_send" then
      debug_ui.monetary_action(player)
    elseif event_name == "tvc_debug_ui_sub_send" then
      debug_ui.sub_action(player)
    elseif event_name == "tvc_debug_ui_misc_send" then
      debug_ui.misc_action(player)
    end
  end
}

return debug_ui