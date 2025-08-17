-- This is the function that initializes the game.
local cameraX = 0
local mapImage
function love.load()


    anim8 = require 'libraries/anim8'
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- This variable will hold our player's sprite sheet image.
    local playerSpriteSheet = love.graphics.newImage('sprites/player-sheet.png')

    -- Load map
    local mapOffsetY = 53
    local scale = 3
    mapImage = love.graphics.newImage("map.png")
    mapWidth = mapImage:getWidth()* scale
    mapHeight = mapImage:getHeight()* scale
    mapY = love.graphics.getHeight() - mapHeight+ mapOffsetY
    -- This line loads a background image from the 'sprites' folder.

    -- Now that we have loaded the images, we can create the 'player' table.
    -- This table holds all the data related to our player character.
    player = {
        -- Initial Position of Player
        x = 100, 
        y = 300,
        -- Hitbox size adjustable w(width) h(height)
        w = 40,
        h = 40,
        -- The loaded sprite sheet is now assigned to the player's 'spriteSheet' property.
        spriteSheet = playerSpriteSheet,
        -- Later this will be what collides with enemies and walls.
        yVelocity = 0,
        jumpForce = -600,
        -- Jump force is a negative value, pushing the player up.
        gravity = 1400,
        -- Fixed value of acceleration
        speed = 250,
        facing_right = true,
        onGround = false

        -- The player spawns in/loads from the air and falls down to hit the floor.
    }
    groundY = mapY + mapHeight - player.h 
    
    -- Assigns the background image to a global variable so love.draw() can access it.
    -- This is necessary because the 'background' variable above is local to this function.

    -- Now that player.spriteSheet has a value, we can create the grid.
    player.grid = anim8.newGrid(32, 32, player.spriteSheet:getWidth(), player.spriteSheet:getHeight())

    player.animations = {}
    player.animations.idle = anim8.newAnimation(player.grid('1-4', 1), 0.3)
    player.animations.walk = anim8.newAnimation(player.grid('1-4', 2), 0.2)
    player.animations.jump = anim8.newAnimation(player.grid('1-5', 5), 0.2)

    player.anim = player.animations.idle

    groundY = 400
    -- Y level of the ground the player can walk around on.
end

function handleHorizontalMovement(dt)
    local is_moving = false
    if love.keyboard.isDown("a") then
        player.x = player.x - player.speed * dt
        player.facing_right = false
        is_moving = true
    elseif love.keyboard.isDown("d") then
        player.x = player.x + player.speed * dt
        player.facing_right = true
        is_moving = true
    end
    return is_moving
end

function love.update(dt) -- It's called automatically by the engine for every frame of the game.

    -- Horizontal movement, also checks if keyboard button "a" and "d" is pressed.
    handleHorizontalMovement(dt)
    if player.onGround then
        if love.keyboard.isDown("a") or love.keyboard.isDown("d") then
            player.anim = player.animations.walk
        else
            player.anim = player.animations.idle
        end
    end  -- ✅ closes if player.onGround then

    -- Gravity
    player.yVelocity = player.yVelocity + player.gravity * dt
    player.y = player.y + player.yVelocity * dt

    -- Ground collision
    if player.y + player.h >= groundY then
        player.y = groundY - player.h
        player.yVelocity = 0
        player.onGround = true
    else
        player.onGround = false
    end 
    
    -- Update the animation to advance to the next frame.
    player.anim:update(dt)


    -- Camera logic: Follow player but allow slack of 100px
    local screenMid = love.graphics.getWidth() / 2
    local slack = 100
    if player.x - cameraX < slack then
        cameraX = player.x - slack
    elseif player.x - cameraX > screenMid - slack then
        cameraX = player.x - (screenMid - slack)
    end

    -- Clamp camera to map edges
    cameraX = math.max(0, math.min(cameraX, mapWidth - love.graphics.getWidth()))
end

function love.keypressed(key)
    -- check if w key is pressed and if player is on the ground
    if key == "w" and player.onGround then
        -- create jump movement, makes player go up
        player.yVelocity = player.jumpForce
        player.onGround = false
        player.anim = player.animations.jump
    end
end

function love.draw()
    local scaleX = player.facing_right and 3 or -3
    local offsetX = player.facing_right and 0 or player.w  -- adjust for flip origin

    -- Draw map with camera offset
    love.graphics.draw(mapImage, -cameraX, mapY, 0, 3, 3)

    -- Draw player with camera offset
    player.anim:draw(player.spriteSheet, player.x - cameraX + offsetX, player.y, nil, scaleX, 3)
end
