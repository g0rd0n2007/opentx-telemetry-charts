local sensorName = "Curr"
local valueFormat = "%.1f"--Lipo: 25.20 [V]
local valueUnit = "[A]"
local timeBetweenSamples = 500 --oznacza co 5 sek
local adjustMax = 2 --0-no adjustment, 1-non zero adjustment, 2-full adjustment
local adjustMin = 1 --0-no adjustment, 1-non zero adjustment, 2-full adjustment
local maxValue = 0--6S max
local minValue = 0--6S min
local axisX, axisY = 25, 10



local maxValuesCount = 100
local values = {}
local lastSampleTime = 0




local function createGraph()
    local lcdWidth, lcdHeight = 128, 64    
    local graphWidth, graphHeight = lcdWidth - axisX, lcdHeight - axisY - 1
    
    
    local range = maxValue - minValue
    if range <= 0 then
        range = 1
    end

    lcd.drawLine(axisX - 1, axisY - 1, 127, axisY - 1, DOTTED, 0)
    lcd.drawLine(axisX - 1, axisY - 1, axisX - 1, 63, DOTTED, 0)
    
    local prevX, prevY = nil, nil
    for i, v in ipairs(values) do
        local x = axisX + i - 1
        local y = axisY + (1.0 - ((v - minValue) / range)) * graphHeight --lcdHeight - 1 - ((v - minValue) / range) * graphHeight

        if minValue <= v and v <= maxValue then
            if prevX and prevY then
                lcd.drawLine(prevX, prevY, prevX, y, SOLID, 0)
            end
            --lcd.drawPoint(x, y)

            prevX, prevY = x, y
        end      
    end
end

local function background()
    local currentTime = getTime()  -- Pobierz aktualny czas w 10ms jednostkach

    local newValue = getValue(sensorName)

    if newValue and type(newValue) == "number" then

        if  newValue > maxValue and
            ( 
                (adjustMax == 1 and newValue ~= 0) or--non zero adjustment
                (adjustMax == 2)--full adjustment 
            )
        then
            maxValue = newValue
        end       

        if  newValue < minValue and 
            (
                (adjustMin == 1 and newValue ~= 0) or--non zero adjustment
                (adjustMin == 2)--full adjustment 
            )
        then
            minValue = newValue
        end

        if currentTime - lastSampleTime >= timeBetweenSamples then            
            if #values >= maxValuesCount then
                for i = 1, maxValuesCount - 1 do
                    values[i] = values[i + 1]
                end
                values[maxValuesCount] = newValue
            else
                values[#values + 1] = newValue
            end
            lastSampleTime = currentTime
        end
    end
end

local function run(event)
    if event == EVT_ENTER_LONG then
        values = {}
    else
        lcd.clear()
        createGraph()
    
        if maxValue ~= nil then
            lcd.drawText(0, 15, string.format(valueFormat, maxValue), SMLSIZE)
        end
        
        if minValue ~= nil then 
            lcd.drawText(0, 55, string.format(valueFormat, minValue), SMLSIZE)
        end
        
        if #values > 0 then
            lcd.drawText(40, 0, string.format("%s: " .. valueFormat .. " " .. valueUnit, sensorName, values[#values]), SMLSIZE)
        end
    end
end

local function getSensorByName(sensorName)
    local index = 0
    while true do
        local sensor = model.getSensor(index)
        if sensor then
            if sensor.name == sensorName then
                return sensor
            end
        else
            break
        end
        index = index + 1
    end
    return nil
end


local function init_func()
    local sensor = getSensorByName(sensorName)
end

return {
    run = run,
    background = background,
    init = init_func,
    option = option
}

