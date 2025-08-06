
-- This is the function that initializes the game.
function love.load()
    -- Load the anim8 library first.
    anim8 = require 'libraries/anim8'
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- We need to load our images first.
    -- This variable will hold our player's sprite sheet image.
    local playerSpriteSheet = love.graphics.newImage('sprites/player-sheet.png')

    -- Your love.draw function also tries to draw a background image.
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
        -- Jump force is a negative value, push     ing the player up.
        gravity = 1400,
        -- Fixed value of acceleration
        speed = 250,
        onGround = false
        -- The player spawns in/loads from the air and falls down to hit the floor.
    }
    
    -- Assign the background image to a global variable so love.draw() can access it.
    -- This is necessary because the 'background' variable above is local to this function.

    -- Now that player.spriteSheet has a value, we can create the grid.
    player.grid = anim8.newGrid(32, 32, player.spriteSheet:getWidth(), player.spriteSheet:getHeight())

    player.animations = {}
    -- Create the 'down' animation using the first four frames in the first row.
    -- The second parameter, 0.2, sets the duration of each frame to 0.2 seconds.
    player.animations.idleright = anim8.newAnimation(player.grid('1-4', 1), 0.3)
    player.animations.walkright = anim8.newAnimation(player.grid('1-4', 2), 0.2)
    player.animations.idleleft = anim8.newAnimation(player.grid('1-4', 3), 0.3)
    player.animations.walkleft = anim8.newAnimation(player.grid('1-4', 4), 0.2)

    player.anim = player.animations.idleright
    groundY = 400
    -- Y level of the ground the player can walk around on.
end


function love.update(dt) -- It's called automatically by the engine for every frame of the game.

    -- Horizontal movement, also checks if keyboard button "a" and "d" is pressed.
    if love.keyboard.isDown("a") then
        player.x = player.x - player.speed * dt
        player.anim = player.animations.walkleft
    -- If 'a' is not pressed, check if the "d" key is currently being held down.
    elseif love.keyboard.isDown("d") then
        player.x = player.x + player.speed * dt
        player.anim = player.animations.walkright

    else
        player.anim = player.animations.idleright
    end

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
end

function love.keypressed(key)
    -- check if w key is pressed and if player is on the ground
    if key == "w" and player.onGround then
        -- create jump mkovement, makes player go up
        player.yVelocity = player.jumpForce
        player.onGround = false
    end
end

function love.draw()
    -- Draw ground
 
 
    love.graphics.rectangle("fill", 0, groundY, love.graphics.getWidth(), 100)

    -- Draw player
    player.anim:draw(player.spriteSheet, player.x, player.y, nil, 3)
    
end
