

function love.boot()
  -- Init package.path and add filesystem-compatible package loader
  package.path = "?.lua;?/init.lua"
  table.insert(package.loaders, 1, function(modname)
    modname = modname:gsub("%.", "/")
    for x in package.path:gmatch("[^;]+") do
      local file = x:gsub("?", modname)
      if love.filesystem.exists(file) then
        return assert(loadstring(love.filesystem.read(file), "=" .. file))
      end
    end
  end)

  -- Try to mount .exe file, then the first argument
  for i, v in ipairs { love.argv[1], love.argv[2] } do
    local mounted = love.filesystem.mount(v)
    if mounted then
      break
    end
  end

  -- Set write directory and mount
  love.filesystem.setWriteDir("save")
  love.filesystem.mount("save")

  -- Load main.lua or init `nogame` state
  if love.filesystem.isFile("main.lua") then
    require("main")
  else
    love.nogame()
  end

  love.run()
end


function love.run()
  -- Prepare arguments
  local args = {}
  for i = 2, #love.argv do
    args[i - 1] = love.argv[i]
  end

  -- Do load callback
  if love.load then love.load(args) end
  love.timer.step()

  while true do
    -- Handle mouse events
    for _, e in ipairs(love.mouse.poll()) do
      if e.type == "motion" then
        if love.mousemoved then love.mousemoved(e.x, e.y, e.dx, e.dy) end
      elseif e.type == "pressed" then
        if love.mousepressed then love.mousepressed(e.x, e.y, e.button) end
      elseif e.type == "released" then
        if love.mousereleased then love.mousereleased(e.x, e.y, e.button) end
      end
    end
    -- Handle keyboard events
    for _, e in ipairs(love.keyboard.poll()) do
      if e.type == "down" then
        if love.keypressed then love.keypressed(e.key, e.code, e.isrepeat) end
      elseif e.type == "up" then
        if love.keyreleased then love.keyreleased(e.key, e.code) end
      elseif e.type == "text" then
        if love.textinput then love.textinput(e.text) end
      end
    end
    -- Update
    love.timer.step()
    local dt = love.timer.getDelta()
    if love.update then love.update(dt) end
    -- Draw
    love.graphics.clear()
    if love.draw then love.draw() end
    love.graphics.present()
  end
end


function love.errhand(msg)
  -- Init error text
  local err = { "Error\n", msg }
  local trace = debug.traceback("", 2)
  for line in string.gmatch(trace, "([^\t]-)\n") do
    table.insert(err, line)
  end
  local str = table.concat(err, "\n")

  -- Init error state
  love.graphics.reset()
  pcall(love.graphics.setBackgroundColor, 89, 157, 220)

  -- Do error main loop
  while true do
    for _, e in ipairs(love.keyboard.poll()) do
      if e.type == "down" and e.code == 1 then
        os.exit()
      end
    end
    love.graphics.clear()
    love.graphics.print(str, 6, 6)
    love.graphics.present()
  end
end


xpcall(love.boot, love.errhand)
