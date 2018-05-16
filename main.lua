
local Player = require('Player')
local paint = require('paint')
local events = require('events')
local decipher = require('decipher')
local helper = require('helper')

tileSize = 28
clock = 0

map = nil
numberOfLevels = 3
bigFood = {}
numberOfFood = 0

gameState = nil

message = ''
messageTimer = -1
pauseTimer = -1
endGame = false

man = nil 
red = nil

avatars = {} 
ghostMovement = 'patrol'

remainingLives = 0
beginLife = 0
score = 0
readyMessage = 0
beginningLives = 3
foodToWin = 0


eaten = love.audio.newSource("pacman_chomp.wav")
startMusic = love.audio.newSource("TheFeeling.mp3")

function eatBigFood()
  addScore(40)
end

function dotter(x, y, isBigFood)
  local size = 2
  isBigFood = isBigFood or bigFood[helper.str({x, y})]
  if isBigFood then 
    size = 8 
  end
  local blink = 0.4

  if isBigFood and math.floor(clock / blink) % 2 == 1 and
     pauseTimer <= clock then
    return
  end
  paint.setColor(255, 220, 128)
  love.graphics.circle('fill', x * tileSize, y * tileSize, size, 10)
end

function drawDot()
  for k, v in pairs(dots) do 
    dotter(v[1], v[2]) 
  end
end

function waller(x, y)
  love.graphics.setLineWidth(3)

  function m(pt)
    if math.min(pt[1], pt[2]) < 1 then 
      return 0 
    end
    if pt[1] > #map or pt[2] > #(map[1]) then 
      return 0 
    end
    return map[pt[1]][pt[2]]
  end

  function line(x1, y1, x2, y2)
    love.graphics.line(math.floor(x1 + 0.5) + 0.5, math.floor(y1 + 0.5) + 0.5, math.floor(x2 + 0.5) + 0.5, math.floor(y2 + 0.5) + 0.5)
  end

  local w = 0.7
  local ww = 1.0 - w
  local map_pt = {x, y}

  local wc = level.wall_color
  paint.setColor(wc.r, wc.g, wc.b, 255, {is_wall = true})
  for coord = 1, 2 do 
    for delta = -1, 1, 2 do
      local other_pt = {map_pt[1], map_pt[2]}
      other_pt[coord] = other_pt[coord] + delta
      local other = m(other_pt)
      if other ~= 1 then
        local c = {(w * map_pt[1] + ww * other_pt[1] + 0.5) * tileSize, (w * map_pt[2] + ww * other_pt[2] + 0.5) * tileSize}
        local d = {{0, 0}, {0, 0}}
        for dd = -1, 1, 2 do
          local i = (dd + 3) / 2 
          local side = {map_pt[1], map_pt[2]}
          local normal = 3 - coord
          side[normal] = side[normal] + dd
          d[i][normal] = dd * ww * tileSize
          if m(side) == 1 then 
            d[i][normal] = dd * w * tileSize 
          end
        end
      line(c[1] + d[1][1], c[2] + d[1][2], c[1] + d[2][1], c[2] + d[2][2])
      end
    end 
  end 
end

function pointCollision(x, y)
  local h = 0.45 
  local pts = {}
  for dx = -1, 1, 2 do 
    for dy = -1, 1, 2 do
      table.insert(pts, {math.floor(x + dx * h), math.floor(y + dy * h)})
    end 
  end
  return pts
end

function foodCollision(x, y)
  local pts = pointCollision(2 * x + 0.5, 2 * y + 0.5)
  local dots = {}
  for k, v in pairs(pts) do
    local pt = {v[1] / 2, v[2] / 2}
    dots[helper.str(pt)] = pt
  end
  return dots
end

function wallCollision(x, y)
  local pts = pointCollision(x, y)
  for k, v in pairs(pts) do
    if v[1] >= 1 and v[1] <= #map then
      local m = map[v[1]][v[2]]
      if m == 1 then 
        return true 
      end
    end
  end
  return false
end

function displayLives()
  local char = Player.new('hero', 'yellow')
  char.y = 13.5
  char.always_draw = true
  char.is_fake = true
  for i = 1, remainingLives - 1 do
    char.x = 22.25 + 1.2 * i
    char:draw()
  end
end

function levelCompleted()
  if levelNumber == numberOfLevels then
    message = 'Wow you actually did it! The champion has been decided!'
    messageTimer = math.huge
  else
    message = 'Level Complete! Even a blind squirrel finds a nut sometimes...'
    messageTimer = math.huge
  end
  if levelNumber == numberOfLevels then
    gameOver()
  else
    events.add(3, goNextLevel)
  end
  avatars = {}
end

function ghostCollision()
  font = love.graphics.newFont('Prototype.ttf', 18)
  love.graphics.setFont(font)
  for k, character in pairs(avatars) do
    if character ~= man and man:distance(character) < 0.5 then
      sound = love.audio.newSource("pacman_death.wav")
      sound:play()
      remainingLives = remainingLives - 1

      message = "You're supposed to avoid those guys..."
      messageTimer = math.huge
      pauseTimer = math.huge

      avatars = {man}

      beginLife = pauseTimer
        
      if remainingLives == 0 then
        message = 'Game over, back to the beginning with you!'
        gameOver()
      else
        events.add(2, beginGame)
      end
    end
  end
end

function gameOver()
  endGame = true
  love.audio.setVolume(.25)
  startMusic:play()
  function mainMenu()
    pauseTimer = 0
    setScreen('start screen')
  end
  events.add(3, mainMenu)
end

function showPrompt()
  if messageTimer < clock then 
    return 
  end
  paint.setColor(255, 255, 255)
  local t = 14
  love.graphics.printf(message, t, 23.25 * tileSize, 21 * tileSize - t, 'center')
end

function showScore()
  font = love.graphics.newFont('Prototype.ttf', 28)
  love.graphics.setFont(font)
  local wc = level.wall_color
  paint.setColor(wc.r, wc.g, wc.b)
  love.graphics.printf(score, 0, 11.5 * tileSize, 25 * tileSize, 'right')
end

function addScore(points)
  love.audio.setVolume(.5)
  if eaten:isPlaying() == false then
    eaten:play()
  end
  score = score + points
end

function turnInput(dir)
  if dir == nil then 
    return 
  end
  if man == nil then 
    return 
  end
  if man:turnCheck(dir) then
    man.dir = dir
  else
    man.next_dir = dir
  end
end

function sign(x)
  if x == 0 then 
    return 0 
    end
  if x < 0 then 
    return -1 
  end
  return 1
end

function goNextLevel()
  levelNumber = levelNumber + 1
  loadLevel()
end

function loadLevel()
  local filename = 'level' .. levelNumber .. '.txt'
  level = decipher.read(filename)
  map = level.map

  numberOfFood = 0

  bigFood = helper.hash_from_list(level.superdots)

  dots = {}

  function addDots(x, y)
    if map[x][y] ~= 0 then 
      return 
    end
    addSingleDot(x + 0.5, y + 0.5)
    if x + 1 <= #map and map[x + 1][y] == 0 then
      addSingleDot(x + 1, y + 0.5)
    end
    if y + 1 <= #(map[1]) and map[x][y + 1] == 0 then
      addSingleDot(x + 0.5, y + 1)
    end
  end
  function addSingleDot(x, y)
    dots[helper.str({x, y})] = {x, y}
    numberOfFood = numberOfFood + 1
  end

  for x = 1, #map do 
    for y = 1, #(map[1]) do 
      addDots(x, y) 
    end 
  end

  avatars = {}
  local freeze = 4
  events.add(1, freezeCharacters)
  events.add(freeze, beginGame)
  pauseTimer = math.huge
  readyMessage = clock + freeze

end

function newGame()
  remainingLives = beginningLives
  endGame = false
  score = 0
  levelNumber = 1
  loadLevel()
  sound = love.audio.newSource("pacman_beginning.wav")
  sound:play()
end

function createCharacters()
  avatars = {}
  man = Player.new('hero', 'yellow')
  table.insert(avatars, man)

  red = Player.new('ghost', 'red')
  table.insert(avatars, red)

  table.insert(avatars, Player.new('ghost', 'pink'))
  table.insert(avatars, Player.new('ghost', 'blue'))
  table.insert(avatars, Player.new('ghost', 'orange'))
  if(levelNumber == 2) then
    table.insert(avatars, Player.new('ghost', 'purple'))
  end
  if(levelNumber == 3) then
    table.insert(avatars, Player.new('ghost', 'purple'))
    table.insert(avatars, Player.new('ghost', 'black'))
    table.insert(avatars, Player.new('ghost', 'green'))
    table.insert(avatars, Player.new('ghost', 'silver'))
  end
end

function freezeCharacters()
  createCharacters()
  for k, c in pairs(avatars) do
    c.dir = {0, 0}
    c.always_draw = true
  end
end

function beginGame()
  createCharacters()
  pauseTimer = 0
  messageTimer = 0
end

function displayCountdown()
  if readyMessage <= clock then 
    return 
  end

  local x, y, w, h = 206, 361, 176, 75
  paint.setColor(0, 0, 0, 255)
  love.graphics.rectangle('fill', x, y, w, h, 10, 30)
  local wc = level.wall_color
  paint.setColor(wc.r, wc.g, wc.b)
  love.graphics.rectangle('line', x, y, w, h, 10, 30)

  font = love.graphics.newFont(17)
  love.graphics.setFont(font)
  paint.setColor(190, 190, 190)
  love.graphics.printf('This is level ' .. levelNumber, x + 6, y + 2, w, 'center')
  paint.setColor(190, 190, 190)
  love.graphics.printf('Get ready!', x + 6, y + 35, w, 'center')
end

function mainMenuCharacters()
  avatars = {}
  local y = 25
  local colors = {'yellow', 'blue', 'orange', 'pink', 'red'}
  local tw = math.floor(love.graphics.getWidth() / tileSize)
  for k, color in pairs(colors) do
    local shape = 'ghost'
    local j = k
    if j == 1 or j == 3 then
      j = 4 - j 
    end
    local x = j * 2 + tw / 2 - 6
    if color == 'yellow' then 
      shape = 'hero' 
    end
    local c = Player.new(shape, color)
    c.x = x
    c.y = y
    table.insert(avatars, c)
  end
end

function setScreen(new_mode)
  gameState = new_mode
  if gameState == 'start screen' then
    mainMenuCharacters()
    love.draw = createMainMenu
    love.update = mainMenuUpdate
    love.keypressed = buttonPressMainMenu
  elseif gameState == 'playing' then
    love.draw = displayPlayingScreen
    love.update = updatePlayScreen
    love.keypressed = buttonPressPlaying
  end
end

function createMainMenu()

  paint.setColor(255, 255, 255)
  font = love.graphics.newFont('storm ExtraBold.ttf', 80)
  love.graphics.setFont(font)
  message = "Welcome to Pao-er Pac!"
  love.graphics.printf(message, 0, 10* tileSize, 45 * tileSize, 'center')
  font = love.graphics.newFont('storm ExtraBold.ttf', 50)
  love.graphics.setFont(font)
  message = "Press any key to begin the game!"
  love.graphics.printf(message, 0, 15* tileSize, 45 * tileSize, 'center')
  for k, c in pairs(avatars) do 
    c:draw() 
  end

end

function mainMenuUpdate(dt)
  clock = clock + dt
  events.update(dt)
end

function buttonPressMainMenu(key)
  newGame()
  setScreen('playing')
  startMusic:stop()
end

function displayPlayingScreen()
  love.graphics.translate(345, 15)

  for x = 1, #map do for y = 1, #(map[1]) do
    if map[x][y] == 1 or map[x][y] == 3 then
      waller(x, y)
    end
  end end  

  for k, v in pairs(dots) do 
    dotter(v[1], v[2]) 
  end

  for k, character in pairs(avatars) do
    character:draw()
  end

  displayLives()
  showPrompt()
  displayCountdown()
  showScore()
end

function updatePlayScreen(dt)

  local max_dt = 0.06 
  dt = math.min(dt, max_dt)
  clock = clock + dt

  for k, character in pairs(avatars) do
    character:update(dt)
  end
  ghostCollision()
  events.update(dt)
end

function buttonPressPlaying(key)
  local dirs = {up = {0, -1}, down = {0, 1}, left = {-1, 0}, right = {1, 0}}
  turnInput(dirs[key])
end

function love.load()
  level = decipher.read('level1.txt')
  love.window.setMode(1280, 720)
  love.window.setTitle('Pao-er Pac')
  setScreen('start screen')
  love.audio.setVolume(.25)
  startMusic:play()
end
