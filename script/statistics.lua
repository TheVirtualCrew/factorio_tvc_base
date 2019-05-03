-- Statistics counter for outputing to file

local statistics = {
	store_results = function(self, tick)
		tick = self.floorToNearest(tick, 60);
		local playerForce = game.forces.player;
		local stats = playerForce.item_production_statistics;
		local kills = playerForce.kill_count_statistics;
		local build = playerForce.entity_build_count_statistics;
		return {
			multiple = true,
			rows = {
				{
					tick = tick,
					type = 'item_input_counts',
					items = stats.input_counts
				},
				{
					tick = tick,
					type = 'item_output_counts',
					items = stats.output_counts
				},
				{
					tick = tick,
					type = 'kill_input_counts',
					items = kills.input_counts
				},
				{
					tick = tick,
					type = 'kill_output_counts',
					items = kills.output_counts
				},
				{
					tick = tick,
					type = 'build_input_counts',
					items = build.input_counts
				},
				{
					tick = tick,
					type = 'build_output_counts',
					items = build.output_counts
				}
			}
		}
	end,
	floorToNearest = function(number, multiple)
		return math.floor(number / multiple) * multiple;
	end
}

return statistics;
