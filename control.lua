-- [[
-- Api base mod
-- ]]

local handler = require("event_handler")
handler.add_libraries(
	{
		require("script.api"),
		require("script.statistics"),
		require("script.remote_interface"),
		require("script.graftorio")
	}
)
