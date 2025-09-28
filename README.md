# OpenTX/EdgeTX Charts for telemetry sensors

### Black/White charts for Taranis X7

Copy file `charts.lua` to Your `SDCARD/SCRIPTS/TELEMETRY` directory. During start it will scan all Your sensors. To limit CPU usage every sensor is disabled at the beggining. 

![2.png](/images/1.png)

To start recording just push `[OK]` button. It will start the chart. You can switch between sensors with `[MENU]` button. 

There is also cursor function in the charts. Normally it follows the newest value. But You can move it with rotation wheel. The value from the cursor is shown in the middle at left side.

On left side there are also Maximum and Minimum values shown.

Here are some pictures:

![3.png](/images/2.png)

![4.png](/images/3.png)

### Color charts for TX16S

Copy `Multigraph` folder to Your radio `SDCARD/WIDGETS` folder. Then select new widget in the same way as other widgets. In widget settings You will find:

- Source1-4: Choose source 

- Color1-4: Select color

- MaxSamples: How many points chart have

- Time: How quickly to take new sample. 10 means 0.1sec, 100 means 1sec.

Standard size

![10.jpg](/images/10.jpg)

Full screen

![12.jpg](/images/12.jpg)

New upgrade with correct precision and unit description

![13.jpg](/images/13.jpg)



From experience - to dont exceed CPU limit - dont exceed 100 points for 4 channels. If You want more points then decrease monitored channels number to 3, 2 or 1.
