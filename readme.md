# TVC Base Api Mod

This is the base mod that allows integration with the tvc api
This will enable mods to react to events like follows or donations

# Events

The base mod will send out events on which mods can react

These events are registered during the on_init event

Example init for events

```
local api_events = false;
script.on_init(function() {
	if api_events == false and remote.interfaces.tvc_api then
		api_events = remote.call('tvc_api', 'get_events')
	end
	
	script.on_event(api_events.api_on_donation, function(event) {
	    ...
	});
});
```


## Available events

The following events are triggered on which you can react

- api_on_donation
- api_on_member
- api_on_follow
- api_on_raid
- api_on_host
- api_on_merch

The events contain the following information:

```
event = {
    message = {}
    tick = game.tick
}
```
Depending on the type the message can differ.

@TODO: add all the different message info

# Deathcounter

The deathcounter counts the player deaths and can be used.
To get the deathcounts you can use
```
remote.call('tvc_api', 'get_deathcount_list')
```

To add custom death count causes you can add a remote interface for your mod to catch that  
If you dont return anything, this will not add it as a possible cause. Otherwise return a string

```
remote.add_interface('my_mod_name', {
	tvc_api_on_death = function(event)
		local player = game.players[event.player_index]
		local surface = player.surface

		if event.cause_name == 'other' then
		    if valid_source_for_death then
		        return 'reason'
		    end
		end
	end
})
```

