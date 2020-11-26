local api = {}
local temp_subgift = {}
local shared = require("shared")
events = {}
local script_data = {
  requests = {
    donation = {},
    member = {},
    follow = {},
    raid = {},
    host = {},
    merch = {},
    subgift = {},
    channel_point = {},
    hypetrain = {}
  },
  store_requests = {
    donation = true,
    member = true,
    follow = false,
    raid = false,
    host = false,
    merch = false,
    subgift = true,
    channel_point = false,
    hypetrain = false
  }
}

local function setup_events(forced)
  forced = forced or false
  if (events.api_on_donation == nil) or forced then
    events = {
      api_on_donation = script.generate_event_name(),
      api_on_member = script.generate_event_name(),
      api_on_follow = script.generate_event_name(),
      api_on_raid = script.generate_event_name(),
      api_on_host = script.generate_event_name(),
      api_on_merch = script.generate_event_name(),
      api_on_subgift = script.generate_event_name(),
      api_on_channel_point = script.generate_event_name(),
      api_on_hypetrain_start = script.generate_event_name(),
      api_on_hypetrain_progress = script.generate_event_name(),
      api_on_hypetrain_end = script.generate_event_name(),
    }
  end
end

local function store_request(type, message)
  if script_data.store_requests[type] then
    local entry = {}
    if (type == "donation") then
      entry.amount = message.amount
      entry.message = message.message

      if (message.type ~= "bits") then
        entry.formatted_amount = message.formatted_amount
        entry.currency = message.currency
      end
    elseif (type == "member") then
      -- general
      entry.months = message.months

      -- Twitch stuff
      entry.sub_plan = "1000"
      if message.sub_plan then
        entry.sub_plan = message.sub_plan
        entry.sub_type = message.sub_type
      end

      if message.gifter then
        entry.gifter = message.gifter_display_name or message.gifter
      end

      if message.streak_months then
        entry.streak_months = message.streak_months
      end
    elseif (type == "raid") then
      entry.amount = message.raiders
    elseif (type == "host") then
      entry.amount = message.viewers
    elseif (type == "follow") then
      -- continue
    elseif (type == "merch") then
      entry.product = message.product
      entry.message = message.message or nil
    elseif (type == "subgift") then
    elseif (type == "channel_point") then
    elseif (type == "hypetrain_start") then
    elseif (type == "hypetrain_progress") then
    elseif (type == "hypetrain_end") then
    else
      return
    end

    entry.type = message.type
    entry.name = message.display_name or message.name
    entry.tick = game.tick

    table.insert(script_data.requests[type], entry)
  end
end

api.get_events = function()
  setup_events()

  return events
end

api.get_store_requests = function(type)
  if script_data.store_requests[type] then
    return script_data.store_requests[type]
  elseif type == "all" then
    return script_data.store_requests
  end

  return nil
end

api.set_store_requests = function(type, bool)
  if script_data.store_requests[type] ~= nil then
    script_data.store_requests[type] = bool
  end
end

api.on_donation = function(message)
  script.raise_event(events.api_on_donation, {message = message, tick = game.tick})
  store_request("donation", message)
end

api.on_member = function(message)
  script.raise_event(events.api_on_member, {message = message, tick = game.tick})
  store_request("member", message)
end

api.on_follow = function(message)
  script.raise_event(events.api_on_follow, {message = message, tick = game.tick})
  store_request("follow", message)
end

api.on_host = function(message)
  script.raise_event(events.api_on_host, {message = message, tick = game.tick})
  store_request("host", message)
end

api.on_raid = function(message)
  script.raise_event(events.api_on_raid, {message = message, tick = game.tick})
  store_request("raid", message)
end

api.on_merch = function(message)
  script.raise_event(events.api_on_merch, {message = message, tick = game.tick})
  store_request("merch", message)
end

-- Have to check for duplicate events... twitch tend to send it twice
api.on_subgift = function(message)
  local last = temp_subgift
  if last and last.event_id == message.event_id then
    return
  end

  last = message
  script.raise_event(events.api_on_subgift, {message = message, tick = game.tick})
  store_request("subgift", message)
end

api.on_channel_point = function(message)
  script.raise_event(events.api_on_channel_point, {message = message, tick = game.tick})
  store_request("channel_point", message)
end

api.on_hypetrain_start = function(message)
  script.raise_event(events.api_on_hypetrain_start, {message = message, tick = game.tick})
  store_request("hypetrain", message)
end

api.on_hypetrain_progress = function(message)
  script.raise_event(events.api_on_hypetrain_progress, {message = message, tick = game.tick})
  store_request("hypetrain", message)
end

api.on_hypetrain_end = function(message)
  script.raise_event(events.api_on_hypetrain_end, {message = message, tick = game.tick})
  store_request("hypetrain", message)
end

api.remove_stored_requests_since_tick = function(tick)
  local requests = global.data.requests
  for _, type in pairs(requests) do
    for i, entry in pairs(type) do
      if entry.tick and entry.tick < tick then
        type[i] = nil
      end
    end
  end
end

api.on_init = function()
  global.api_data = global.api_data or script_data
end

api.on_load = function()
  script_data = global.api_data or script_data
  setup_events(true)
end

api.on_nth_tick = {
  [shared.clear_timer] = function(event)
    local tick = event.tick - shared.clear_timer
    if tick > 0 then
      api.remove_stored_requests_since_tick(tick)
    end
  end
}

api.on_configuration_changed = function(event)
  if global.config and global.config.store_requests then
    for k, v in pairs(global.config.store_requests) do
      script_data.store_requests[k] = v
    end
    global.config.store_requests = nil
  end

  if global.data and global.data.requests then
    for k, v in pairs(global.data.requests) do
      script_data.requests[k] = v
    end
    global.data.requests = nil
  end
end

return api
