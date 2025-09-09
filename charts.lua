local timeBetweenSamples = 500 --100 -> 1[sec]

local maxValuesCount = 95
local lcdWidth, lcdHeight = 128, 64    
local axisX, axisY = 30, 10
local graphWidth, graphHeight = 97, 53

local Pages = {}
local PageIdx = 1
local lastSampleTime = 0
local settings_file = "/SCRIPTS/TELEMETRY/settings.txt"

local function calcChartY(page, range, v)    
    return axisY + graphHeight - 2 - (v - page.min) * (graphHeight - 3) / range
end

local Units={"", "V", "A", "mA", "knt", "mps", "fps", "kph", "mph", "m", "ft", "*C", "*F", "%", "mAh", "W", "mW", "dB", "RPM", "G", "deg", "rad", "mL", "fo", "mLpm", "h", "m", "s", "", "", "", "", ""};

local function createGraph(page)
    --Full list: https://doc.open-tx.org/opentx-2-3-lua-reference-guide/part_vii_-_appendix/units
    local unit=Units[page.unit+1];
        
    lcd.drawText(1, 1, string.format("%s: %." .. page.prec .. "f [%s]", page.name, page.currentValue, unit), SMLSIZE)
    lcd.drawText(lcdWidth - 20, 1, string.format("%d/%d", PageIdx, #Pages), SMLSIZE)
    
    local range = page.max - page.min
    if range <= 0.0 then
        range = 0.01
        page.max = page.min + 0.01
    end

    lcd.drawRectangle(axisX, axisY, graphWidth, graphHeight, SOLID)

    -- Max
    if page.max and page.max ~= math.huge then        
        lcd.drawText(1, axisY, string.format("%." .. page.prec .. "f", page.max), SMLSIZE)
    end    

    -- Cursor value
    if page.min and page.max and page.max ~= math.huge then
        local vc = (page.values[page.cursor].max + page.values[page.cursor].min) / 2
        local yc = calcChartY(page, range, vc) 
        if yc < axisY + 15 then yc = axisY + 15 end
        if yc > axisY + graphHeight - 12 then yc = axisY + graphHeight - 12 end
        lcd.drawText(
            1, 
            yc - 5, 
            string.format("%." .. page.prec .. "f", vc), 
            SMLSIZE
        )
    end

    -- Min
    if page.min and page.min ~= math.huge then 
        lcd.drawText(1, axisY + graphHeight - 7, string.format("%." .. page.prec .. "f", page.min), SMLSIZE)
    end




    if page.enabled == 1 then
        for i, v in ipairs(page.values) do
            if v and v.min and v.max and v.min <= v.max then
                local x = axisX + i - page.offset            
                local y1 = calcChartY(page, range, v.min) --axisY + graphHeight - 2 - (v.max - page.min) * (graphHeight - 3) / range
                local y2 = calcChartY(page, range, v.max) --axisY + graphHeight - 2 - (v.min - page.min) * (graphHeight - 3) / range

                if axisX < x and x < axisX + graphWidth then
                    lcd.drawLine(x, y1, x, y2, SOLID, 0)
                end            
            end
        end

        -- Cursor
        local xc = axisX + page.cursor - page.offset
        if axisX < xc and xc < axisX + graphWidth then
            lcd.drawLine(xc, axisY + 1, xc, axisY + graphHeight - 3, DOTTED, 0)
        end     
    else 
        lcd.drawText(axisX + graphWidth / 2 - 5, axisY + 5, "[OK]", SMLSIZE)
        lcd.drawText(axisX + graphWidth / 2 - 31, axisY + 15, "Enable/Disable", SMLSIZE)
        --lcd.drawText(axisX + graphWidth / 2 - 22,  axisY + 30, "[MNU-LONG]", SMLSIZE)
        --lcd.drawText(axisX + graphWidth / 2 - 22,  axisY + 40, "Clear data", SMLSIZE)
        lcd.drawText(axisX + graphWidth / 2 - 9,  axisY + 30, "[MNU]", SMLSIZE)
        lcd.drawText(axisX + graphWidth / 2 - 25,  axisY + 40, "Next sensor", SMLSIZE)
    end
    
    
end

local function background()
    local currentTime = getTime()  -- Pobierz aktualny czas w 10ms jednostkach

    local next_sample = (currentTime - lastSampleTime) >= timeBetweenSamples
    if next_sample then lastSampleTime = currentTime end

    for p = 1, #Pages do
        local newValue = getValue(Pages[p].name)

        if newValue and type(newValue) == "number" and Pages[p].enabled == 1 then
            Pages[p].currentValue = newValue

            --Min/Max całego wykresu
            if  newValue > Pages[p].max then
                Pages[p].max = newValue
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

            
            if next_sample then            
                
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
                    if Pages[p].cursor == #Pages[p].values - 1 then
                        Pages[p].cursor = Pages[p].cursor + 1
                    end

                    if #Pages[p].values > (graphWidth - 2) then 
                        Pages[p].offset = #Pages[p].values - (graphWidth - 2)
                    end
        
                end

                
            end            
        end
    end
end

local function run(event)

    --[[if #Pages == 0 then 
        message("No sensors")
        return
    end]]--
    --EVT_MENU_LONG
    --EVT_ENTER_BREAK
    --EVT_ROT_RIGHT
    --EVT_ROT_LEFT

    --[[if event == EVT_MENU_LONG then
        --Clear data
        for p = 1, #Pages do
            Pages[p].values = {
                {
                    min=math.huge,
                    max=0
                }
            }
            Pages[p].min=math.huge            
            Pages[p].max=0
            Pages[p].lastSampleTime=0
        end
    else]]--
    if event == EVT_ENTER_BREAK then
        -- Enable/Disable
        if Pages[PageIdx].enabled == 0 then
            Pages[PageIdx].enabled = 1
            Pages[PageIdx].cursor = 1
            Pages[PageIdx].values={
                {
                    min=math.huge,
                    max=0
                }
            }
            Pages[PageIdx].min = math.huge
            Pages[PageIdx].max = 0
        else
            Pages[PageIdx].enabled = 0            
        end       
        saveSettings() 
    elseif event == EVT_MENU_BREAK then
        -- Page right
        if PageIdx < #Pages then
            PageIdx = PageIdx + 1
        else
            PageIdx = 1
        end
    --[[elseif event == EVT_ROT_LEFT then
        -- Page left
        if PageIdx > 1 then
            PageIdx = PageIdx - 1
        else
            PageIdx = #Pages
        end]]--
    elseif event == EVT_ROT_RIGHT then
        -- Cursor right
        if Pages[PageIdx].cursor < #Pages[PageIdx].values then
            Pages[PageIdx].cursor = Pages[PageIdx].cursor + 1        
        end
    elseif event == EVT_ROT_LEFT then
        -- Cursor left
        if Pages[PageIdx].cursor > 1 then
            Pages[PageIdx].cursor = Pages[PageIdx].cursor - 1        
        end
    else
        if #Pages > 0 then
            lcd.clear()
            createGraph(Pages[PageIdx]) 
        else
            message("No sensors")
        end
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
                max=0,                
                prec=sensor.prec,
                currentValue=0,
                enabled=0,
                unit=sensor.unit,
                offset=0,
                cursor=1
            }            
        else
            break
        end
        index = index + 1
    end

    currentTime = getTime()
    readSettings()
end



function readSettings()
    local updates={}
    local line
    

    f = io.open(settings_file, "r")
    if not f then
        f = io.open(settings_file, "w")
        if f then io.close(f) end        
        f = io.open(settings_file, "r")
    end

    if f then
        repeat
            line = io.read(f, 64)
            if line then
                local key, value = string.match(line, "([%w]+)%s*=([%w]+)")
                if key and value then
                    updates[key] = value
                    --lcd.drawText(0, 50, string.format("%s : %s", key, value), SMLSIZE) 
                    
                end
            end
        until string.len(line) == 0
        io.close(f)

        -- Aktualizuj Pages na podstawie odczytanych danych
        for _, page in ipairs(Pages) do
            if updates[page.name] ~= nil then
                page.enabled = tonumber(updates[page.name])
            end
        end
    end
end

function saveSettings()
    local f = io.open(settings_file, "w")
    if f then        
        for key, value in pairs(Pages) do
            io.write(f, string.format("%-10s=%d\n", value.name, value.enabled))
        end
        io.close(f)
    end
end

function message(text)
    lcd.clear()
    lcd.drawRectangle(10, 10, lcdWidth - 20, lcdHeight - 20, SOLID)
    lcd.drawText(lcdWidth / 2 - 5 * #text / 2, lcdHeight / 2 - 5, text, MDLSIZE)
end

return {
    run = run,
    background = background,
    init = init_func,
    option = option
}

