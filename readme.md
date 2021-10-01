## Introduction ##

This software uses Sonic Pi 3.3.1 to interact with the MkII version of Hexler's TouchOSC to generate an interactive alarm clock with audible output for seconds, 10th of seconds, and voice announcement of the time each minute. In addition the clock can play the westmister chimes at the 1/4 1/2 3/4 of the hour and on the hour. A separate 24 hour alarm can be set to any minute.

The TouchOSC interface is available for Mac, Windows and Linux desktops (including Raspberry Pi). It can be gried for free, but a licence is avaialbe which covers a user for every platform.

Two files are required. TouchOSCclock.rb which runs on Sonic Pi, and clockAlarmTW.tosc which is loaded into teh TouchOSC editor.

The system is designed to run Sonic Pi and TouchOSCeditor on the same computer, but it can be adjusted to run them on separate comptuters on the same local network, preferrably both connected by wired ethernet rather than WiFi.

## Instructions for use ##

Open the Touch OSC editor and load in the file clockAlarmTW.tosc

Open the connections setting, select **OSC** and in **connection 1** enter
```
host: localhost
send port: 4560
receive port: 9000
```

The TouchOSCclock.rb program is too long to run from a Sonic Pi buffer. Instead enter the following lines into a free buffer on your Sonic Pi
```
set :ip,"localhost"
run_file "/path/to/file/TouchOSAlarmCclock.rb"
```

Start Touch OSC by Toggling the editor on the View Menu

switch to Sonic Pi and star the program running, then back to TouchOSC.

## Controls ##
```
Enable Secs. Toggles on/off a tone wich sounds every second,
       rising for seconds 0->30 then falling back again for seconds 30->60
Enable Tenths Toggles on/off rising and falling notes every 1/10th second
Enbable Speech Toggles On/Off speech output announcing each minute
        and 15/30 and 45 second marks
Enable Chimes Toggles on/off Westminster Chimes sounding at 1/4 1/2 3/4 and on the hour.
       In addition tones to indicate the hour starting on each hour
Enable Alarm Toggles on/off arming the Alarm to sound at the displayed alarn time
Set PM Toggles the Alarm Hur selector buttons between 0->11 and 12->23 hours
```
## Setting the Alarm Time
```
use the Set PM swtch to choose the Alarm Hour range
click the required hour
use the Alarm Mins buttons to choose the nearest 5min BEFORE the alarm time
use the Add In buttons to select additonal minutes to get the required time
use the Enable Alarm button to prime the alarm
The selected larm time and its enable state are shown in the text field
```
