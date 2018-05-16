
local paint = require('paint')
local helper = require('helper')

local Player = {} ; 
Player.__index = Player

function Player.new(shape, color)
  local c = setmetatable({shape = shape, color = color}, Player)
  c.is_fake = false
  c:restore()
  return c
end

function Player:died()
  return self.dead_till > clock
end

function Player:restore()
  self.dead_till = -1
  self.mode = 'normal' 
  self.eaten = false  
  self.past_turns = {}
  local start_pos = level.start_pos[self.color]
  self.x = start_pos[1]
  self.y = start_pos[2]
  if self.shape == 'hero' then
    self.dir = {-1, 0}
    self.next_dir = nil
  else
    if self.color == 'red' then
      self.dir = {1, 0}
      self.exit_time = math.huge
    elseif self.color == 'pink' then
      self.dir = {0, 0}
      self.exit_time = clock
    elseif self.color == 'blue' then
      self.dir = {0, 0}
      self.exit_time = clock
    elseif self.color == 'orange' then
      self.dir = {0, 0}
      self.exit_time = clock
    elseif self.color == 'purple' then
      self.dir = {0, 0}
      self.exit_time = clock
    elseif self.color == 'green' then
      self.dir = {0, 0}
      self.exit_time = clock
    elseif self.color == 'black' then
      self.dir = {0, 0}
      self.exit_time = clock
    elseif self.color == 'silver' then
      self.dir = {0, 0}
      self.exit_time = clock
    end
  end
end

function Player:velocity()
  local hotel_pos = level.ghost_hotel.outside
  if self.shape == 'hero' then 
    return 6
  else
    if levelNumber == 1 then
      return 5
    elseif levelNumber == 2 then
      return 6
    else
      return 6.5
    end
  end
end

function Player:beacon()
  local hotel = level.ghost_hotel
  if self.shape == 'hero' then return {} end
  if self:died() then 
    return hotel.inside 
  end
  if self.mode == 'freemove' then 
    return hotel.outside 
  end
  if self.color == 'red' then
    if ghostMovement == 'patrol' then 
      return {9, 2} 
    end
  elseif self.color == 'pink' then
    if ghostMovement == 'patrol' then 
      return {18, 9} 
    end
  elseif self.color == 'blue' then
    if ghostMovement == 'patrol' then 
      return {2, 9} 
    end
  elseif self.color == 'orange' then
    if ghostMovement == 'patrol' then 
      return {9, 18} 
    end
  elseif self.color == 'purple' then
    if ghostMovement == 'patrol' then
      return {2, 18}
    end
  elseif self.color == 'green' then
    if ghostMovement == 'patrol' then
      return {18, 18}
    end
  elseif self.color == 'black' then
    if ghostMovement == 'patrol' then
      return {2, 2}
    end
  elseif self.color == 'silver' then
    if ghostMovement == 'patrol' then
      return {18, 2}
    end
  end
end

function Player:directionCheck(dir)
  if dir == nil then 
    return false 
  end
  local new_x, new_y = self.x + dir[1], self.y + dir[2]
  local passDoor = (self.mode == 'freemove' or self:died())
  return not wallCollision(new_x, new_y)
end

function Player:turnCheck(dir)
  if not self:directionCheck(dir) then 
    return false 
  end

  if self.x - math.floor(self.x) == 0.5 and self.y - math.floor(self.y) == 0.5 then
    return true
  end

  for i = 1, 2 do
    if dir[i] ~= -self.dir[i] then 
      return false 
    end
  end
  return true
end

function Player:turnRadius(dir)
  local beacon = self:beacon()
  local beacon_dir = {beacon[1] - self.x, beacon[2] - self.y}
  local score = beacon_dir[1] * dir[1] + beacon_dir[2] * dir[2]
  local past = self.past_turns[helper.str({self.x, self.y})]
  if past and helper.str(past.dir) == helper.str(dir) then
    score = score - 5 * past.times
  end
  return score
end

function Player:compatibleDirections()
  local turn = {self.dir[2], self.dir[1]}
  local turns = {}
  if self:directionCheck(self.dir) then 
    turns = {self.dir} 
  end
  for sign = -1, 1, 2 do
    local t = {turn[1] * sign, turn[2] * sign}
    if self:directionCheck(t) then 
      table.insert(turns, t) 
    end
  end
  if #turns == 0 then 
    table.insert(turns, {-self.dir[1], -self.dir[2]}) 
  end
  return turns
end


function Player:determineTurn(turn)
  if self:turnRadius(turn) > self:turnRadius(self.dir) then
    self.dir = turn
    self.last_turn = {self.x, self.y}
  end
end

function Player:nextGP()
  local pt = {self.x, self.y}

  for i = 1, 2 do
    if self.dir[i] == 1 then
      pt[i] = math.floor(pt[i] + 0.5) + 0.5
    elseif self.dir[i] == -1 then
      pt[i] = math.ceil(pt[i] - 0.5) - 0.5
    end
  end
  return pt
end

function Player:update(dt)
  if pauseTimer > clock then 
    return 
  end

  if self.shape == 'ghost' and self.exit_time < clock then
    self.mode = 'freemove'
    self.exit_time = math.huge
    self.dir = {0, -1}
  end

  local movement = dt * self:velocity()
  while movement > 0 do
    if self.dir[1] == 0 and self.dir[2] == 0 then 
      break 
    end

    local pt = self:nextGP()
    local distance = self:distanceToPoint(pt)
    if distance <= movement then
      self.x, self.y = pt[1], pt[2]
      self:reachedGP()
    else
      self.x = self.x + self.dir[1] * movement
      self.y = self.y + self.dir[2] * movement
    end
    movement = movement - distance 
  end

  self:teleporter()
  self:computeDotEaten()
end

function Player:reachedGP()
  if self.x < 1 or self.x > (#map + 1) then 
    return 
  end

  if self.shape == 'hero' then
    if self:directionCheck(self.next_dir) then
      self.dir = self.next_dir
      self.next_dir = nil
    elseif not self:directionCheck(self.dir) then
      self.dir = {0, 0}
    end
  end

  if self.shape == 'ghost' then
    local can_pass_hotel_door = (self.mode == 'freemove' or self:died())
    local t = self:beacon()
    if can_pass_hotel_door and self.x == t[1] and self.y == t[2] then
        self.mode = 'normal'
    end

    local dirs = self:compatibleDirections()
    self.dir = dirs[1]
    for k, t in pairs(dirs) do 
      self:determineTurn(t) 
    end
    self:computeTurn()
  end
end

function Player:computeTurn()
  local key = helper.str({self.x, self.y})
  local value = self.past_turns[key]
  if value and helper.str(value.dir) == helper.str(self.dir) then
    value.times = value.times + 1
  else
    self.past_turns[key] = {dir = self.dir, times = 1}
  end
end

function Player:teleporter()
  if self.x <= 0.5 then
    self.x = #map + 1.5
    self.dir = {-1, 0}
  elseif self.x >= #map + 1.5 then
    self.x = 0.5
    self.dir = {1, 0}
  end
end

function Player:computeDotEaten()
  if self.shape ~= 'hero' then 
    return 
  end
  local dots_hit = foodCollision(self.x, self.y)
  for k, v in pairs(dots_hit) do
    if dots[k] then
      if bigFood[k] then 
        eatBigFood() 
      end
      dots[k] = nil
      numberOfFood = numberOfFood - 1
      addScore(10)
      if numberOfFood <= foodToWin then
        pauseTimer = math.huge
        levelCompleted()
      end
    end
  end
end

function Player:draw()
  local draw_opts = {is_live = not self.is_fake}
  if not self.always_draw then
    if pauseTimer > clock then 
      return 
    end
  end
  local colors = {red = {255, 0, 0}, pink = {255, 128, 128}, blue = {0, 224, 255}, orange = {255, 128, 0}, yellow = {255, 255, 0}, purple = {147, 112, 219},
                  black = {0, 0, 0,}, green = {46, 139, 87}, silver = {255, 255, 255}}
  local color = colors[self.color]
  paint.setColor(color[1], color[2], color[3], 255, draw_opts)
  if self.shape == 'hero' then
    local p = 0.15 
    local max = 1.0 
    local r = 0.45 
    if self.always_draw then
      local mouth_angle = max
      local start = math.atan2(0, -1)
      love.graphics.arc('fill', self.x * tileSize, self.y * tileSize, tileSize * r, start + mouth_angle / 2, start + 2 * math.pi - mouth_angle / 2, 16)
    else
      local mouth_angle = max * (math.sin((clock % p) / p * 2 * math.pi) + 1.0)
      local start = math.atan2(self.dir[2], self.dir[1])
      love.graphics.arc('fill', self.x * tileSize, self.y * tileSize, tileSize * r, start + mouth_angle / 2, start + 2 * math.pi - mouth_angle / 2, 16)
    end
  else 
    local is_inverted_weak = false
    if not self:died() then
      local r = 0.45
      love.graphics.circle('fill', self.x * tileSize, self.y * tileSize, tileSize * r, 14)

      local vertices = {self.x * tileSize, self.y * tileSize, (self.x - r) * tileSize, self.y * tileSize}
      local n = 3
      local left = (self.x - r) * tileSize
      local bottom = (self.y + 0.45) * tileSize
      for i = 0, n - 1 do
        local dy = 2 * (1 - (i % 2) * 2)
        table.insert(vertices, left + (i / (n - 1)) * tileSize * (2 * r))
        table.insert(vertices, bottom + dy)
      end
      table.insert(vertices, (self.x + r) * tileSize)
      table.insert(vertices, self.y * tileSize)
      love.graphics.polygon('fill', vertices)
    end
    paint.setColor(255, 255, 255, 255, draw_opts)
    if is_inverted_weak then paint.setColor(0, 0, 255, 255, draw_opts) end
    for i = -1, 1, 2 do
      local dx = i * 5
      local radius = 4
      love.graphics.circle('fill', self.x * tileSize + dx, (self.y - 0.1) * tileSize, radius, 10)
    end
    paint.setColor(0, 0, 192, 255, draw_opts)
    for i = -1, 1, 2 do
      local dx = i * 5
      love.graphics.circle('fill', self.x * tileSize + dx + 1.5 * self.dir[1], (self.y - 0.1) * tileSize + self.dir[2], 2.5, 10)
    end
  end
end

function Player:distanceToPoint(pt)
  local distance_v = {self.x - pt[1], self.y - pt[2]}
  return math.abs(distance_v[1]) + math.abs(distance_v[2])
end

function Player:distance(other)
  if other:died() then 
    return math.huge 
  end
  return self:distanceToPoint({other.x, other.y})
end

return Player
