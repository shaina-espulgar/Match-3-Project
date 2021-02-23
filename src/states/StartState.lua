--[[
    -- StartState Class --
]]

local positions = {}

StartState = Class{__includes = BaseState}

function StartState:init()

    self.currentMenuItem = 1

    self.colors = {
        [1] = {255/255, 165/255, 0/255, 1},
        [2] = {255/255, 200/255, 124/255, 1},
        [3] = {255/255, 140/255, 0/255, 1},
        [4] = {255/255, 179/255, 71/255, 1},
        [5] = {255/255, 174/255, 66/255, 1},
        [6] = {255/255, 153/255, 51/255, 1},
        [7] = {255/255, 168/255, 18/255, 1},
        [8] = {237/255, 237/255, 237/255, 1},
        [9] = {232/255, 97/255, 0/255, 1},
        [10] = {249/255, 77/255, 0/255, 1},
        [11] = {228/255, 132/255, 0/255, 1},
        [12] = {251/255, 153/255, 2/255, 1},
        [13] = {255/255, 159/255, 0/255, 1}
    }

    self.letterTable = {
        {'H', -210},
        {'A', -172},
        {'I', -145},
        {'K', -120},
        {'Y', -85},
        {'U', -48},
        {'U', -15},
        {'M', 42},
        {'A', 85},
        {'T', 125},
        {'C', 160},
        {'H', 195},
        {'!', 235}
    }

       self.colorTimer = Timer.every(0.05, function()
        
        self.colors[0] = self.colors[6]

        for i = 13, 1, -1 do
            self.colors[i] = self.colors[i - 1]
        end
    end)

    for i = 1, 64 do
        table.insert(positions, gFrames['tiles'][math.random(18)][math.random(6)])
    end

    self.transitionAlpha = 0
out
    self.pauseInput = false
end

function StartState:update(dt)
    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end

    if not self.pauseInput then
        
        if love.keyboard.wasPressed('up') or love.keyboard.wasPressed('down') then
            self.currentMenuItem = self.currentMenuItem == 1 and 2 or 1
            gSounds['select']:play()
        end

        if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then
            if self.currentMenuItem == 1 then

                Timer.tween(1, {
                    [self] = {transitionAlpha = 1}
                }):finish(function()
                    gStateMachine:change('begin-game', {
                        level = 1
                    })

                    self.colorTimer:remove()
                end)
            else
                love.event.quit()
            end

            self.pauseInput = true
        end
    end

    Timer.update(dt)
end

function StartState:render()
    
    for y = 1, 8 do
        for x = 1, 8 do
            
            love.graphics.setColor(0, 0, 0, 1)
            love.graphics.draw(gTextures['main'], positions[(y - 1) * x + x], 
                (x - 1) * 32 + 128 + 3, (y - 1) * 32 + 16 + 3)

            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(gTextures['main'], positions[(y - 1) * x + x], 
                (x - 1) * 32 + 128 + 3, (y - 1) * 32 + 16 + 3)
        end
    end

    love.graphics.setColor(0, 0, 0, 128/255)
    love.graphics.rectangle('fill', 0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT)

    self:drawMatch3Text(-70)
    self:drawOptions(12)

    -- draw our transition rect; is normally fully transparent, unless we're moving to a new state
    love.graphics.setColor(1, 1, 1, self.transitionAlpha)
    love.graphics.rectangle('fill', 0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT)
end

function StartState:drawMatch3Text(y)
    
    love.graphics.setColor(255/255, 222/255, 173/255, 128/255)
    love.graphics.rectangle('fill', VIRTUAL_WIDTH / 3.9, VIRTUAL_HEIGHT / 2 + y, 255, 38)

    love.graphics.setFont(gFonts['large'])
    self:drawTextShadow(' HAIKYUU MATCH !', VIRTUAL_HEIGHT / 2 + y)

    for i = 1, 13 do
        love.graphics.setColor(self.colors[i])
        love.graphics.printf(self.letterTable[i][1], 0, VIRTUAL_HEIGHT / 2 + y,
            VIRTUAL_WIDTH + self.letterTable[i][2], 'center')
    end
end

function StartState:drawOptions(y)
    
    love.graphics.setColor(255/255, 222/255, 173/255, 128/255)
    love.graphics.rectangle('fill', VIRTUAL_WIDTH / 2 - 76, VIRTUAL_HEIGHT / 2 + y, 150, 58, 6)

    love.graphics.setFont(gFonts['medium'])
    self:drawTextShadow('Start', VIRTUAL_HEIGHT / 2 + y + 8)
    
    if self.currentMenuItem == 1 then
        love.graphics.setColor(255/255, 165/255, 0/255, 1)
    else
        love.graphics.setColor(196/255, 98/255, 16/255, 1)
    end
    
    love.graphics.printf('Start', 0, VIRTUAL_HEIGHT / 2 + y + 8, VIRTUAL_WIDTH, 'center')

    love.graphics.setFont(gFonts['medium'])
    self:drawTextShadow('Quit Game', VIRTUAL_HEIGHT / 2 + y + 33)
    
    if self.currentMenuItem == 2 then
        love.graphics.setColor(255/255, 165/255, 0/255, 1)
    else
        love.graphics.setColor(196/255, 98/255, 16/255, 1)
    end
    
    love.graphics.printf('Quit Game', 0, VIRTUAL_HEIGHT / 2 + y + 33, VIRTUAL_WIDTH, 'center')
end

function StartState:drawTextShadow(text, y)
    love.graphics.setColor(34/255, 32/255, 52/255, 1)
    love.graphics.printf(text, 2, y + 1, VIRTUAL_WIDTH, 'center')
    love.graphics.printf(text, 1, y + 1, VIRTUAL_WIDTH, 'center')
    love.graphics.printf(text, 0, y + 1, VIRTUAL_WIDTH, 'center')
    love.graphics.printf(text, 1, y + 2, VIRTUAL_WIDTH, 'center')
end
