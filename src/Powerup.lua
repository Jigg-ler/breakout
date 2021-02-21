--Powerup Class

Powerup = Class{}

function Powerup:init(power)
    --self.x = x
    --self.y = y
    self.dy = 30
    self.dx = 0
    self.width = 16
    self.height = 16

    self.skin = power --number which tells which powerup will be used

    self.inPlay = true
end

function Powerup:collides(target)
    -- first, check to see if the left edge of either is farther to the right
    -- than the right edge of the other
    if self.x > target.x + target.width or target.x > self.x + self.width then
        return false
    end

    -- then check to see if the bottom edge of either is higher than the top
    -- edge of the other
    if self.y > target.y + target.height or target.y > self.y + self.height then
        return false
    end 

    -- if the above aren't true, they're overlapping
    return true
end

function Powerup:update(dt)
    -- falling
    self.y = self.y + self.dy * dt
    self.x = self.x + self.dx * dt
end

--[[
    Render the paddle by drawing the main texture, passing in the quad
    that corresponds to the proper skin and size.
]]
function Powerup:render()
    if self.inPlay then
        love.graphics.draw(gTextures['main'], gFrames['powerups'][self.skin],
            self.x, self.y)
    end
end