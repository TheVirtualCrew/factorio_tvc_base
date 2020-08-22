local function track_event(event)
  local deathcount = global.statistics_data.deathcount
  remote.call("graftorio", "get_gauge", "factorio_deathcounter", "Deathcounter", {"name", "cause"})

  for player_name, counts in pairs(deathcount) do
    for cause, count in pairs(counts) do
      remote.call("graftorio", "gauge_set", "factorio_deathcounter", count, {player_name, cause})
    end
  end
end
local lib = {
  on_load = function()
    if remote.interfaces["graftorio"] then
      events = remote.call("graftorio", "get_plugin_events")
      script.on_event(events.graftorio_add_stats, track_event)
    end
  end
}
return lib