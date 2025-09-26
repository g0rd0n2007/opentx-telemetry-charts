local options = {  
  { "Source1", SOURCE, 0 },
  { "Source2", SOURCE, 0 },
  { "Source3", SOURCE, 0 },
  { "Source4", SOURCE, 0 },
  { "Color1", COLOR, GREEN },
  { "Color2", COLOR, BLUE },
  { "Color3", COLOR, YELLOW },
  { "Color4", COLOR, RED },
  { "MaxSamples", VALUE, 100, 50, 500 },
  { "Time", VALUE, 100, 10, 500 }
}

local history = { {}, {}, {}, {} }
local minmax = { {min = 0, max = 0}, {min = 0, max = 0}, {min = 0, max = 0}, {min = 0, max = 0} }
local names = { "S1", "S2", "S3", "S4" }
local units = { "", "", "", "" }
local prec = { 0, 0, 0, 0 }

local function create(zone, options)
  local widget = {
    zone = zone,
    options = options,
    tick = 0,
    lastUpdate = 0    
  }
  return widget
end

local function update(widget, options)
  widget.options = options
  history = { {}, {}, {}, {} }
  minmax = { {min = 0, max = 0}, {min = 0, max = 0}, {min = 0, max = 0}, {min = 0, max = 0} }

  names = { "S1", "S2", "S3", "S4" }
  units = { "", "", "", "" }
  prec = { 0, 0, 0, 0 }
end

local function background(widget)
  
end

local function refresh(widget)
  -- Użycie opcji:
  local srcs = { 
    widget.options.Source1,
    widget.options.Source2,
    widget.options.Source3,
    widget.options.Source4
  }
  local cls = { 
    widget.options.Color1,
    widget.options.Color2,
    widget.options.Color3,
    widget.options.Color4
  }
  local ms = widget.options.MaxSamples
  local x = widget.zone.x
  local y = widget.zone.y
  local w = widget.zone.w
  local h = widget.zone.h
  
  
  
  
  
 
  
  --Zbieranie danych
  widget.tick = (widget.tick or 0) + 1
  local currentTime = getTime()
    
  if (currentTime - widget.lastUpdate) >= widget.options.Time then
    widget.lastUpdate = currentTime
    
    --lcd.setColor(CUSTOM_COLOR, GREEN)
    --lcd.drawRectangle(x, y, 10, 10, SOLID, CUSTOM_COLOR)

    for i = 1, 4 do
      local srcId = srcs[i]
      
      if type(srcId) == "number" and srcId ~= 0 then
        local val = getValue(srcId)
        if val ~= nil then
            table.insert(history[i], val)

            if val > minmax[i].max then minmax[i].max = val end
            if val < minmax[i].min then minmax[i].min = val end
        else
            table.insert(history[i], 0)
        end

        while #history[i] > ms do
          table.remove(history[i], 1)
        end          
      end
    end
  end



  --Rysowanie
  local gx = x + 5
  local gy = y + 30
  local gw = w - 10
  local gh = h - 70
  --bg
  --lcd.setColor(CUSTOM_COLOR, BLACK)
  lcd.drawFilledRectangle(x, y, w, h, BLACK)
  --Graph
  lcd.drawLine(gx - 1, gy - 1, gx + gw + 1, gy - 1, SOLID, DARKGREY)
  lcd.drawLine(gx - 1, gy + gh + 1, gx + gw + 1, gy + gh + 1, SOLID, DARKGREY)
  lcd.drawLine(gx - 1, gy - 1, gx - 1, gy + gh + 1, SOLID, DARKGREY)
  lcd.drawLine(gx + gw + 1, gy - 1, gx + gw + 1, gy + gh + 1, SOLID, DARKGREY)

  for i = 1, 4 do
    

    if cls[i] ~= nil and srcs[i] ~= nil and srcs[i] > 0 and #history[i] >= 2 then 

      lcd.setColor(CUSTOM_COLOR, cls[i])

      if srcs[i] >= 1 and srcs[i] <= 32 then 
        --Channel
        names[i] = "CH" .. srcs[i]
        units[i] = ""
        prec[i] = 0
      elseif srcs[i] >= 33 and srcs[i] <= 64 then
        --Input
        names[i] = "I" .. (srcs[i] - 32)
        units[i] = ""
        prec[i] = 2
      elseif srcs[i] >= 65 and srcs[i] <= 96 then
        --pot
        names[i] = "POT" .. (srcs[i] - 64)
        units[i] = "%"
        prec[i] = 0
      elseif srcs[i] >= 97 and srcs[i] <= 128 then
        --switch
        names[i] = "SW" .. (srcs[i] - 96)
        units[i] = ""
        prec[i] = 0
      else
        --Telemetry
        names[i] = getSourceName(srcs[i])        
        if model and model.getFieldInfo then
          local info = model.getFieldInfo(srcs[i])
          if info then
            units[i] = info.unit
            prec[i] = info.prec            
          end
        end
      end
      
      
      local tx = x + 5 + (i - 1) * (w / 4)
      
      --Current value with source name and unit      
      if not units[i] or #units[i] == 0 then lcd.drawText(tx, y + 5, string.format("%s: %." .. prec[i] .."f", names[i], history[i][#history[i]] or 0.0), SMLSIZE + cls[i]) 
      else lcd.drawText(tx, y + 5, string.format("%s: %." .. prec[i] .."f [%s]", names[i], history[i][#history[i]] or 0.0, units[i]), SMLSIZE + cls[i]) end

      --Max
      lcd.drawText(tx, y + h - 5 - 30, string.format("Max: %.0f", minmax[i].max or 0.0), SMLSIZE + cls[i])
      --Min
      lcd.drawText(tx, y + h - 5 - 15, string.format("Min: %.0f", minmax[i].min or 0.0), SMLSIZE + cls[i])
    
      local range = minmax[i].max - minmax[i].min
      if range <= 0 then range = 0.1 end

      local scale = gh / range
      local step = gw;
      if #history[i] >= 2 then step = gw / (#history[i] - 1) end

      for j = 2, #history[i] do
        local v1 = history[i][j-1]
        local v2 = history[i][j]

        local x1 = gx + (j - 2) * step
        local y1 = gy + gh - (v1 - minmax[i].min) * scale
        local x2 = gx + (j - 1) * step
        local y2 = gy + gh - (v2 - minmax[i].min) * scale

        lcd.drawLine(x1, y1, x2, y2, SOLID, CUSTOM_COLOR)
      end
      
    end
  end
  
end

return { 
  name = "MultiGraph", 
  options = options,
  create = create, 
  update = update,
  refresh = refresh,
  background = background
}