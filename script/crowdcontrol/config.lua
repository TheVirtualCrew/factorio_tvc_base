local cfg = {
	handcraft = {
		min = -1,
		max = 1,
		stackable = false,
	},
	botspeed = {
		min = 0,
		max = 10,
		stackable = true
	},
	runspeed = {
		min = -0.9,
		max = 3,
		stackable = true
	},
	teleport = {
		cooldown = 10,
		apply_function = 'random_teleport'
	},
	fakedeath = {
		cooldown = 30,
		apply_function = 'fakedeath'
	}
}

return cfg;
