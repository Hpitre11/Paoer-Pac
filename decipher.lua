
local M = {}

function M.read(filename)
  local section = nil
  local level = { map = {}, superdots = {}, start_pos = {}, ghost_hotel = {} }
  for line in love.filesystem.lines(filename) do
    if #line == 0 then
      section = nil
    elseif section == 'layout' then
      for i = 1, #line do
        if level.map[i] == nil then 
          level.map[i] = {} 
        end
        table.insert(level.map[i], tonumber(line:sub(i, i)))
      end
    elseif section == 'bigFood' then
      for x, y in string.gmatch(line, '([%d%.]+),%s*([%d%.]+)') do
        table.insert(level.superdots, {x, y})
      end
    elseif section == 'resting coordinates' then
      for color, x, y in string.gmatch(line, '(%w+).-(%d+).-(%d+)') do
        level.start_pos[color] = {x + 0.5, y + 0.5}
      end
    elseif section == 'ghost area' then
      for pos, x, y in string.gmatch(line, '(%w+).-(%d+).-(%d+)') do
        level.ghost_hotel[pos] = {x + 0.5, y + 0.5}
      end
    elseif section == 'arena hue' then
      local r, g, b = string.match(line, '(%d+)%s+(%d+)%s+(%d+)')
      level.wall_color = {r = r, g = g, b = b}
    elseif section == nil then
      section = line:sub(1, #line - 1)
    end
  end
  return level
end


return M

