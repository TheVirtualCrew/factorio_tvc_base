local data = {
  clear_timer = 60 * 60 * 60 * 24 * 7,
  output_file = "tvc_api.json",
  statistics_file = "tvc_statistics.txt"
}

function data.write_external(command, msg, out_file)
  local output = {command = command, msg = msg}
  if rcon and out_file == nil then
    rcon.print(game.table_to_json(output))
  else
    out_file = out_file or data.output_file
    game.write_file(out_file, game.table_to_json(output), false, 0)
  end

  return msg
end

return data
