-- ========================================================================== --
--   Platform implementation.                                                 --
--   Copyright (c) 2011 Laurens Rodriguez Oscanoa.                            --
--   This code is released under the MIT license.                             --
-- -------------------------------------------------------------------------- --

-- Size of square tile
local TILE_SIZE = 12

-- Board up-left corner coordinates
local BOARD_X = 180
local BOARD_Y = 4

-- Preview tetromino position
local PREVIEW_X = 112
local PREVIEW_Y = 210

-- Score position and length on screen
local SCORE_X      = 72
local SCORE_Y      = 52
local SCORE_LENGTH = 10

-- Lines position and length on screen
local LINES_X      = 108
local LINES_Y      = 34
local LINES_LENGTH = 5

-- Level position and length on screen
local LEVEL_X      = 108
local LEVEL_Y      = 16
local LEVEL_LENGTH = 5

-- Tetromino subtotals position
local TETROMINO_X   = 425
local TETROMINO_L_Y = 53
local TETROMINO_I_Y = 77
local TETROMINO_T_Y = 101
local TETROMINO_S_Y = 125
local TETROMINO_Z_Y = 149
local TETROMINO_O_Y = 173
local TETROMINO_J_Y = 197

-- Size of subtotals 
local TETROMINO_LENGTH = 5

-- Tetromino total position
local PIECES_X      = 418
local PIECES_Y      = 221
local PIECES_LENGTH = 6

-- Size of number 
local NUMBER_WIDTH  = 7
local NUMBER_HEIGHT = 9

-- Libretro joypad buttons const
RETRO_DEVICE_ID_JOYPAD_B        = 1
RETRO_DEVICE_ID_JOYPAD_Y        = 2
RETRO_DEVICE_ID_JOYPAD_SELECT   = 3
RETRO_DEVICE_ID_JOYPAD_START    = 4
RETRO_DEVICE_ID_JOYPAD_UP       = 5
RETRO_DEVICE_ID_JOYPAD_DOWN     = 6
RETRO_DEVICE_ID_JOYPAD_LEFT     = 7
RETRO_DEVICE_ID_JOYPAD_RIGHT    = 8
RETRO_DEVICE_ID_JOYPAD_A        = 9
RETRO_DEVICE_ID_JOYPAD_X        = 10
RETRO_DEVICE_ID_JOYPAD_L        = 11
RETRO_DEVICE_ID_JOYPAD_R        = 12
RETRO_DEVICE_ID_JOYPAD_L2       = 13
RETRO_DEVICE_ID_JOYPAD_R2       = 14
RETRO_DEVICE_ID_JOYPAD_L3       = 15
RETRO_DEVICE_ID_JOYPAD_R3       = 16

Platform = {
    m_bmpBackground = nil;
    m_bmpBlocks = nil;
    m_bmpNumbers = nil;  

    m_blocks = nil;
    m_numbers = nil;

    m_musicLoop = nil;
    m_musicIntro = nil;
}

-- Initializes platform.
function Platform:init()
    -- Initialize random generator
    math.randomseed(os.time())

    -- Load images.
    self.m_bmpBackground = love.graphics.newImage("assets/back.png")

    self.m_bmpBlocks = love.graphics.newImage("assets/blocks.png")
    self.m_bmpBlocks:setFilter("nearest", "nearest")
    local w = self.m_bmpBlocks:getWidth()
    local h = self.m_bmpBlocks:getHeight()

    -- Load music.
	self.m_musicIntro = love.audio.newSource("assets/stc_theme_intro.ogg", "static")
	self.m_musicIntro:setVolume(0.5)
	self.m_musicIntro:play()
	self.m_musicLoop = love.audio.newSource("assets/stc_theme_loop.ogg", "stream")
	self.m_musicLoop:setLooping(true)
	self.m_musicLoop:setVolume(0.5)

    -- Load sfx.
    self.fx_drop = love.audio.newSource("assets/fx_drop.wav", "static")
    self.fx_line = love.audio.newSource("assets/fx_line.wav", "static")

    -- Create quads for blocks
    self.m_blocks = {}
    for shadow = 0, 1 do
        self.m_blocks[shadow] = {}
        for color = 0, Game.COLORS - 1 do
            self.m_blocks[shadow][color] = love.graphics.newQuad(TILE_SIZE * color, (TILE_SIZE+1) * shadow,
                                                                 TILE_SIZE + 1, TILE_SIZE + 1, w, h)
        end
    end

    self.m_bmpNumbers = love.graphics.newImage("assets/numbers.png")
    self.m_bmpNumbers:setFilter("nearest", "nearest")
    w = self.m_bmpNumbers:getWidth()
    h = self.m_bmpNumbers:getHeight()

    -- Create quads for numbers
    self.m_numbers = {}
    for color = 0, Game.COLORS - 1 do
        self.m_numbers[color] = {}
        for digit = 0, 9 do
            self.m_numbers[color][digit] = love.graphics.newQuad(NUMBER_WIDTH * digit, NUMBER_HEIGHT * color,
                                                                 NUMBER_WIDTH, NUMBER_HEIGHT, w, h)
        end
    end
end

-- Draw a tile from a tetromino
function Platform:drawTile(x, y, tile, shadow)
    love.graphics.draw(self.m_bmpBlocks, self.m_blocks[shadow][tile], x, y)
end

-- Draw a number on the given position
function Platform:drawNumber(x, y, number, length, color)
    local pos = 0
    repeat
        love.graphics.draw(self.m_bmpNumbers, self.m_numbers[color][number % 10],
                            x + NUMBER_WIDTH * (length - pos), y)
        number = math.floor(number / 10)
        pos = pos + 1
    until (pos >= length)
end

-- Render the state of the game using platform functions.
function Platform:renderGame()
    -- Draw background
    love.graphics.draw(self.m_bmpBackground, 0, 0)

    -- Draw preview block
    if Game:showPreview() then
        for i = 0, Game.TETROMINO_SIZE - 1 do
            for j = 0, Game.TETROMINO_SIZE - 1 do
                if (Game:nextBlock().cells[i][j] ~= Game.Cell.EMPTY) then
                    print(PREVIEW_X, TILE_SIZE, i)
                    Platform:drawTile(PREVIEW_X + TILE_SIZE * i - 1,
                                      PREVIEW_Y + TILE_SIZE * j - 1,
                                      Game:nextBlock().cells[i][j], 0)
                end
            end
        end
    end

    -- Draw shadow tetromino
    if (Game:showShadow() and Game:shadowGap() > 0) then
        for i = 0, Game.TETROMINO_SIZE - 1 do
            for j = 0, Game.TETROMINO_SIZE - 1 do
                if (Game:fallingBlock().cells[i][j] ~= Game.Cell.EMPTY) then
                    Platform:drawTile(BOARD_X + (TILE_SIZE * (Game:fallingBlock().x + i)) - 1,
                                      BOARD_Y + (TILE_SIZE * (Game:fallingBlock().y + Game:shadowGap() + j)) - 1,
                                      Game:fallingBlock().cells[i][j], 1)
                end
            end
        end
    end

    -- Draw the cells in the board
    for i = 0, Game.BOARD_TILEMAP_WIDTH - 1 do
        for j = 0, Game.BOARD_TILEMAP_HEIGHT - 1 do
            if (Game:getCell(i, j) ~= Game.Cell.EMPTY) then
                Platform:drawTile(BOARD_X + (TILE_SIZE * i) - 1,
                                  BOARD_Y + (TILE_SIZE * j) - 1,
                                  Game:getCell(i, j), 0)
            end
        end
    end

    -- Draw falling tetromino
    for i = 0, Game.TETROMINO_SIZE - 1 do
        for j = 0, Game.TETROMINO_SIZE - 1 do
            if (Game:fallingBlock().cells[i][j] ~= Game.Cell.EMPTY) then
                Platform:drawTile(BOARD_X + TILE_SIZE * (Game:fallingBlock().x + i) - 1,
                                  BOARD_Y + TILE_SIZE * (Game:fallingBlock().y + j) - 1,
                                  Game:fallingBlock().cells[i][j], 0)
            end
        end
    end

    -- Draw game statistic data
    if (not Game:isPaused()) then
        Platform:drawNumber(LEVEL_X, LEVEL_Y, Game:stats().level, LEVEL_LENGTH, Game.Cell.WHITE)
        Platform:drawNumber(LINES_X, LINES_Y, Game:stats().lines, LINES_LENGTH, Game.Cell.WHITE)
        Platform:drawNumber(SCORE_X, SCORE_Y, Game:stats().score, SCORE_LENGTH, Game.Cell.WHITE)

        Platform:drawNumber(TETROMINO_X, TETROMINO_L_Y, Game:stats().pieces[Game.TetrominoType.L], TETROMINO_LENGTH, Game.Cell.ORANGE)
        Platform:drawNumber(TETROMINO_X, TETROMINO_I_Y, Game:stats().pieces[Game.TetrominoType.I], TETROMINO_LENGTH, Game.Cell.CYAN)
        Platform:drawNumber(TETROMINO_X, TETROMINO_T_Y, Game:stats().pieces[Game.TetrominoType.T], TETROMINO_LENGTH, Game.Cell.PURPLE)
        Platform:drawNumber(TETROMINO_X, TETROMINO_S_Y, Game:stats().pieces[Game.TetrominoType.S], TETROMINO_LENGTH, Game.Cell.GREEN)
        Platform:drawNumber(TETROMINO_X, TETROMINO_Z_Y, Game:stats().pieces[Game.TetrominoType.Z], TETROMINO_LENGTH, Game.Cell.RED)
        Platform:drawNumber(TETROMINO_X, TETROMINO_O_Y, Game:stats().pieces[Game.TetrominoType.O], TETROMINO_LENGTH, Game.Cell.YELLOW)
        Platform:drawNumber(TETROMINO_X, TETROMINO_J_Y, Game:stats().pieces[Game.TetrominoType.J], TETROMINO_LENGTH, Game.Cell.BLUE)

        Platform:drawNumber(PIECES_X, PIECES_Y, Game:stats().totalPieces, PIECES_LENGTH, Game.Cell.WHITE)
    end

	-- Adding music loop check here for convenience.
	if (self.m_musicIntro) then
		if (self.m_musicIntro:isStopped()) then
			self.m_musicIntro = nil
			self.m_musicLoop:play()
		end
	end
end

function Platform:getSystemTime()
    return math.floor(1000 * love.timer.getTime())
end

function Platform:random()
    return math.random(1000000000)
end
