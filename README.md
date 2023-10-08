## OpenTX Telemetry Charts

# Multi.lua

This is next version of chart script. It combines all sensors into one script. On Taranis X7 You can switch between sensors with rotativ knob.
Moreover, it saves CSV files into /LOGS directory. It creates separated file for each sensor.

![RPM](https://github.com/g0rd0n2007/opentx-telemetry-charts/blob/main/20231007_194238.jpg)
![RSSI](https://github.com/g0rd0n2007/opentx-telemetry-charts/blob/main/20231007_194250.jpg)

File name:
- SensorName + Date

Each row contains:
- Hour;MinValue;MaxValue

![CSV](https://github.com/g0rd0n2007/opentx-telemetry-charts/blob/main/Zrzut%20ekranu%20z%202023-10-07%2019-38-39.png)

You can use excel stock charts to properly view it. Use min value as open value and max as close value.



# Lipo.lua, RPM.lua, Curr.lua

Just change first lines to configure the script.

Name of Your sensor:
- sensorName = "Lipo"

Value format. In this case float with 2 digits after dot:
- valueFormat = "%.2f"

Value unit:
- valueUnit = "[V]"

To clear all samples - long press Ent/OK button. It is usefull between flights.

LUA scripts tested on Taranis X7 transmitter with screen size 128x64


![Lipo](https://github.com/g0rd0n2007/opentx-telemetry-charts/blob/main/20231006_211725.jpg)

![RPM](https://github.com/g0rd0n2007/opentx-telemetry-charts/blob/main/20231006_211733.jpg)
