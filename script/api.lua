local api = {};

api.setup_events = function()
	if (#global.events == 0) then
		global.events = {
			api_on_donation = Event.generate_event_name('api_on_donation'),
			api_on_member = Event.generate_event_name('api_on_member'),
			api_on_follow = Event.generate_event_name('api_on_follow'),
			api_on_raid = Event.generate_event_name('api_on_raid'),
			api_on_host = Event.generate_event_name('api_on_host'),
		}
	end
end

api.on_donation = function(message)
	Event.raise_event(global.events.api_on_donation, { message = message, tick = game.tick });
	api.store_request('donation', message)
end

api.on_member = function(message)
	Event.raise_event(global.events.api_on_member, { message = message, tick = game.tick });
	api.store_request('member', message)
end

api.on_follow = function(message)
	Event.raise_event(global.events.api_on_follow, { message = message, tick = game.tick });
	api.store_request('follow', message)
end

api.on_host = function(message)
	Event.raise_event(global.events.api_on_host, { message = message, tick = game.tick });
	api.store_request('host', message)
end

api.on_raid = function(message)
	Event.raise_event(global.events.api_on_raid, { message = message, tick = game.tick });
	api.store_request('raid', message)
end

api.store_request = function(type, message)
	if global.config.store_requests[type] then
		local entry = {};
		if (type == 'donation') then
			entry.amount = message.amount
			entry.message = message.message

			if (message.type ~= 'bits') then
				entry.formatted_amount = message.formatted_amount
				entry.currency = message.currency
			end
		elseif (type == 'member') then
			-- general
			entry.months = message.months

			-- Twitch stuff
			entry.sub_plan = '1000';
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
		elseif (type == 'raid') then
			entry.amount = message.raiders
		elseif (type == 'host') then
			entry.amount = message.viewers
		elseif (type == 'follow') then
			-- continue
		else
			return ;
		end

		entry.type = message.type
		entry.name = message.display_name or message.name
		entry.tick = game.tick

		table.insert(global.data.requests[type], entry);
	end
end

api.remove_stored_requests_since_tick = function(tick)
	local requests = global.data.requests;
	for _, type in pairs(requests) do
		for i, entry in pairs(type) do
			if entry.tick and entry.tick < tick then
				table.remove(type, i)
			end
		end
	end
end

return api