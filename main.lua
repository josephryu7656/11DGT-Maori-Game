-- main.lua

-- This is the function that initializes the game. 
function love.load()
    player = {
        -- Initial Position of Player
        x = 100, 
        y = 300,
        -- Hitbox size adjustable w(width) h(height)
        w = 40,
        h = 40,
        -- Later this will be what collides with enemies and walls.
        yVelocity = 0,

        jumpForce = -400,
        -- Jump force is a negative value 
        gravity = 1400,
        -- Fixed value of acceleration
        speed = 250,
        onGround = false
        -- The player spawns in/loads from the air and falls down to hit the floor.
    }

    groundY = 400
    -- Y level of the ground the player can walk around on.
end


function love.update(dt) -- It's called automatically by the engine for every frame of the game.

    -- Horizontal movement, also checks if keyboard button "a" and "d" is pressed.
    if love.keyboard.isDown("a") then
        player.x = player.x - player.speed * dt
    -- If 'a' is not pressed, check if the "d" key is currently being held down.
    elseif love.keyboard.isDown("d") then
        player.x = player.x + player.speed * dt
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
    love.graphics.setColor(0, 0.6, 0)
    love.graphics.rectangle("fill", 0, groundY, love.graphics.getWidth(), 100)

    -- Draw player
    love.graphics.setColor(0, 0, 1)
    love.graphics.rectangle("fill", player.x, player.y, player.w, player.h)
end
