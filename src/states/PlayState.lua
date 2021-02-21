--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.balls = { params.ball }
    self.level = params.level
    
    self.hasLock = params.hasLock
    self.key = params.key
    self.powerups = {}

    self.recoverPoints = params.recoverPoints

    -- give ball random starting velocity
    self.balls[1].dx = math.random(-200, 200)
    self.balls[1].dy = math.random(-50, -60)
end

function PlayState:update(dt)

    if love.keyboard.isDown('down') then
        self.paddle.x = self.balls[1].x - self.paddle.width / 2
    end

    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end

    self.paddle:update(dt)

    for k, ball in pairs(self.balls) do
        ball:update(dt)
    end

    for k, powerup in pairs(self.powerups) do
        powerup:update(dt)
    end

    for k, ball in pairs(self.balls) do
        if ball:collides(self.paddle) then

            ball.y = self.paddle.y - 8
            ball.dy = -ball.dy

            if ball.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
                ball.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - ball.x))

            elseif ball.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
                ball.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - ball.x))
            end

            gSounds['paddle-hit']:play()
        end
    end

    -- detect collision across all bricks with the ball
    for k, brick in pairs(self.bricks) do

        for kk, ball in pairs(self.balls) do
        -- only check collision if we're in play
            if brick.inPlay and ball:collides(brick) then

                brick:hit(self.key)

                -- add to score
                if not brick.inPlay or not brick.isLocked then
                    self.score = self.score + (brick.tier * 200 + brick.color * 25 + (brick.isLocked and 1 or 0) * 500)
                end

                --if the brick is no longer in play // not locked brick
                if not brick.inPlay then
                    local powerup = nil
                    if self:powerupSpawn(brick, self.level) then
                        powerup = Powerup(7)
                    end

                    --if it's locked
                    if self.hasLock then
                        if self:keySpawn() and not self.key and not self:powerupsContainSkin(10) then
                            powerup = Powerup(10)
                        end
                    end

                    if powerup ~= nil then
                        powerup.x = brick.x + brick.width / 2 - powerup.width / 2
                        powerup.y = brick.y + brick.height / 2
                        table.insert(self.powerups, powerup)
                    end

                    if brick.isLocked then
                        self.key = false
                        self.hasLock = false
                    end
                end

                -- if we have enough points, recover a point of health
                if self.score > self.recoverPoints then
                    -- can't go above 3 health
                    self.health = math.min(3, self.health + 1)

                    self.recoverPoints = self.recoverPoints + math.min(100000, self.recoverPoints * 2)

                    gSounds['recover']:play()

                    self.paddle:grow()
                end

                -- go to our victory screen if there are no more bricks left
                if self:checkVictory() then
                    gSounds['victory']:play()

                    gStateMachine:change('victory', {
                        level = self.level,
                        paddle = self.paddle,
                        health = self.health,
                        score = self.score,
                        highScores = self.highScores,
                        ball = self.balls[1],
                        recoverPoints = self.recoverPoints
                    })
                end


                if ball.x + 2 < brick.x and ball.dx > 0 then
                    
                    -- flip x velocity and reset position outside of brick
                    ball.dx = -ball.dx
                    ball.x = brick.x - 8
                
                elseif ball.x + 6 > brick.x + brick.width and ball.dx < 0 then
                    
                    -- flip x velocity and reset position outside of brick
                    ball.dx = -ball.dx
                    ball.x = brick.x + 32
                
                -- top edge if no X collisions, always check
                elseif ball.y < brick.y then
                    
                    -- flip y velocity and reset position outside of brick
                    ball.dy = -ball.dy
                    ball.y = brick.y - 8
                
                -- bottom edge if no X collisions or top collision, last possibility
                else
                    
                    -- flip y velocity and reset position outside of brick
                    ball.dy = -ball.dy
                    ball.y = brick.y + 16
                end

                -- slightly scale the y velocity to speed up the game, capping at +- 150
                if math.abs(ball.dy) < 150 then
                    ball.dy = ball.dy * 1.02
                end

                -- only allow colliding with one brick, for corners
                break
            end
        end
    end

    --powerup collision
    for k, powerup in pairs(self.powerups) do
        if powerup:collides(self.paddle) then

            self.score + self.score + 200

            if powerup.skin == 10 then
                self.key = true
            else
                for i = 0, 1 do
                    local newBall = Ball()
                    newBall.skin = math.random(7)
                    newBall.x = self.paddle.x + self.paddle.width / 2 - newBall.width / 2
                    newBall.y = self.paddle.y - newBall.height
                    newBall.dx = math.random(-200, 200)
                    newBall.dy = math.random(-50, -60)
                    table.insert(self.balls, newBall)
                end
            end
            powerup.inPlay = false
        end
    end

    for k, powerup in pairs(self.powerups) do
        if powerup.inPlay == false or powerup.y >= VIRTUAL_HEIGHT then
            table.remove(self.powerups, k)
        end
    end

    for k, ball in pairs(self.balls) do
        if ball.y >= VIRTUAL_HEIGHT then
            table.remove(self.balls, k)
        end
    end

    -- if ball goes below bounds, revert to serve state and decrease health
    if #self.balls <= 0 then
        self.health = self.health - 1
        gSounds['hurt']:play()

        if self.health == 0 then
            gStateMachine:change('game-over', {
                score = self.score,
                highScores = self.highScores
            })
        else
            self.paddle:shrink()

            gStateMachine:change('serve', {
                paddle = self.paddle,
                bricks = self.bricks,
                health = self.health,
                score = self.score,
                highScores = self.highScores,
                level = self.level,
                recoverPoints = self.recoverPoints,
                hasLock = self.hasLock,
                key = self.key
            })
        end
    end

    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function PlayState:render()
    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    self.paddle:render()
    
    for k, ball in pairs(self.balls) do
        ball:render()
    end

    for k, powerup in pairs(self.powerups) do
        powerup:render()
    end

    if self.key then
        renderKeyPowerup()
    end

    renderScore(self.score)
    renderHealth(self.health)

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end 
    end

    return true
end

function PlayState:powerupSpawn(brick, level)
    local levelseed = math.random(1, (level % 9) + 1)
    local seed = brick.tierVal * 12 + brick.colorVal * 7
    return math.random(1,94) <= seed+levelseed
end

function PlayState:brickCount()
    local counter = 0
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            counter = counter + 1
        end
    end
    return counter
end

function PlayState:keySpawn()
    return math.random(1, self:brickCount()) <= 2
end

function PlayState:powerupsContainSkin(skin)
    for k, powerup in pairs(self.powerups) do
        if powerup.skin == skin then
            return true
        end
    end
    return false
end