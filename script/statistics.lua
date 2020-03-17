-- Statistics counter for outputing to file
require "util"

local shared = require("shared")
local write_external = shared.write_external
local floor = math.floor
local script_data = {
  export_statistics_mode = false,
  deathcount = {}
}

local function combine(tables)
  local res = {}
  for _, tabs in ipairs(tables) do
    for _, tab in pairs(tabs) do
      table.insert(res, tab)
    end
  end
  return res
end

local function floorToNearest(number, multiple)
  return floor(number / multiple) * multiple
end

local function get_stats(force, type, name, tick)
  if force == nil then
    force = game.forces.player
  end

  if force and force[type .. "_statistics"] then
    tick = floorToNearest(tick, 60)
    local stats = force[type .. "_statistics"]

    return {
      {
        tick = tick,
        type = name .. "_input_counts",
        items = stats.input_counts
      },
      {
        tick = tick,
        type = name .. "_output_counts",
        items = stats.output_counts
      }
    }
  end
end

local function raise_call_event(event_name, event_data, between)
  local responses
  between = between or function()
    end

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

local statistics = {}
statistics.get_items = function(force, tick)
  return get_stats(force, "item_production", "item", tick)
end
statistics.get_kills = function(force, tick)
  return get_stats(force, "kill_count", "kill", tick)
end
statistics.get_build = function(force, tick)
  return get_stats(force, "entity_build_count", "build", tick)
end
statistics.store_results = function(force, tick)
  local playerForce = force or game.forces.player
  local result =
    combine(
    {
      statistics.get_items(force, tick),
      statistics.get_kills(force, tick),
      statistics.get_build(force, tick)
    }
  )

  return {
    multiple = true,
    rows = result
  }
end

statistics.get_deathcount = function(player)
  if player then
    return script_data.deathcount[player] or nil
  end

  return script_data.deathcount
end

statistics.set_export_mode = function(mode)
  script_data.export_statistics_mode = mode
end

statistics.is_file_mode = function()
  return script_data.export_statistics_mode == 1
end

statistics.is_rcon_mode = function()
  return script_data.export_statistics_mode == 2
end

statistics.on_init = function()
  global.statistics_data = global.statistics_data or script_data
end

statistics.on_load = function()
  script_data = global.statistics_data or script_data
end

statistics.on_configuration_changed = function()
  if global.config and global.config.export_statistics then
    script_data.export_statistics_mode = global.config.export_statistics
    global.config.export_statistics = nil
  end

  if global.data and global.data.deathcount then
    script_data.deathcount = global.data.deathcount
    global.data.deathcount = nil
  end
end

statistics.on_nth_tick = {
  [60] = function(event)
    if statistics.is_file_mode() and event.tick ~= 0 then
      write_external("statistics", statistics.store_results(event.tick), shared.statistics_file)
    end
  end
}

statistics.events = {
  [defines.events.on_pre_player_died] = function(event)
    local cause = "other"
    local player_name = game.players[event.player_index].name
    local train_types = {locomotive = 1, ["cargo-wagon"] = 1, ["artillery-wagon"] = 1, ["fluid-wagon"] = 1}
    local deathcount = script_data.deathcount

    if event.cause then
      local v = event.cause
      if train_types[v.type] then
        cause = "train"
      elseif v.type == "player" and v.player ~= nil and v.player.name == player_name then
        cause = "suicide"
      elseif v.force and v.force.name == "enemy" then
        cause = "biter"
      end
    end

    if not deathcount[player_name] or type(deathcount[player_name]) ~= "table" then
      deathcount[player_name] = {
        suicide = 0,
        train = 0,
        biter = 0,
        other = 0
      }
    end

    local copy = table.deepcopy(event)
    copy.cause_name = cause
    cause =
      raise_call_event(
      "tvc_api_on_death",
      copy,
      function(e, b)
        e.cause_name = b
      end
    ) or cause

    if deathcount[player_name][cause] == nil then
      deathcount[player_name][cause] = 0
    end

    deathcount[player_name][cause] = deathcount[player_name][cause] + 1
  end
}

return statistics
