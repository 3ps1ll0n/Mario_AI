--CONSTANTE--
NOM_STATE = "debut.state"

WIDTH_CAMERA = 256
HEIGHT_CAMERA = 224
MAX_SPRITE = 11

WIDTH_INPUTS = 16
HEIGHT_INPUTS = 14
TILE_SIZE = 16
VIEW_WIDTH = WIDTH_INPUTS * TILE_SIZE
VIEW_HEIGHT = HEIGHT_INPUTS * TILE_SIZE


NEURON_DISPLAY_SIZE = 4 
X_NEURON_ANCHOR = 100
Y_NEURON_ANCHOR = 25

SIZE_WIDTH_OUTPUT = 20
SIZE_HEIGTH_OUTPUT = 10
X_OUTPUT_ANCHOR = 200
Y_OUTPUT_ANCHOR = 10

CONTROLER_INPUT = {'A', 'B', 'X', 'Y', 'Up', 'Down', 'Left', 'Right'}

--CLASSES--

Neurons = {biases = 0}

Layer = {neurons = {}, connections = {}}

Network = {input = {}, layers = {}, output = {}}

--METHODS--

function newNetwork()
    local n = {}
    n.input = {}
    n.layers = {}
    n.output = {}
    return n
end

--FUNCTIONS--

function getInputsIndice(x, y)
	return x + ((y-1) * WIDTH_INPUTS)
end

function getMarioPos()
    local mario = {}
    mario.x = memory.read_s16_le(0x94)
    mario.y = memory.read_s16_le(0x96)
    return mario
end

function getRelPos(pos)
    local mario = getMarioPos()
    mario.x = mario.x - VIEW_WIDTH / 2
    mario.y = mario.y - VIEW_HEIGHT / 2
    local relPos = {}

    relPos.x = math.floor((pos.x - mario.x) / TILE_SIZE) + 1
    relPos.y = math.floor((pos.y - mario.y) / TILE_SIZE) + 1

    return relPos
end

function drawInput(inputs)
    local j = 0
    for i = 1, WIDTH_INPUTS, 1 do
        for j = 1, HEIGHT_INPUTS, 1 do
            local indice = getInputsIndice(i, j)
            local x = X_NEURON_ANCHOR + (i - 1) * NEURON_DISPLAY_SIZE
            local y = Y_NEURON_ANCHOR + (j - 1) * NEURON_DISPLAY_SIZE

            local color = "gray"
            if inputs[indice] > 0 then
                color = "white"
            end    
            if inputs[indice] < 0 then
                color = "red"
            end    

            gui.drawRectangle(x, y, NEURON_DISPLAY_SIZE, NEURON_DISPLAY_SIZE, "black", color)

            --*Draw Mario (He's not an input)
            local mario = getRelPos(getMarioPos())
            mario.x = (mario.x - 1) * NEURON_DISPLAY_SIZE + X_NEURON_ANCHOR
	        mario.y = (mario.y - 1) * NEURON_DISPLAY_SIZE + Y_NEURON_ANCHOR
            gui.drawRectangle(mario.x, mario.y, NEURON_DISPLAY_SIZE, NEURON_DISPLAY_SIZE * 2, "black", "blue")

        end
    end
end

function drawOutput(output)
    if #output == 8 then
        for i = 1, #output, 1 do
            local color = "gray"
            if output[i] > 0.5 then
                color = "white"
            end
            gui.drawRectangle(X_OUTPUT_ANCHOR, Y_OUTPUT_ANCHOR + (i * SIZE_HEIGTH_OUTPUT), SIZE_WIDTH_OUTPUT, SIZE_HEIGTH_OUTPUT, "black", color)
            gui.drawString(X_OUTPUT_ANCHOR + SIZE_WIDTH_OUTPUT, Y_OUTPUT_ANCHOR + i * SIZE_HEIGTH_OUTPUT, CONTROLER_INPUT[i], "black", "white", 10, "Arial")
        end
    end
end

function getTiles()
    local tiles = {}
    local mario = getMarioPos()
    mario.x = mario.x - (WIDTH_INPUTS * TILE_SIZE)/2
    mario.y = mario.y - (HEIGHT_INPUTS * TILE_SIZE)/2
    

    for i = 1, WIDTH_INPUTS, 1 do
        for j = 1, HEIGHT_INPUTS, 1 do
            local relativeX = math.ceil((mario.x + ((i - 1) * TILE_SIZE)) / TILE_SIZE)
            local relativeY = math.ceil((mario.y + ((j - 1) * TILE_SIZE)) / TILE_SIZE)

            tiles[getInputsIndice(i, j)] = memory.readbyte(
                0x1C800 +
                math.floor(relativeX/TILE_SIZE) * 0x1B0 +
                (relativeY * TILE_SIZE) +
                (relativeX % TILE_SIZE)
                
            )
        end
    end
    return tiles
end

function getSprites()
    local sprites = {}
    local j = 1
    for i = 0, MAX_SPRITE, 1 do
        if memory.readbyte(0x14C8 + i) > 7 then
            sprites[j] = {
                x = memory.readbyte(0xE4 + i) + (memory.readbyte(0x14E0 + i) * 256),
                y = math.floor(memory.readbyte(0xD8 + i) + (memory.readbyte(0x14D4 + i) * 256))
            }

            j = j + 1
        end    
        if memory.readbyte(0x170B + i) ~= 0 then
            sprites[j] = {
                x = memory.readbyte(0x171F + i) + (memory.readbyte(0x1733 + i) * 256),
                y = math.floor(memory.readbyte(0x1715 + i) + (memory.readbyte(0x1729 + i) * 256))
            }

            j = j + 1
        end
        
    end

    return sprites

end

function getInputs()
    local inputs = {}
    local tiles = getTiles()
    local sprites = getSprites()

    for i = 1, WIDTH_INPUTS, 1 do
		for j = 1, HEIGHT_INPUTS, 1 do
			inputs[getInputsIndice(i, j)] = 0
		end
	end

    for i = 1, WIDTH_INPUTS, 1 do
        for j = 1, HEIGHT_INPUTS, 1 do
            local indice = getInputsIndice(i, j)

            if tiles[indice] ~= 0 then
                inputs[indice] = tiles[indice]
            end
        end
    end
    local inScreen = 0
    for i = 1, #sprites, 1 do
        local input = getRelPos(sprites[i])
        if(input.x > 0 and input.x < (VIEW_WIDTH / TILE_SIZE) + 1) then
            inputs[getInputsIndice(input.x, input.y)] = -1
            inScreen = inScreen + 1
        end
    end

    gui.text(50, 33, inScreen)

    return inputs
end

--VARIABLES--

NETWORK = newNetwork()

--SCRIPT--

console.log('AI STARTED')
savestate.load(NOM_STATE)

while true do
    local mario = memory.read_s16_le(0x94);
    gui.text(50, 50, mario)
    gui.text(50, 25, #getSprites())
    --gui.drawRectangle(X_NEURON_ANCHOR, Y_NEURON_ANCHOR, NEURON_DISPLAY_SIZE, NEURON_DISPLAY_SIZE, "black", "white")
    NETWORK.input = getInputs()
    drawInput(NETWORK.input)

    drawOutput({math.random(), math.random(), math.random(), math.random(), math.random(), math.random(), math.random(), math.random()})
    
    joypad.set({Right = true}, 1)
    emu.frameadvance()

    if memory.readbyte(0x13E0) == 62 then
        savestate.load(NOM_STATE)
    end
end