io = require("io")

push = require("push")
utf8 = require("utf8")
showe = require("show")

love.graphics.setDefaultFilter("nearest", "nearest") 

local CANVAS_WIDTH = 801
local CANVAS_HEIGHT = 601
local POINT_SIZE = 1

function love.load(arg)
  love.filesystem.setIdentity("SpaceShoot")
  local dataa, eroooo = love.filesystem.load("HighScore.lua")
  --print( "filo:",dataa)
  if eroooo then
    print("no high score save detected, creating new one")
  local file = love.filesystem.newFile("HighScore.lua")
  file:open("w")
  file:write(table.show({{highscore=30, name="ANNNNNNNNNNNNNNNNNNNNNN"},{highscore=30, name="look it's Anastasia the gal who developed this game"} ,{highscore=30, name="AnastasiaAnastasiaAnastasiaAnastasiaAnastasiaAnastasia"}}, "highscore"))
  
  file:close()
  dataa = love.filesystem.load("HighScore.lua")
end
  dataa()
  lvl=1
  shipIM = love.graphics.newImage( "sprites/ship.png")
  asteroidIM = love.graphics.newImage( "sprites/asteroid.png")
  planetIM = love.graphics.newImage("sprites/planet.png")
  
  math.randomseed(love.timer.getTime())
  scorename = ""
  
  
  setup()
  love.graphics.setFont (love.graphics.newFont (50))
  font = love.graphics.getFont ()
  text = love.graphics.newText(love.graphics.newFont(20))
  text2 = love.graphics.newText(love.graphics.newFont(50))
  txt = {"FALL","SHEAR","ANGLE", "TOTAL"}
  BTN={ [true]=1, [false]=0 }
  
  statusvec = {false, false, false, false} 
  asteroids={}
  push:setupScreen(800, 600,801, 601, {fullscreen=false, resizable=true, vsync=true, pixelperfect = false} )
end

function love.resize(w,h)
push:resize(w,h)
end


function love.textinput(t)
  if pause=="fail" then 
    scorename = scorename .. t
    end
  if pause=="pause" and (t=="d" or t=="a") then
    lvl = lvl-1
    if t=="d" then
    lvl = (lvl+1)%3--math.fmod( lvl+1,4 )
    else
    lvl = (lvl-1)%3--math.fmod( lvl-1,4 )
    
  end
  lvl=lvl+1
    setup(lvl)
    end
  
  end

function love.keypressed(key, scancode, isrepeat)
  
  if pause == "fail" then
     if key == "backspace" then
        -- get the byte offset to the last UTF-8 character in the string.
        local byteoffset = utf8.offset(scorename, -1)

        if byteoffset then
            -- remove the last UTF-8 character.
            -- string.sub operates on bytes rather than UTF-8 characters, so we couldn't do string.sub(text, 1, -2).
            scorename = string.sub(scorename, 1, byteoffset - 1)
        end
    end
    
    if key == "return" then
      if math.floor(score) > highscore[lvl].highscore then
      highscore[lvl].highscore = math.floor(score)
      highscore[lvl].name = scorename
      
      file = love.filesystem.newFile("HighScore.lua")
      file:open("w")
      
      file:write(table.show(highscore, "highscore"))
      file:close()
      end
    setup(lvl)
  end
  
    end
  
  
  end

function love.update(dt)
  if (pause == "pause" ) and love.keyboard.isDown("w") then
    pause="run"
  end
  if pause == "run" then
    if math.fmod(score,1)<0.5 and math.fmod(score+dt,1)>0.5 then
       asteroids=spawn_astr(Planet[1+math.floor(#Planet-1)], asteroids)
      end
    
    score = score+dt
    if love.keyboard.isDown("w") then
      Player.dx =Player.dx+ dt*30* math.cos(Player.angle)
      Player.dy =Player.dy+ dt*30* math.sin(Player.angle)
      Player.landed = "floating"
    end
    
    for I,V in ipairs(asteroids) do
      
      for G,T in ipairs(Planet) do
      asteroids[I] = gravity(asteroids[I], T, dt)
      end
    end
    for I,V in ipairs(asteroids) do
      asteroids[I].x = V.x + dt*V.dx
      asteroids[I].y = V.y + dt*V.dy
      asteroids[I].angle = V.angle +dt*V.dangle
    end

    for G,T in ipairs(Planet) do 
    dellist = {}
      
      for I,V in ipairs(asteroids) do
      local DIS = dist(V, T)
      if DIS.dist < T.radius or DIS.dist >100000 then
        table.insert(dellist, I)
      end
      local DIS = dist(V, Player)
      if DIS.dist < V.radius then
        fail()
        end
      end
    for I=#dellist,1,-1 do
      table.remove(asteroids, dellist[I])
    end
  end
  
  
    if Player.landed == "floating" then
    if love.keyboard.isDown("s") then
      Player.dx =Player.dx- dt*10* math.cos(Player.angle)
      Player.dy =Player.dy- dt*10* math.sin(Player.angle)
    end
    if love.keyboard.isDown("d") then
      Player.dangle =Player.dangle+dt*2
    end 
    if love.keyboard.isDown("a") then
      Player.dangle =Player.dangle-dt*2
    end 
    
    
    for I,V in ipairs(Planet) do
    Player = gravity(Player, V, dt)
    end
    
    Player.angle = math.fmod(Player.angle+Player.dangle*dt, 2*math.pi )
    Player.x = Player.x+dt*Player.dx
    Player.y = Player.y+dt*Player.dy
    
    local lowdist = 99999999999
    for I,V in ipairs(Planet) do
    local DIS = dist(Player, V)
    
    if DIS.dist < lowdist then
    lowdist = DIS.dist
    local dax= (DIS.x/DIS.dist)
    local day = (DIS.y/DIS.dist)
    local velt = (dax*Player.dx+day*Player.dy)
    local velt2 =  dax*Player.dy-day*Player.dx
    statusvec = {velt<-40, math.abs(velt2)>25,math.fmod( math.abs(math.atan2(DIS.y, DIS.x)-Player.angle), 2*math.pi )>1} 
    statusvec[4]= statusvec[1] or statusvec[2] or statusvec[3]
  end
  end
    if not( Player.landed == "landed") then
    for I,V in ipairs(Planet) do
    local DIS = dist(Player, V)
    if (DIS.dist < Player.radius + V.radius-1) then
        
        Player.landed="landed"
        
        if statusvec[4] then
          print("failure")
          fail()
          end
    local dax= (DIS.x/DIS.dist)
    local day = (DIS.y/DIS.dist)
        
        --print(velt, velt2)
        --print(dax, day, Player.dx, Player.dy)
        --print(math.abs(math.atan2(DIS.y, DIS.x)-Player.angle),math.atan2(DIS.y, DIS.x), Player.angle )
        Player.x = V.x + dax*(Player.radius + V.radius)
        Player.y = V.y + day*(Player.radius + V.radius)
        
        Player.dx=0
        Player.dy=0
        Player.dangle=0
        Player.angle = math.atan2(DIS.y, DIS.x)
    end
    end
    end
    if oxy <0 then
      fail()
    end
    
    oxy=oxy-dt
    
    
    end
    
    if Player.landed == "landed" then
      oxy=math.min( oxy+10*dt, 30)
      end
    end
end

function love.draw()
push:start()
love.graphics.setColor(1,1,1)  
love.graphics.draw(shipIM,  Player.x, Player.y, Player.angle+0.5*math.pi, 2*Player.radius/shipIM:getWidth(), 2*Player.radius/shipIM:getHeight(), shipIM:getWidth()/2, shipIM:getHeight()/2)
  
love.graphics.setColor(1,1,1)

local HOLO=planetIM:getHeight()
local WOLO=planetIM:getWidth()
for I,V in ipairs(Planet) do


--love.graphics.circle("fill", V.x, V.y,V.radius)
  love.graphics.draw(planetIM, V.x, V.y, 0, 2.02*V.radius/WOLO, 2.02*V.radius/HOLO, WOLO/2, HOLO/2)
end
love.graphics.setColor(1,1,1)
 HOLO=asteroidIM:getHeight()
WOLO=asteroidIM:getWidth()

for I, V in ipairs(asteroids) do
  love.graphics.draw(asteroidIM, V.x, V.y, V.angle, 2*V.radius/WOLO, 2*V.radius/HOLO, WOLO/2, HOLO/2)
  --love.graphics.circle("fill", V.x, V.y,V.radius)
  
  end


love.graphics.setColor(1,1,0)

--love.graphics.circle("fill", Player.x, Player.y,Player.radius)
love.graphics.setColor(0,1,1)
--love.graphics.line( Player.x, Player.y,Player.x+math.cos(Player.angle)*20, Player.y+math.sin(Player.angle)*20)
love.graphics.setColor(1,1,1)
text:clear()
for i=1,4 do
  text:add({{BTN[statusvec[i]] , BTN[not statusvec[i]], 0}, txt[i]} , 10, 13*i-5)
  end
text:add({{1 , 1, 1}, string.format("Score: %.0f", math.floor(score))} , 10, 13*5-5)

love.graphics.draw(text)

love.graphics.setColor(0,0,1)  
love.graphics.rectangle("fill",40,500, 400*(oxy/30), 10)
if not (pause == "run") then
love.graphics.setColor(1,1,1)  
text2:clear()
text2:add({{1,1,1}, pause}, 100, 100)
if pause == "fail" then
text2:add({{1,1,1}, "Score: ".. math.floor(score)}, 50, 150)
text2:add({{1,1,1}, "Player name: ".. scorename}, 50, 200)
text2:add({{1,1,1}, "Top Score: ".. highscore[lvl].highscore}, 50, 250)
text2:add({{1,1,1}, "by: ".. highscore[lvl].name}, 50, 300)
  end
love.graphics.draw(text2)
end
push:finish()
end

function gravity(body, planet, dt)
  local DIS = dist(planet, body)
  local force = planet.gravity / ((DIS.dist^2))
  body.dx = body.dx +dt*force*DIS.x/DIS.dist
  body.dy = body.dy +dt*force*DIS.y/DIS.dist
  return body
end


function dist(bodyA, bodyB)
  local xdif = bodyA.x - bodyB.x
  local ydif = bodyA.y - bodyB.y
  local dist = math.sqrt((xdif^2)+(ydif^2))
  
  return {x = xdif, y = ydif, dist = dist}
  end

function setup(ID)
  ID = ID or 1
  if ID == 1 then
  Player={x = 200, y = 200, dx=10, dy=10, angle=-2.677945044589, dangle=0, radius=5, landed="floating"}
  Planet={{x=400, y=300, radius=100, gravity=190000}}
elseif ID==2 then
  
  Player={x = 200, y = 200, dx=0, dy=0, angle=-2.677945044589, dangle=0, radius=5, landed="floating"}
  Planet={{x=300, y=300, radius=50, gravity=50000}, {x=450, y=300, radius=50, gravity=50000}}
elseif ID==3 then
  Player={x = 200, y = 200, dx=0, dy=0, angle=-2.677945044589, dangle=0, radius=5, landed="floating"}
  Planet={{x=300, y=400, radius=40, gravity=40000}, {x=450, y=400, radius=30, gravity=25000}, 
    {x=375, y=250, radius=50, gravity=50000}}

  end
  
  oxy = 30
  pause="pause"
  score = 0
  asteroids = {}
end

function spawn_astr(planet , asteroidi)
  local aa = math.random(0, 2*math.pi)
  local bb = aa+math.random(-0.3, 0.3)
  local cc = aa+math.random(5, 30)
  
  local as = {x=planet.x+450*math.sin(aa), y=planet.y+450*math.cos(aa), dx=-math.sin(bb)*cc, dy=-math.cos(bb)*cc, radius=math.random(5,35), angle=math.random(0, 2*math.pi), dangle=math.random(-0.2, 0.2) }
  table.insert(asteroidi, as)
  return asteroidi
end



function fail()
  pause = "fail"
  scorename = ""
  
  end




