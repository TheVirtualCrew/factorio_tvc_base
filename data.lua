local function add_sound(name, filename)
	return {
		type = 'sound',
		name = name,
		filename = filename,
		volume = 0.75
	}
end

data:extend({
	add_sound('api_console_message', '__core__/sound/console-message.ogg'),
})

