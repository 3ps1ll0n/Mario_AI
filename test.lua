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

POPULATION_SIZE = 20
GENRATION = 0

NEURON_DISPLAY_SIZE = 4 
X_NEURON_ANCHOR = 100
Y_NEURON_ANCHOR = 25

SIZE_WIDTH_OUTPUT = 20
SIZE_HEIGTH_OUTPUT = 10
X_OUTPUT_ANCHOR = 200
Y_OUTPUT_ANCHOR = 10

NBRE_OUTPUT = 8
CONTROLER_INPUT_STR = {'A', 'B', 'X', 'Y', 'Up', 'Down', 'Left', 'Right'}
CONTROLER_INPUT =   {
                        {name = "P1 A"},
                        {name = "P1 B"},
                        {name = "P1 X"},
                        {name = "P1 Y"},
                        {name = "P1 Up"},
                        {name = "P1 Down"},
                        {name = "P1 Left"},
                        {name = "P1 Right"} 
                    }

MAX_STATIC_FRAMES = 100

--CLASSES--

--CONSTRUCTOR--

function newEmptyPopulation()
    local p = {}
    p.pop = {}
    p.maxFitness = 0

    return p
end

function newPopulation()
    local p = newEmptyPopulation()
    for i = 1, POPULATION_SIZE, 1 do
        p.pop[i] = newNetwork()
        p.pop[i].outputLayer = newLayer(8, WIDTH_INPUTS * HEIGHT_INPUTS)
    end

    return p
end

function newNetwork()
    local n = {}
    n.input = {}
    n.layers = {}
    n.outputLayer = {}
    n.output = {}
    n.fitness = 0
    return n
end

function newLayer(nbreNeurons, nbreInput)
    local l = newEmptyLayer()

    for i = 1, nbreNeurons, 1 do
        l.biases[i] = 0 --*Init Biases
        l.weigth[i] = {}
        for j = 1, nbreInput, 1 do
            local isNeg = math.random(0, 1)
            if isNeg == 0 then isNeg = -1 end
            l.weigth[i][j] = (math.random(1, 100) * 0.01) * isNeg
        end
    end
    return l
end

function newEmptyLayer()
    local l = {}
    l.biases = {}
    l.weigth = {}

    return l
end

--METHODS--

function getActivationOutput(network)
    local currentInput = network.input
    --console.log(#network.layers)
    for i = 1, #network.layers, 1 do
        network.output = ReLU(forward(currentInput, network.layers[i].biases, network.layers[i].weigth))
        currentInput = network.output
    end
        --console.log(#network.output)

    network.output = softmax(forward(currentInput, network.outputLayer.biases, network.outputLayer.weigth))

    --console.log(#network.output)

    return  network.output
    
end

--MATH_FUNCTION--

function forward(input, biases, weigth)
    local output = {}
        for i = 1, #weigth, 1 do
            local sumOf = 0
            for j = 1, #weigth[i], 1 do
                sumOf = sumOf + (input[j] * weigth[i][j])
            end
            output[i] = sumOf + biases[i]
        end
    return output
end

function sum(input)
    local acc = 0.0
    for i = 1, #input, 1 do
        acc = acc + input[i]
    end
    return acc
end

function max(input)
    local maxValue = -0xfffffff0

    for i = 1, #input, 1 do
        if maxValue < input[i] then
            maxValue = input[i]
        end
    end

    return maxValue
end

function ReLU(input)
    local output = {}
    for i = 1, #input, 1 do
        output[i] = math.max(0.0, input[i])
    end
    return output
end

function softmax(input)
    local output = {}
    local expOutput = {}
    local maxValue = max(input)
    local sumOf = 0
    for i = 1, #input, 1 do
        expOutput[i] = math.exp(input[i] - maxValue)
        sumOf = sumOf + expOutput[i]
    end

    --console.log(sumOf)

    for i = 1, #expOutput, 1 do
        output[i] = expOutput[i] / sumOf
    end
    return output
end

--FUNCTIONS--

function reset(population, isAtBegining)

    if isAtBegining then
        console.log("Can't advance with this configuration...\nCreating brand new pop...")
        return newPopulation()
    end

    GENRATION = GENRATION + 1

    return nextGen(population)
end

function nextGen(population)
    local newPop = newEmptyPopulation()
    local bestIndex = 0
    local bestFitness = 0

    for i = 1, #population.pop, 1 do
        if bestFitness < population.pop[i].fitness then
            bestFitness = population.pop[i].fitness
            bestIndex = i
        end
    end

    local bestNetwork = population.pop[bestIndex]
    newPop.pop[1] = bestNetwork

    math.randomseed(os.time())
    for i = 2, POPULATION_SIZE, 1 do
        newPop.pop[i] = changeBiasesAndWeight(bestNetwork, 2, 0.5)
    end

    return newPop
end

function changeBiasesAndWeight(network, biasesRange, weightRange) -- Use to applied edit on vector
    local updatedNetwork = newNetwork()
    
    if network.layers == {} then
        for l = 1, #network.layer, 1 do
            for i = 1, #network.layer[l].biases, 1 do
                local sign = math.random(0, 1)
                if sign == 0 then sign = - 1 end
                
                updatedNetwork.layer[l].biases[i] = network.layer[l].biases[i] + ((math.random(1, 100) * 0.01 * biasesRange) * sign)
            end
        end
        for l = 1,#network.layer, 1 do
            for i = 1, #network.layer[l].weigth, 1 do
                for j = 1, #network.layer[l].weigth[i], 1 do
                    local sign = math.random(0, 1)
                    if sign == 0 then sign = - 1 end

                    updatedNetwork.layer[l].weigth[i][j] = network.layer[l].weigth[i][j] + ((math.random(1, 100) * 0.01 * weightRange) * sign)
                end
            end
        end
    end
    updatedNetwork.outputLayer = newLayer(8, WIDTH_INPUTS * HEIGHT_INPUTS)
    for i = 1, #network.outputLayer.weigth, 1 do
        for j = 1, #network.outputLayer.weigth[i], 1 do
            local sign = math.random(0, 1)
            if sign == 0 then sign = -1 end
            updatedNetwork.outputLayer.weigth[i][j] = network.outputLayer.weigth[i][j] + ((math.random(1, 100) * 0.01 * weightRange) * sign)
         end
    end

    return updatedNetwork
    
end

function outputToControl(input) --* used to convert output layer into controller input
    local controlOutputs = {}
    for i = 1, NBRE_OUTPUT, 1 do
        controlOutputs[CONTROLER_INPUT[i].name] = (input[i] > NEURONS_SENSITIVITY) -- Chesk if the output must be turned on
    end

    if controlOutputs["P1 Left"] and controlOutputs["P1 Right"] then
		controlOutputs["P1 Left"] = false
	end

    return controlOutputs
end

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
            if output[i] > NEURONS_SENSITIVITY then
                color = "white"
            end
            gui.drawRectangle(X_OUTPUT_ANCHOR, Y_OUTPUT_ANCHOR + (i * SIZE_HEIGTH_OUTPUT), SIZE_WIDTH_OUTPUT, SIZE_HEIGTH_OUTPUT, "black", color)
            gui.drawString(X_OUTPUT_ANCHOR + SIZE_WIDTH_OUTPUT, Y_OUTPUT_ANCHOR + i * SIZE_HEIGTH_OUTPUT, CONTROLER_INPUT_STR[i], "black", "white", 10, "Arial")
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

function getInputs() --Get tiles and sprites position
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
    return inputs
end

--VARIABLES--

local population = newPopulation()
local currentBeing = 1 

NEURONS_SENSITIVITY = 0.3

local lastFramFitness = 0
local fitness = 0
local maxFitness = 0

local staticFrames = 0

--SCRIPT--
math.randomseed(os.time())

console.log('AI STARTED')
console.log(os.clock())
savestate.load(NOM_STATE)

while true do
    staticFrames = staticFrames + 1
    local currentNetwork = population.pop[currentBeing]
    local mario = memory.read_s16_le(0x94);
    if mario > fitness then
        fitness = mario
    end
    if fitness > lastFramFitness then
        staticFrames = 0
    end

    gui.text(20, 10, "Max fitness : " .. population.maxFitness)
    gui.text(20, 30, "Current fitness : " .. mario)
    gui.text(20, 50, "Which individual : " .. currentBeing)
    gui.text(20, 70, "Gen : " .. GENRATION)
    gui.text(20, 90, "Static frame count : " .. staticFrames)
    
    --gui.drawRectangle(X_NEURON_ANCHOR, Y_NEURON_ANCHOR, NEURON_DISPLAY_SIZE, NEURON_DISPLAY_SIZE, "black", "white")
    currentNetwork.input = getInputs()
    drawInput(currentNetwork.input)

    local output = getActivationOutput(currentNetwork)
    --console.log(NETWORK.output)
    --console.log(table.concat(output, ", "))
    --console.log(sum(NETWORK.output))
    --console.log(table.concat(NETWORK.input, ", "))
    
    local inp = {}
    joypad.set(outputToControl(output))
    drawOutput(output)

    lastFramFitness = fitness

    emu.frameadvance()

    if memory.readbyte(0x13E0) == 62 or staticFrames >= MAX_STATIC_FRAMES then
        savestate.load(NOM_STATE)
        staticFrames = 0
        population.pop[currentBeing].fitness = fitness
        
        
        if population.maxFitness < fitness then
            population.maxFitness = fitness
        end

        fitness = 0
        lastFramFitness = 0

        if currentBeing < POPULATION_SIZE then
            currentBeing = currentBeing + 1
        else 
            currentBeing = 1
            population = reset(population, (fitness/16)  == 1.0 and (fitness%16) == 0)
        end
    end
end