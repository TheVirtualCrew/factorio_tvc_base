local api = require("script.api")
local statistics = require("script.statistics")
local shared = require("shared")
local output_file = shared.output_file
local write_external = shared.write_external

local interface = {
  get_events = function()
    return api.get_events()
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
    api.on_merch(message)
  end,
  subgift = function(message)
    api.on_subgift(message)
  end,
  channel_point = function(message)
    api.on_channel_point(message)
  end,
  get_deathcount_list = function()
    return write_external("deathcount", statistics.get_deathcount())
  end,
  -- [[
  -- Setting for enabling/disabling the statistics export
  -- 0 = disabled
  -- 1 = write to file
  -- 2 = enable it, but wait for remote to call to collect the statistics
  -- ]]
  set_statistics_export = function(setting)
    statistics.set_export_mode(setting)
  end,
  set_store_requests = function(type, bool)
    api.set_store_requests(type, bool)
  end,
  get_stored_requests = function(type)
    write_external("get_stored_requests", api.get_stored_requests(type))
  end,
  clear_requests_from_tick = function(tick)
    api.remove_stored_requests_since_tick(tick)
  end,
  collect_statistics = function(type, force)
    if statistics.is_rcon_mode() then
      if force == nil then
        force = game.forces.player
      end
      if type and statistics["get_" .. type] ~= nil then
        return write_external("collect_statistics", statistics["get_" .. type](force, game.tick))
      end

      return write_external("collect_statistics", statistics.store_results(force, game.tick))
    end
  end,
  write_out = function(command, value)
    if type(value) == "function" then
      value = value()
    end

    return write_external(command, value)
  end,
  message_to_game_chat = function(msg, color)
    -- Use chat color if available
    if type(color) == "string" and color:len() > 0 then
      color = util.color(color)
    else
      color = false
    end
    color = color or {r = 0.83499997854233, g = 0.66600000858307, b = 0.076999999582767, a = 0.5}

    if msg.to_player then
      local player = game.players[msg.to_player]
      if player and player.valid then
        player.print(msg.name .. ": " .. msg.msg, color)
        if game.is_valid_sound_path("api_console_message") then
          player.play_sound({path = "api_console_message"})
        end
      elseif rcon then
        write_external("in_game_message", "Player not found; " .. msg.to_player)
      end
    else
      game.print(msg.name .. ": " .. msg.msg, color)
      if game.is_valid_sound_path("api_console_message") then
        game.play_sound({path = "api_console_message"})
      end
    end
  end
}

local lib = {}

lib.add_remote_interface = function()
  if not remote.interfaces["tvc_api"] then
    remote.add_interface("tvc_api", interface)
  end
end

return lib
