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
	damage_mod = {
		min = -100,
		max = 100,
		stackable = false,
		apply_function = 'empty'
	},
	fakedeath = {
		cooldown = 30,
		apply_function = 'fakedeath'
	}
}
