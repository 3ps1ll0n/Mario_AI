--CONSTANTE--
NOM_STATE = "debut.state"
NOM_FICHIER = "model_mario"

WIDTH_CAMERA = 256
HEIGHT_CAMERA = 224
MAX_SPRITE = 11

WIDTH_INPUTS = 16
HEIGHT_INPUTS = 14
TILE_SIZE = 16
VIEW_WIDTH = WIDTH_INPUTS * TILE_SIZE
VIEW_HEIGHT = HEIGHT_INPUTS * TILE_SIZE

MAX_NEURONS_ON_LAYER = 30
POPULATION_SIZE = 50
GENRATION = 0

NEURON_DISPLAY_SIZE = 4 
X_NEURON_ANCHOR = 50
Y_NEURON_ANCHOR = 25

SIZE_WIDTH_OUTPUT = 20
SIZE_HEIGTH_OUTPUT = 10
X_OUTPUT_ANCHOR = 200
Y_OUTPUT_ANCHOR = 10
X_HIDEN_ANCHOR = 120
Y_HIDEN_ANCHOR = 5

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

MAX_STATIC_FRAMES = 90
ABSOLUTE_MAX_FINTESS = 0
NO_UPGRADES_CYCLE = 0
MAX_NO_UPGRADES_CYCLE = 1000
FITNESS_WHEN_LEVEL_IS_COMPLETE = 100000
PLAYED_FRAME = 0

--CLASSES--

--CONSTRUCTOR--

function newEmptyPopulation()
    local p = {}
    p.currentGen = 0;
    p.pop = {}
    p.maxFitness = 0

    return p
end

function newAdvancedPopulation(neurons)
    local p = newPopulation()

    for i = 1, #p.pop, 1 do
        for j = 1, neurons, 1 do
            p.pop[i] = addNeurons(p.pop[i])
        end
    end
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
        l.weigth[i] = generateRandomWeigths(nbreInput)
    end
    --if #l.biases == #l.weigth then console.log("THIS LAYER IS OK") end
    return l
end

function generateRandomWeigths(amount)
    local weights = {}
    for i = 1, amount, 1 do
        weights[i] = (math.random(1, 100) * 0.01) * generateRandomSign()
    end

    return weights
    
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

    network.output = sigmoid(forward(currentInput, network.outputLayer.biases, network.outputLayer.weigth))

    --console.log(#network.output)

    return  network.output
    
end

--MATH_FUNCTION--

function generateRandomSign()
    local sign = math.random(0, 1)
    if sign == 0 then
        sign = -1
    end

    return sign
end

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

function sigmoid(input)
    local output = {}

    for i = 1, #input, 1 do
        output[i] = 1/(1 + math.exp(-input[i]))
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

function  countWeight(network)
    local nbre = 0

    for l = 1, #network.layers do
        for i = 1, #network.layers[l].weigth, 1 do
            for j = 1, #network.layers[l].weigth[i], 1 do
                nbre = nbre + 1
            end
        end
    end

    for i = 1, #network.outputLayer.weigth, 1 do
        for j = 1, #network.outputLayer.weigth[i] do
            nbre = nbre + 1
        end
    end
    return nbre
end

function countBiases(network)
    local nbre = 0

    for l = 1, #network.layers do
        for i = 1, #network.layers[l].biases, 1 do
            nbre = nbre + 1
        end
    end

    for i = 1, #network.outputLayer.biases, 1 do
        nbre = nbre + 1
    end


    return nbre
end

function isLevelComplete()
    local value = 0
    if memory.readbyte(0x0100) == 0x0C then
        console.log("level complete !")
        value = FITNESS_WHEN_LEVEL_IS_COMPLETE + (400 * 30 - PLAYED_FRAME)
    end
    return value
end

function reset(population, isAtBegining)
    
    if isAtBegining then
        console.log("Can't advance with this configuration...\nCreating brand new pop...")
        return newPopulation()
    end

    saveModel(population)

    GENRATION = GENRATION + 1

    return nextGen(population)
end

function nextGen(population)
    local newPop = newEmptyPopulation()
    local bestIndex = 0
    local bestFitness = 0
    local isNeuronBeenAdded = false
    for i = 1, #population.pop, 1 do
        if bestFitness < population.pop[i].fitness then
            bestFitness = population.pop[i].fitness
            bestIndex = i
        end
    end

    local bestNetwork = population.pop[bestIndex]

    if ABSOLUTE_MAX_FINTESS >= bestFitness then NO_UPGRADES_CYCLE = NO_UPGRADES_CYCLE + 1
    else 
        ABSOLUTE_MAX_FINTESS = bestFitness
        NO_UPGRADES_CYCLE = 0
    end
    if NO_UPGRADES_CYCLE >= MAX_NO_UPGRADES_CYCLE then 
        bestNetwork = addNeurons(bestNetwork)
        isNeuronBeenAdded = true
        NO_UPGRADES_CYCLE = 0
    end

    newPop.pop[1] = bestNetwork

    math.randomseed(os.time())
    if isNeuronBeenAdded then
        for i = 2, POPULATION_SIZE, 1 do
            if i <= POPULATION_SIZE/2 then newPop.pop[i] = changeBiasesAndWeight(bestNetwork, 2, 0.5)
            else newPop.pop[i] = changeBiasesAndWeight(bestNetwork, 5, 4) end
        end
    else 
        for i = 2, POPULATION_SIZE, 1 do
            if math.random() <= 0.100 then newPop.pop[i] = changeBiasesAndWeight(mergeBiasesAndWeigth(bestNetwork, population.pop[i]), 0.5, 0.5)
            elseif  math.random() <= 0.100 then newPop.pop[i] = changeBiasesAndWeight(bestNetwork, 0.5, 0.5)
            --elseif i <= POPULATION_SIZE/2 then newPop.pop[i] = changeBiasesAndWeight(bestNetwork, 5, 4)
            --elseif i <= POPULATION_SIZE/(3/4) then newPop.pop[i] = mergeBiasesAndWeigth(bestNetwork, population.pop[i])
            else newPop.pop[i] = mergeBiasesAndWeigth(bestNetwork, population.pop[i]) end
        end
    end
    return newPop
end

function addNeurons(network)
    gui.addmessage("Creating neuron...")
    if #network.layers == 0 then --IF THERE IS NO EXISTING LAYER
        gui.addmessage("FIRST NEURON...")
        network.layers[1] = newLayer(1, WIDTH_INPUTS * HEIGHT_INPUTS)
        network.layers[1].biases[1] = (math.random(1, 100) * 0.005) * generateRandomSign()
        for i = 1, #network.outputLayer.weigth, 1 do
            local summation = sum(network.outputLayer.weigth[i])
            local entryNumbers = #network.outputLayer.weigth[i]
            network.outputLayer.weigth[i] =  {summation / entryNumbers}  --Merging existing weight
        end
    elseif #network.layers[1].biases >= MAX_NEURONS_ON_LAYER then --IF A LAYER IS FULL, CREATE AN OTHER
        table.insert(network.layers, 1, newLayer(1, WIDTH_INPUTS * HEIGHT_INPUTS))
        network.layers[1].biases[1] = math.random() * generateRandomSign()
        for i = 1, #network.layers[2].weigth, 1 do
            network.layers[2].weigth[i] = {sum(network.layers[2].weigth[i]) / #network.layers[2].weigth[i]}
        end
    else
        table.insert(network.layers[1].biases, math.random() * generateRandomSign()) -- new neuron
        table.insert(network.layers[1].weigth, generateRandomWeigths(WIDTH_INPUTS * HEIGHT_INPUTS)) -- new connections to Input

        if #network.layers == 1 then
            for i = 1, #network.outputLayer.weigth, 1 do
                table.insert(network.outputLayer.weigth[i], math.random() * generateRandomSign())
            end
        else
            for i = 1, #network.layers[2].weigth, 1 do
                table.insert(network.layers[2].weigth[i], math.random() * generateRandomSign())
            end
        end
    end

    for i = 1, #network.layers, 1 do -- CHECK IF THE LAYERS ARE VALID
        if #network.layers[i].biases ~= #network.layers[i].weigth then gui.addmessage("NOT VALID LAYER : unvalid connection") end
        if i == 1 then
            if #network.layers[i].weigth[1] ~= WIDTH_INPUTS * HEIGHT_INPUTS then gui.addmessage("NOT VALID LAYER : wrong input size") end
        else
            if  #network.layers[i].weigth[1] ~= #network.layers[i - 1].biases then gui.addmessage("NOT VALID LAYER : not rightly connected") end
        end
    end
    if #network.outputLayer.biases ~= #network.outputLayer.weigth then gui.addmessage("NOT VALID OUPUT LAYER") end
    --END OF VERIFICATION 
    gui.addmessage("New neuron created...")
    return network
end

function mergeBiasesAndWeigth(bestNetwork, network)
    local updatedNetwork = newNetwork()
    local percentOfBest = (network.fitness/bestNetwork.fitness) * 0.4
    if #network.layers ~= 0 then
        for l = 1, #network.layers, 1 do
            updatedNetwork.layers[l]  = newEmptyLayer()
            for i = 1, #network.layers[l].weigth, 1 do
                updatedNetwork.layers[l].weigth[i] = {}
                if math.random(0, 1000) <= 1 then  updatedNetwork.layers[l].biases[i] = math.random() * generateRandomSign()
                elseif math.random() <= percentOfBest then updatedNetwork.layers[l].biases[i] = network.layers[l].biases[i]
                else updatedNetwork.layers[l].biases[i] = bestNetwork.layers[l].biases[i]
                end
                for j = 1, #network.layers[l].weigth[i], 1 do
                    if math.random(0, 1000) <= 1 then updatedNetwork.layers[l].weigth[i][j] = math.random()  * generateRandomSign()
                    elseif math.random() <= percentOfBest then updatedNetwork.layers[l].weigth[i][j] = network.layers[l].weigth[i][j]
                    else updatedNetwork.layers[l].weigth[i][j] = bestNetwork.layers[l].weigth[i][j]
                    end
                end
            end
        end
    end
    updatedNetwork.outputLayer = newEmptyLayer()
    for i = 1, #network.outputLayer.weigth, 1 do
        updatedNetwork.outputLayer.weigth[i] = {}
        --if math.random(0, 100) <= 1 then  updatedNetwork.outputLayer.biases[i] = math.random() * generateRandomSign()
        --elseif math.random() <= percentOfBest then updatedNetwork.outputLayer.biases[i] = network.outputLayer.biases[i]
        --else updatedNetwork.outputLayer.biases[i] = bestNetwork.outputLayer.biases[i]
        --end
        updatedNetwork.outputLayer.biases[i] = 0
        for j = 1, #network.outputLayer.weigth[i], 1 do
            if math.random(0, 100) <= 1 then  updatedNetwork.outputLayer.weigth[i][j] = math.random() * generateRandomSign()
            elseif math.random() <= percentOfBest then updatedNetwork.outputLayer.weigth[i][j] = network.outputLayer.weigth[i][j]
            else updatedNetwork.outputLayer.weigth[i][j] = bestNetwork.outputLayer.weigth[i][j]
            end
        end
    end

    return updatedNetwork
end

function changeBiasesAndWeight(network, biasesRange, weightRange) -- Use to applied edit on vector
    local updatedNetwork = newNetwork()
    
    if #network.layers ~= 0 then
        for l = 1, #network.layers, 1 do
            updatedNetwork.layers[l]  = newEmptyLayer()
            for i = 1, #network.layers[l].biases, 1 do
                local mustBeRandomlyChanged = math.random()
                if mustBeRandomlyChanged <= 0.005 then
                    updatedNetwork.layers[l].biases[i] = (math.random(1, 100) * 0.01) * generateRandomSign()
                elseif mustBeRandomlyChanged < 0.001 then 
                    updatedNetwork.layers[l].biases[i] = network.layers[l].biases[i] + ((math.random(1, 100) * 0.01 * biasesRange) * generateRandomSign())
                else updatedNetwork.layers[l].biases[i] = network.layers[l].biases[i]
                end
            end
        end
        for l = 1,#network.layers, 1 do
            for i = 1, #network.layers[l].weigth, 1 do
                updatedNetwork.layers[l].weigth[i] = {}
                for j = 1, #network.layers[l].weigth[i], 1 do
                    local mustBeRandomlyChanged = math.random()
                    if mustBeRandomlyChanged <= 0.005 then
                        updatedNetwork.layers[l].weigth[i][j] = (math.random(1, 100) * 0.01) * generateRandomSign()
                    elseif mustBeRandomlyChanged < 0.001 then 
                        updatedNetwork.layers[l].weigth[i][j] = network.layers[l].weigth[i][j] + ((math.random(1, 100) * 0.01 * weightRange) * generateRandomSign())
                    else updatedNetwork.layers[l].weigth[i][j] = network.layers[l].weigth[i][j]
                    end
                end
            end
        end
    end
    updatedNetwork.outputLayer = newEmptyLayer()
    for i = 1, #network.outputLayer.weigth, 1 do
        updatedNetwork.outputLayer.weigth[i] = {}
        updatedNetwork.outputLayer.biases[i] = 0
        for j = 1, #network.outputLayer.weigth[i], 1 do
            local mustBeRandomlyChanged = math.random()

            if mustBeRandomlyChanged <= 0.100 then
                updatedNetwork.outputLayer.weigth[i][j] = (math.random(1, 100) * 0.005) * generateRandomSign()
            elseif mustBeRandomlyChanged < 0.250 then 
                updatedNetwork.outputLayer.weigth[i][j] = network.outputLayer.weigth[i][j] + ((math.random(1, 100) * 0.01 * weightRange) * generateRandomSign())
            else updatedNetwork.outputLayer.weigth[i][j] = network.outputLayer.weigth[i][j]
            end
            
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

function drawHiden(hidenLayers)
    if hidenLayers[1] == nil then return end

    for i = 1, #hidenLayers, 1 do
        for j = 1, #hidenLayers[i].biases, 1 do
            gui.drawRectangle(
                            X_HIDEN_ANCHOR + (((j - 1) % (MAX_NEURONS_ON_LAYER/2)) * NEURON_DISPLAY_SIZE ),
                            Y_HIDEN_ANCHOR + ( (math.floor((j - 1)/(MAX_NEURONS_ON_LAYER/2))) * (NEURON_DISPLAY_SIZE)) + ((i - 1) * 3 * NEURON_DISPLAY_SIZE),
                            NEURON_DISPLAY_SIZE,
                            NEURON_DISPLAY_SIZE,
                            "black",
                            "white"
                        )
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

--SAVING_FILES_MANAGER--

function serialize (o) --(https://www.lua.org/pil/12.1.html)
    if type(o) == "number" then
      io.write(o)
    elseif type(o) == "string" then
      io.write(string.format("%q", o))
    elseif type(o) == "table" then
      io.write("{\n")
      for k,v in pairs(o) do
        io.write("  [")
        serialize(k)
        io.write("] = ")
        serialize(v)
        io.write(",\n")
      end
      io.write("}\n")
    else
      error("cannot serialize a " .. type(o))
    end
  end
function file_exists(name)
    local f = io.open(name, "r")
    return f ~= nil and io.close(f)
end  

local function exportstring( s )
    return string.format("%q", s)
 end

function table.save(  tbl,filename ) --(http://lua-users.org/wiki/SaveTableToFile)
    local charS,charE = "   ","\n"
    local file,err = io.open( filename, "wb" )
    if err then return err end

    -- initiate variables for save procedure
    local tables,lookup = { tbl },{ [tbl] = 1 }
    file:write( "return {"..charE )

    for idx,t in ipairs( tables ) do
       file:write( "-- Table: {"..idx.."}"..charE )
       file:write( "{"..charE )
       local thandled = {}

       for i,v in ipairs( t ) do
          thandled[i] = true
          local stype = type( v )
          -- only handle value
          if stype == "table" then
             if not lookup[v] then
                table.insert( tables, v )
                lookup[v] = #tables
             end
             file:write( charS.."{"..lookup[v].."},"..charE )
          elseif stype == "string" then
             file:write(  charS..exportstring( v )..","..charE )
          elseif stype == "number" then
             file:write(  charS..tostring( v )..","..charE )
          end
       end

        for i,v in pairs( t ) do
          -- escape handled values
            if (not thandled[i]) then
          
            local str = ""
            local stype = type( i )
             -- handle index
             if stype == "table" then
                if not lookup[i] then
                   table.insert( tables,i )
                   lookup[i] = #tables
                end
                str = charS.."[{"..lookup[i].."}]="
             elseif stype == "string" then
                str = charS.."["..exportstring( i ).."]="
             elseif stype == "number" then
                str = charS.."["..tostring( i ).."]="
             end
          
             if str ~= "" then
                stype = type( v )
                -- handle value
                if stype == "table" then
                   if not lookup[v] then
                      table.insert( tables,v )
                      lookup[v] = #tables
                   end
                   file:write( str.."{"..lookup[v].."},"..charE )
                elseif stype == "string" then
                   file:write( str..exportstring( v )..","..charE )
                elseif stype == "number" then
                   file:write( str..tostring( v )..","..charE )
                end
             end
          end
       end
       file:write( "},"..charE )
    end
    file:write( "}" )
    file:close()
 end
 
 --// The Load Function
 function table.load( sfile )  --(http://lua-users.org/wiki/SaveTableToFile)
    local ftables,err = loadfile( sfile )
    if err then return _,err end
    local tables = ftables()
    for idx = 1,#tables do
       local tolinki = {}
       for i,v in pairs( tables[idx] ) do
          if type( v ) == "table" then
             tables[idx][i] = tables[v[1]]
          end
          if type( i ) == "table" and tables[i[1]] then
             table.insert( tolinki,{ i,tables[i[1]] } )
          end
       end
       -- link indices
       for _,v in ipairs( tolinki ) do
          tables[idx][v[2]],tables[idx][v[1]] =  tables[idx][v[1]],nil
       end
    end
    return tables[1]
 end

function readModel() --! TO DO ASAP @3ps1ll0n
    console.log(" : " .. NOM_FICHIER .. ".pop")
    return table.load(NOM_FICHIER .. ".pop")
end

function saveModel(population) --! TO DO ASAP @3ps1ll0n
    table.save(population, NOM_FICHIER .. ".pop")
end

--VARIABLES--

local population = newAdvancedPopulation(90)
local currentBeing = 1 

NEURONS_SENSITIVITY = 0.5

local lastFramFitness = 0
local fitness = 0
local maxIndiv = 0

local staticFrames = 0

--SCRIPT--
math.randomseed(os.time())

console.log('AI STARTED')
--console.log(os.clock())
savestate.load(NOM_STATE)
if file_exists(NOM_FICHIER .. ".pop") then 
    population = readModel()
    GENRATION = population.currentGen
end

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
    gui.text(20, 110, "NO_UPGRADES_CYCLE : " .. NO_UPGRADES_CYCLE)
    gui.text(20, 130, "Biases : " .. countBiases(currentNetwork) .. "; Weight : " .. countWeight(currentNetwork) .. "; Input : " .. WIDTH_INPUTS * HEIGHT_INPUTS)
    gui.text(20, 150, "Pot Max Fitness : " .. FITNESS_WHEN_LEVEL_IS_COMPLETE + (400 * 30 - PLAYED_FRAME))
    --gui.drawRectangle(X_NEURON_ANCHOR, Y_NEURON_ANCHOR, NEURON_DISPLAY_SIZE, NEURON_DISPLAY_SIZE, "black", "white")
    currentNetwork.input = getInputs()
    drawInput(currentNetwork.input)

    local output = getActivationOutput(currentNetwork)
    --console.log(NETWORK.output)
    --console.log(table.concat(output, ", "))
    --console.log(sum(NETWORK.output))
    --console.log(table.concat(NETWORK.input, ", "))
    
    joypad.set(outputToControl(output))
    drawOutput(output)
    drawHiden(currentNetwork.layers)

    lastFramFitness = fitness

    emu.frameadvance()
    PLAYED_FRAME = PLAYED_FRAME + 1

    local lvlComplete = isLevelComplete()

    if memory.readbyte(0x13E0) == 62 or staticFrames >= MAX_STATIC_FRAMES or lvlComplete > 0 then
        savestate.load(NOM_STATE)
        staticFrames = 0
        if population.pop[currentBeing].fitness < fitness then population.pop[currentBeing].fitness = fitness end
        population.currentGen = GENRATION;
        if lvlComplete > 0 then population.pop[currentBeing].fitness = lvlComplete end
        if population.maxFitness < population.pop[currentBeing].fitness then 
            population.maxFitness = population.pop[currentBeing].fitness
        end

        fitness = 0
        lastFramFitness = 0
        PLAYED_FRAME = 0

        if currentBeing < POPULATION_SIZE then
            currentBeing = currentBeing + 1
        else 
            currentBeing = 1
            population = reset(population, (fitness/16)  == 1.0 and (fitness%16) == 0)
        end
    end
end