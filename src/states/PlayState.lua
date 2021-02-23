--[[
    -- PlayState Class --
]]

PlayState = Class{__includes = BaseState}

function PlayState:init()

    self.transitionAlpha = 1

    self.boardHighlightX = 0
    self.boardHighlightY = 0

    self.rectHighlighted = false

    self.canInput = true

    self.highlightedTile = nil

    self.score = 0
    self.timer = 60

    Timer.every(0.5, function()
        self.rectHighlighted = not self.rectHighlighted
    end)

    Timer.every(1, function()
        self.timer = self.timer - 1

        if self.timer <= 5 then
            gSounds['clock']:play()
        end
    end)
end

function PlayState:enter(params)

    self.level = params.level

    self.board = params.board or Board(VIRTUAL_WIDTH - 272, 16)

    self.score = params.score or 0

    self.scoreGoal = self.level * 1.25 * 1000
end

function PlayState:update(dt)
    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end

    if self.timer <= 0 then

        Timer.clear()
        
        gSounds['game-over']:play()

        gStateMachine:change('game-over', {
            score = self.score
        })
    end

    if self.score >= self.scoreGoal then

        Timer.clear()

        gSounds['next-level']:play()

        gStateMachine:change('begin-game', {
            level = self.level + 1,
            score = self.score
        })
    end

    if self.canInput then
        if love.keyboard.wasPressed('up') then
            self.boardHighlightY = math.max(0, self.boardHighlightY - 1)
            gSounds['select']:play()
        elseif love.keyboard.wasPressed('down') then
            self.boardHighlightY = math.min(7, self.boardHighlightY + 1)
            gSounds['select']:play()
        elseif love.keyboard.wasPressed('left') then
            self.boardHighlightX = math.max(0, self.boardHighlightX - 1)
            gSounds['select']:play()
        elseif love.keyboard.wasPressed('right') then
            self.boardHighlightX = math.min(7, self.boardHighlightX + 1)
            gSounds['select']:play()
        end
        
        if self.highlightedTile then
            self:mouseSelect()
        else
            self:mouseHighlight()
        end
        
        if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then

            local x = self.boardHighlightX + 1
            local y = self.boardHighlightY + 1

            if not self.highlightedTile then
                self.highlightedTile = self.board.tiles[y][x]

            elseif self.highlightedTile == self.board.tiles[y][x] then
                self.highlightedTile = nil

            elseif math.abs(self.highlightedTile.gridX - x) + math.abs(self.highlightedTile.gridY - y) > 1 then
                gSounds['error']:play()
                self.highlightedTile = nil
            else
                local newTile = self.board.tiles[y][x]
                self.board:swap(self.highlightedTile.gridX, self.highlightedTile.gridY, newTile.gridX, newTile.gridY)

                Timer.tween(0.1, {
                    [self.highlightedTile] = {x = newTile.x, y = newTile.y},
                    [newTile] = {x = self.highlightedTile.x, y = self.highlightedTile.y}
                })

                :finish(function()
                    self:calculateMatches(self.highlightedTile.gridX, self.highlightedTile.gridY, newTile.gridX, newTile.gridY)
                end)
            end
        end
        if love.keyboard.wasPressed("r") then
            self.board:resetR()
        end
    end

    Timer.update(dt)
    self.board:update(dt)
    if self.board:boardCheck() == false then

        self.board:reset()
    end
end


function PlayState:calculateMatches(x1, y1, x2, y2)
    self.highlightedTile = nil

    local matches = self.board:calculateMatches()
    if matches == false and x1 > 0 then
            self.board:swap(x1, y1, x2, y2)
            local tile1 = self.board.tiles[y1][x1]
            local tile2 = self.board.tiles[y2][x2]
            Timer.tween(0.1, {
                [tile1] = {x = tile2.x, y = tile2.y},
                [tile2] = {x = tile1.x, y = tile1.y}
            })
    end
    if matches then
        gSounds['match']:stop()
        gSounds['match']:play()

        for k, match in pairs(matches) do
            for l, tile in pairs(match) do
                self.score = self.score + tile.variety * 10
            end
            self.score = self.score + #match * 50
            self.timer = self.timer + 1
        end

        self.board:removeMatches()

        local tilesToFall = self.board:getFallingTiles()

        Timer.tween(0.25, tilesToFall):finish(function()

            self:calculateMatches(0, 0, 0, 0)
        end)

    else
        self.canInput = true
    end
end

function PlayState:mouseHighlight()
    local mouseX, mouseY = push:toGame(love.mouse.getPosition())

    -- converting to grid coords
    local mouseGridX = math.floor((mouseX - self.board.x )/32) + 1
    local mouseGridY = math.floor((mouseY - self.board.y)/32) + 1

      -- do this only if mouse is inside the board
     if mouseGridX > 0 and mouseGridY > 0 and mouseGridX < 9  and mouseGridY < 9  then
        self.boardHighlightX = mouseGridX - 1
        self.boardHighlightY = mouseGridY - 1

        -- if there is no highlighted tile on the screen, turn selection off

        -- set selection or unhighlight on the board
        if love.mouse.wasPressed(1) then
            if self.highlightedTile == nil then
                self.highlightedTile = self.board.tiles[mouseGridY][mouseGridX]
            end
        end
     end

end

function PlayState:mouseSelect()

    local highX = self.highlightedTile.gridX
    local highY = self.highlightedTile.gridY

    local mouseX, mouseY = push:toGame(love.mouse.getPosition())
    local mouseGridX, mouseGridY = math.floor((mouseX - self.board.x )/32) + 1, math.floor((mouseY - self.board.y)/32) + 1


    if love.mouse.wasPressed(1) and (highX > 0 and highY > 0 and highX < 9 and highY < 9)  then

        if math.abs(mouseGridX - highX) + math.abs(mouseGridY - highY) <= 1 then
            local highTile = self.board.tiles[highY][highX]
            local swapTile = self.board.tiles[mouseGridY][mouseGridX]

            self.board:swap(mouseGridX, mouseGridY, highX, highY)

            Timer.tween(0.1, {
                [highTile] = {x = swapTile.x, y = swapTile.y},
                [swapTile] = {x = highTile.x, y = highTile.y}
            })
            
            -- once the swap is finished, we can tween falling blocks as needed
            :finish(function()
                self:calculateMatches(mouseGridX, mouseGridY, highX, highY)
                
            end)


        else
            self.highlightedTile = nil
        end

    end

    -- draw

    local drawX = highX - 1
    local drawY = highY - 1
    
    love.graphics.setColor(64, 224, 208, 255)
    -- draw actual cursor rect
    love.graphics.setLineWidth(2)       -- draw the 4 highlights orthogonally

    if highX ~= 8 then
     love.graphics.rectangle('line', (drawX+1) * 32 + (VIRTUAL_WIDTH - 272),             --right box
        (drawY) * 32 + 16, 32, 32, 4)
    end
    
    if highX ~= 1 then
    love.graphics.rectangle('line', (drawX - 1) * 32 + (VIRTUAL_WIDTH - 272),           -- left box
    (drawY) * 32 + 16, 32, 32, 4)
    end

    if highY ~= 8 then
    love.graphics.rectangle('line', (drawX) * 32 + (VIRTUAL_WIDTH - 272),               -- bottom box
    (drawY + 1) * 32 + 16, 32, 32, 4)
    end

    if highY ~= 1 then
    love.graphics.rectangle('line', (drawX) * 32 + (VIRTUAL_WIDTH - 272),               -- top box
    (drawY - 1 ) * 32 + 16, 32, 32, 4)
    end

    -- reset color to avoid flash
    love.graphics.setColor(255, 255, 255, 255)
    
end

function PlayState:render()

    self.board:render()
    self.board:renderParticles()
    self.board:renderReset()

    if self.highlightedTile then

        love.graphics.setBlendMode('add')

        love.graphics.setColor(1, 1, 1, 96/255)
        love.graphics.rectangle('fill', (self.highlightedTile.gridX - 1) * 32 + (VIRTUAL_WIDTH - 272),
            (self.highlightedTile.gridY - 1) * 32 + 16, 32, 32, 4)

        love.graphics.setBlendMode('alpha')
    end
    
    if self.highlightedTile then
        self:mouseSelect()
        end

    if self.rectHighlighted then
        love.graphics.setColor(217/255, 87/255, 99/255, 1)
    else
        love.graphics.setColor(172/255, 50/255, 50/255, 1)
    end

    love.graphics.setLineWidth(4)
    love.graphics.rectangle('line', self.boardHighlightX * 32 + (VIRTUAL_WIDTH - 272),
        self.boardHighlightY * 32 + 16, 32, 32, 4)

    love.graphics.setColor(56/255, 56/255, 56/255, 234/255)
    love.graphics.rectangle('fill', 16, 16, 186, 116, 4)

    love.graphics.setColor(99/255, 155/255, 1, 1)
    love.graphics.setFont(gFonts['medium'])
    love.graphics.printf('Level: ' .. tostring(self.level), 20, 24, 182, 'center')
    love.graphics.printf('Score: ' .. tostring(self.score), 20, 52, 182, 'center')
    love.graphics.printf('Goal : ' .. tostring(self.scoreGoal), 20, 80, 182, 'center')
    love.graphics.printf('Timer: ' .. tostring(self.timer), 20, 108, 182, 'center')
end
