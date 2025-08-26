local cameraX = 0 -- camera horizontal position
local mapImage    -- will hold the map image
local mapData     -- will hold map pixel data
local scale = 3   -- global scale factor for graphics
local mapY        -- y-position of map
local mapWidth    -- width of map in pixels after scaling
local mapHeight   -- height of map in pixels after scaling
local lives = 3 -- player starts with 3 lives
local gameState = "menu" -- can be "menu" or "play"
local menuImage   -- will hold the menu screen image
local healthImages = {}
local deathFrames = {}
local currentHealthImage
local showDeathAnim = false
local showHitbox = false -- debug toggle for hitbox display
local deathAnimTimer = 0
local deathAnimIndex = 1
local deathAnimDuration = 0.2 -- seconds per death frame
local healthScale = 3         -- scale factor for crisp enlargement



function love.load()
    anim8 = require 'libraries/anim8' -- animation library
    love.graphics.setDefaultFilter("nearest", "nearest") -- pixel art style, no smoothing

    -- Load menu
    menuImage = love.graphics.newImage("menu.png") -- menu image

    -- Load background
    backgroundImage = love.graphics.newImage("background.png")

    -- Load map
    mapImage = love.graphics.newImage("map.png")      -- load image for drawing
    mapData  = love.image.newImageData("map.png")     -- load image for pixel collision
    mapWidth  = mapImage:getWidth()  * scale         -- scaled width
    mapHeight = mapImage:getHeight() * scale        -- scaled height
    local mapOffsetY = 53
    mapY = love.graphics.getHeight() - mapHeight + mapOffsetY -- position map at bottom

    -- Load player
    local playerSpriteSheet = love.graphics.newImage('sprites/player-sheet.png')
    player = {
        startX = 100, startY = 300, -- player starting position (for reset)
        x = 100, y = 300,    -- player starting position
        w = 40, h = 40,      -- player size
        spriteSheet = playerSpriteSheet,
        yVelocity = 0,       -- vertical speed
        jumpForce = -600,    -- jump strength (negative = up)
        gravity = 1400,      -- gravity pulling down
        speed = 250,         -- horizontal speed
        facing_right = true, -- which way player is facing
        onGround = false     -- is player standing on ground?
    }

    -- create animation grid
    player.grid = anim8.newGrid(32, 32, player.spriteSheet:getWidth(), player.spriteSheet:getHeight())
    player.animations = {
        idle = anim8.newAnimation(player.grid('1-4', 1), 0.3),  -- idle frames
        walk = anim8.newAnimation(player.grid('1-4', 2), 0.2),  -- walking frames
        jump = anim8.newAnimation(player.grid('1-5', 5), 0.25)  -- jumping frames
    }
    player.anim = player.animations.idle -- start with idle animation


    
end

-- find floor Y position at given world X
function getFloorYAt(worldX)
    local imgX = math.floor(worldX / scale) -- convert world X to image X
    if imgX < 0 or imgX >= mapData:getWidth() then
        return love.graphics.getHeight() -- outside map
    end

    -- scan top to bottom for first solid pixel with air above
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

-- check if a world pixel is solid
local function isSolidPixel(worldX, worldY)
    -- Shift the collision detection to the left by 3 pixels
    local shiftedWorldX = worldX
    local imgX = math.floor(shiftedWorldX / scale)
    local imgY = math.floor((worldY - mapY) / scale)

    if imgX < 0 or imgX >= mapData:getWidth() or imgY < 0 or imgY >= mapData:getHeight() then
        return false
    end

    local _, _, _, a = mapData:getPixel(imgX, imgY)
    return a > 0
end

function playerDies()
    lives = lives - 1
    if lives <= 0 then
        gameState = "menu" -- return to menu when out of lives
        lives = 3          -- reset lives for next game
    else
        resetPlayer()      -- respawn
    end
end

-- handle left/right player movement
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
        -- Hitbox adjustments
        local hitboxOffset = 21 -- padding on each side in world units
        local hitboxWidth  = 54 -- actual collision width in world units

        -- Calculate next hitbox edges
        local nextLeft   = player.x + hitboxOffset + moveX
        local nextRight  = player.x + hitboxOffset + hitboxWidth + moveX

        -- Vertical sample points for collision
        local headY = player.y + 5
        local feetY = player.y + player.h - 5

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


-- reset player to starting position
function resetPlayer()
    player.x = player.startX
    player.y = player.startY
    player.yVelocity = 0
end

function love.update(dt)
    if gameState == "menu" then
        return -- skip update logic if still in menu
    end

    handleHorizontalMovement(dt) -- update horizontal movement

    -- update animation based on movement
    if player.onGround then
        if love.keyboard.isDown("a") or love.keyboard.isDown("d") then
            player.anim = player.animations.walk
        else
            player.anim = player.animations.idle
        end
    end

    -- Apply gravity
    player.yVelocity = player.yVelocity + player.gravity * dt

    -- Predict next Y position
    local nextY = player.y + player.yVelocity * dt

    -- Hitbox adjustments
    local hitboxOffset = 21 -- padding on each side in world units
    local hitboxWidth  = 54 -- actual collision width in world units

    -- Feet positions for collision check
    local leftFootX  = player.x + hitboxOffset + 2
    local rightFootX = player.x + hitboxOffset + hitboxWidth - 2

    -- If moving down, check for ground
    if player.yVelocity >= 0 then
        local floorYLeft  = getFloorYAt(leftFootX)
        local floorYRight = getFloorYAt(rightFootX)
        local floorY = math.min(floorYLeft, floorYRight) -- choose the higher ground

        if nextY + player.h >= floorY then
            -- Land on ground
            player.y = floorY - player.h
            player.yVelocity = 0
            player.onGround = true
        else
            -- No collision, keep falling
            player.y = nextY
            player.onGround = false
        end
    else
        -- Moving up: check for ceiling
        local headLeftX  = player.x + hitboxOffset + 2
        local headRightX = player.x + hitboxOffset + hitboxWidth - 2
        local headY = nextY

        if isSolidPixel(headLeftX, headY) or isSolidPixel(headRightX, headY) then
            -- Hit ceiling
            player.yVelocity = 0
            player.y = math.floor(player.y) -- snap to avoid jitter
        else
            player.y = nextY
        end
    end

    if player.y + player.h >= love.graphics.getHeight() then
        playerDies()
    end

    player.anim:update(dt) -- update current animation

    -- camera follow logic
    local screenMid = love.graphics.getWidth() / 2
    local slack = 100 -- distance before camera moves
    if player.x - cameraX < slack then
        cameraX = player.x - slack
    elseif player.x - cameraX > screenMid - slack then
        cameraX = player.x - (screenMid - slack)
    end
    -- clamp camera inside map boundaries
    cameraX = math.max(0, math.min(cameraX, mapWidth - love.graphics.getWidth()))
end

function love.keypressed(key)
    if gameState == "menu" and key == "space" then
        gameState = "play" -- start the game
    elseif gameState == "play" then
        if key == "w" and player.onGround then
            player.yVelocity = player.jumpForce -- apply jump
            player.onGround = false
            player.anim = player.animations.jump -- switch to jump animation
        elseif key == "r" then
            resetPlayer() -- reset player position

        elseif key == "h" then
        -- Allow toggling even in menu if you want
        showHitbox = not showHitbox
        end
    end
end

function love.draw()
    -- Draw static background (fills entire screen, anchored at 0,0)
    love.graphics.draw(backgroundImage, 0, 0, 0,
        love.graphics.getWidth() / backgroundImage:getWidth(),
        love.graphics.getHeight() / backgroundImage:getHeight()
    )
    -- draw the map at camera position
    love.graphics.draw(mapImage, -cameraX, mapY, 0, scale, scale)

    local frameW, frameH = 32, 32 -- sprite frame size
    local sx, ox

    if player.facing_right then
        sx = scale  -- normal scale
        ox = 0      -- origin x
    else
        sx = -scale -- flip horizontally
        ox = frameW -- adjust origin to flip
    end

    local sy = scale
    local oy = frameH -- anchor at feet

    -- 🔹 DEBUG: Draw hitbox if enabled
    if showHitbox then
        local hitboxOffset = 21 -- padding on each side in world units
        local hitboxWidth  = 54 -- actual collision width in world units
        love.graphics.setColor(1, 0, 0, 0.4) -- semi-transparent red
        love.graphics.rectangle(
            "fill",
            player.x + hitboxOffset - cameraX,
            player.y,
            hitboxWidth,
            player.h
        )
            love.graphics.setColor(1, 1, 1, 1) -- reset color
end


    -- draw player animation
    player.anim:draw(
        player.spriteSheet,
        player.x - cameraX, player.y + player.h,
        0, sx, sy, ox, oy
    )
     -- draw menu LAST so it is always on top
    if gameState == "menu" then
        love.graphics.draw(menuImage, 0, 0)
    end
end