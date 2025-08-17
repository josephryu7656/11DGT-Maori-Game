local cameraX = 0
local mapImage
local mapData
local scale = 3 -- global scale factor
local mapY
local mapWidth
local mapHeight

function love.load()
    anim8 = require 'libraries/anim8'
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- Load map
    mapImage = love.graphics.newImage("map.png")
    mapData  = love.image.newImageData("map.png")
    mapWidth  = mapImage:getWidth()  * scale
    mapHeight = mapImage:getHeight() * scale
    local mapOffsetY = 53
    mapY = love.graphics.getHeight() - mapHeight + mapOffsetY

    -- Load player
    local playerSpriteSheet = love.graphics.newImage('sprites/player-sheet.png')
    player = {
        x = 100, y = 300,
        w = 40, h = 40,
        spriteSheet = playerSpriteSheet,
        yVelocity = 0, jumpForce = -600, gravity = 1400, speed = 250,
        facing_right = true, onGround = false
    }

    player.grid = anim8.newGrid(32, 32, player.spriteSheet:getWidth(), player.spriteSheet:getHeight())
    player.animations = {
        idle = anim8.newAnimation(player.grid('1-4', 1), 0.3),
        walk = anim8.newAnimation(player.grid('1-4', 2), 0.2),
        jump = anim8.newAnimation(player.grid('1-5', 5), 0.25)
    }
    player.anim = player.animations.idle
end

-- find floor based on transparent pixels
function getFloorYAt(worldX)
    local imgX = math.floor(worldX / scale)
    if imgX < 0 or imgX >= mapData:getWidth() then
        return love.graphics.getHeight() -- outside map
    end

    -- scan top -> bottom, look for first solid with air above
    for imgY = 0, mapData:getHeight() - 1 do
        local r, g, b, a = mapData:getPixel(imgX, imgY)
        if a > 0 then
            -- check if pixel above is transparent (surface)
            if imgY == 0 then
                return mapY + imgY * scale
            end
            local _, _, _, aAbove = mapData:getPixel(imgX, imgY - 1)
            if aAbove == 0 then
                return mapY + imgY * scale
            end
        end
    end

    return love.graphics.getHeight() -- no ground here
end

local function isSolidPixel(worldX, worldY)
    local imgX = math.floor(worldX / scale)
    local imgY = math.floor((worldY - mapY) / scale)

    if imgX < 0 or imgX >= mapData:getWidth() or imgY < 0 or imgY >= mapData:getHeight() then
        return false
    end

    local _, _, _, a = mapData:getPixel(imgX, imgY)
    return a > 0
end

function handleHorizontalMovement(dt)
    local is_moving = false
    local moveX = 0

    if love.keyboard.isDown("a") then
        moveX = -player.speed * dt
        player.facing_right = false
        is_moving = true
    elseif love.keyboard.isDown("d") then
        moveX = player.speed * dt
        player.facing_right = true
        is_moving = true
    end

    if moveX ~= 0 then
        -- Check at player's feet and head for wall collision
        local nextLeft   = player.x + moveX
        local nextRight  = player.x + player.w + moveX
        local headY      = player.y + 5
        local feetY      = player.y + player.h - 5

        local hitWall = false
        if moveX > 0 then
            -- moving right
            if isSolidPixel(nextRight, headY) or isSolidPixel(nextRight, feetY) then
                hitWall = true
            end
        else
            -- moving left
            if isSolidPixel(nextLeft, headY) or isSolidPixel(nextLeft, feetY) then
                hitWall = true
            end
        end

        if not hitWall then
            player.x = player.x + moveX
        end
    end

    return is_moving
end


function love.update(dt)
    handleHorizontalMovement(dt)

    if player.onGround then
        if love.keyboard.isDown("a") or love.keyboard.isDown("d") then
            player.anim = player.animations.walk
        else
            player.anim = player.animations.idle
        end
    end

    -- gravity
    player.yVelocity = player.yVelocity + player.gravity * dt
    player.y = player.y + player.yVelocity * dt

    -- floor detection
    local floorY = getFloorYAt(player.x + player.w/2)
    if player.y + player.h >= floorY then
        player.y = floorY - player.h
        player.yVelocity = 0
        player.onGround = true
    else
        player.onGround = false
    end

    -- update animation
    player.anim:update(dt)

    -- camera follow
    local screenMid = love.graphics.getWidth() / 2
    local slack = 100
    if player.x - cameraX < slack then
        cameraX = player.x - slack
    elseif player.x - cameraX > screenMid - slack then
        cameraX = player.x - (screenMid - slack)
    end
    cameraX = math.max(0, math.min(cameraX, mapWidth - love.graphics.getWidth()))
end

function love.keypressed(key)
    if key == "w" and player.onGround then
        player.yVelocity = player.jumpForce
        player.onGround = false
        player.anim = player.animations.jump
    end
end

function love.draw()
    -- draw map
    love.graphics.draw(mapImage, -cameraX, mapY, 0, scale, scale)

    local frameW, frameH = 32, 32
    local sx, ox

    if player.facing_right then
        sx = scale
        ox = 0
    else
        sx = -scale
        ox = frameW  -- shift origin so flip is around sprite center/edge
    end

    local sy = scale
    local oy = frameH  -- keep anchor at feet

    player.anim:draw(
        player.spriteSheet,
        player.x - cameraX, player.y + player.h,
        0, sx, sy, ox, oy
    )
end
