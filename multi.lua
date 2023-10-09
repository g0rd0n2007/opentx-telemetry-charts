local timeBetweenSamples = 50 --oznacza co 5 sek
local axisX, axisY = 35, 10



local maxValuesCount = 93
local lcdWidth, lcdHeight = 128, 64    
local graphHeight = lcdHeight - axisY - 1


local Pages = {}
local PageIdx = 1

local function calcPixelY(page, range, v)
    return axisY + (1.0 - ((v - page.min) / range)) * graphHeight
end

local function createGraph(page)
    
    local range = page.max - page.min
    if range <= 0 then
        range = 1
    end

    lcd.drawLine(axisX - 1, axisY - 1, 127, axisY - 1, DOTTED, 0)
    lcd.drawLine(axisX - 1, axisY - 1, axisX - 1, 63, DOTTED, 0)

    if page.max ~= nil then        
        lcd.drawText(0, 10, string.format("%." .. page.prec .. "f", page.max), SMLSIZE)
    end
    if page.mid ~= nil and page.mid ~= math.huge and page.mid ~= page.min and page.mid ~= page.max then
        local y = calcPixelY(page, range, page.mid)
        lcd.drawLine(axisX - 1, y, 127, y, DOTTED, 0)
        --lcd.drawLine(axisX - 1, y, 6, 40, DOTTED, 0)

        lcd.drawText(0, 35, string.format("%." .. page.prec .. "f", page.mid), SMLSIZE)
    end
    if page.min ~= nil and page.min ~= math.huge then 
        lcd.drawText(0, 55, string.format("%." .. page.prec .. "f", page.min), SMLSIZE)
    end




    if page.enabled then
        --local prevX, prevY = nil, nil
        for i, v in ipairs(page.values) do
            local x = axisX + i - 1
            local y1 = calcPixelY(page, range, v.min) --lcdHeight - 1 - ((v - minValue) / range) * graphHeight
            local y2 = calcPixelY(page, range, v.max)

            if page.min <= v.min and v.min <= page.max and page.min <= v.max and v.max <= page.max then
                --if prevX and prevY then
                lcd.drawLine(x, y1, x, y2, SOLID, 0)
                --end
                --lcd.drawPoint(x, y)

                --prevX, prevY = x, y
            end        
        end
    else 
        lcd.drawText(50, 25, "[MNU] - Enable", SMLSIZE)
        lcd.drawText(43, 40, "[OK] - Clear data", SMLSIZE)
    end
    
    
    lcd.drawText(0, 0, string.format("%d/%d %s: %." .. page.prec .. "f", PageIdx, #Pages, page.name, page.currentValue), SMLSIZE)
    --lcd.drawNumber(LCD_W/2, 0, page.values[#page.values].max, SMLSIZE)
    --if page.#values > 0 then
    --    lcd.drawText(70, 0, string.format(page.valueFormat .. " " .. page.valueUnit, values[#values]), SMLSIZE)
    --end
end

local function background()
    local currentTime = getTime()  -- Pobierz aktualny czas w 10ms jednostkach

    for p = 1, #Pages do
        --local p = PageIdx
        local newValue = getValue(Pages[p].name)

        if newValue and type(newValue) == "number" and Pages[p].enabled then
            Pages[p].currentValue = newValue

            --Min/Max całego wykresu
            if  newValue > Pages[p].max then
                Pages[p].max = newValue
            end       
            if  newValue < Pages[p].mid and newValue > 0 then
                Pages[p].mid = newValue
            end
            if  newValue < Pages[p].min then
                Pages[p].min = newValue
            end

            --Min/Max obecnego okresu czasu
            if  newValue > Pages[p].values[#Pages[p].values].max then
                Pages[p].values[#Pages[p].values].max = newValue
            end       
            if  newValue < Pages[p].values[#Pages[p].values].min then
                Pages[p].values[#Pages[p].values].min = newValue
            end

            --
            if (currentTime - Pages[p].lastSampleTime) >= timeBetweenSamples then            
                
                --Save last data point to CSV file on SD card
                if Pages[p].values[#Pages[p].values].min ~= nil and Pages[p].values[#Pages[p].values].max ~= nil then
                    appendToCSV(
                        model.getInfo().name,
                        Pages[p].name, 
                        Pages[p].values[#Pages[p].values].min, 
                        Pages[p].values[#Pages[p].values].max
                    )
                end
                
                if #Pages[p].values >= maxValuesCount then

                    for i = 1, maxValuesCount - 1 do
                        Pages[p].values[i] = Pages[p].values[i + 1]
                    end

                    
                    Pages[p].values[maxValuesCount] = { 
                        min=newValue,
                        max=newValue
                    }
                else
                    
                    Pages[p].values[#Pages[p].values + 1] = {
                        min=newValue,
                        max=newValue
                    }
        
                end
                
                Pages[p].lastSampleTime = currentTime
            end            
        end
    end
end

local function run(event)
    if event == EVT_ENTER_BREAK then
        for p = 1, #Pages do
            Pages[p].values = {
                {
                    min=math.huge,
                    max=0
                }
            }
            Pages[p].min=math.huge
            Pages[p].mid=math.huge
            Pages[p].max=0
            Pages[p].lastSampleTime=0
        end
    elseif event == EVT_MENU_BREAK then
        if Pages[PageIdx].enabled == false then
            Pages[PageIdx].enabled = true
        else
            Pages[PageIdx].enabled = false
            Pages[PageIdx].values={
                {
                    min=math.huge,
                    max=0
                }
            }
        end        
    elseif event == EVT_ROT_RIGHT or event == EVT_MENU_BREAK then--EVT_MENU_BREAK then
        if PageIdx < #Pages then
            PageIdx = PageIdx + 1
        else
            PageIdx = 1
        end
    elseif event == EVT_ROT_LEFT then--or event ==  then--EVT_MENU_LONG then
        if PageIdx > 1 then
            PageIdx = PageIdx - 1
        else
            PageIdx = #Pages
        end
    else
        lcd.clear()
        createGraph(Pages[PageIdx])
    end
end


local function init_func()
 
    local index = 0
    while true do
        local sensor = model.getSensor(index)
        if sensor and sensor.name and sensor.name ~= "" then
            
            Pages[#Pages + 1] = {
                id=index,
                name=sensor.name,
                values={
                    {
                        min=math.huge,
                        max=0
                    }
                },
                min=math.huge,
                mid=math.huge,
                max=0,
                lastSampleTime=0,
                prec=sensor.prec,
                currentValue=0,
                enabled=false
            }            
        else
            break
        end
        index = index + 1
    end
end



local CsvID = 1
function appendToCSV(modelName, sensorName, number1, number2)
    -- Pobierz aktualną datę i godzinę
    local dt = getDateTime()
    
    
    local filename = string.format("/LOGS/%s %s %04d-%02d-%02d.csv", modelName, sensorName, dt.year, dt.mon, dt.day)
    local f = io.open(filename, "a")  -- Otwórz plik w trybie dołączania ("a")

    local txt = string.format("%d:%02d:%02d;%.2f;%.2f\n", dt.hour, dt.min, dt.sec, number1, number2)
    local txt2, n = string.gsub(txt, "%.", ",")
    io.write(f, txt2)
    CsvID = CsvID + 1
    io.close(f)
end

return {
    run = run,
    background = background,
    init = init_func,
    option = option
}

