##Installation

Copy out the program txt file to your KSP/Plugins/PluginData/Archive folder once you have installed kOS. If the folder is not there, create it or run KSP once first.

##Usage

For basic kOS usage (such as loading the program onto your craft) see the [kOS Docs](http://ksp-kos.github.io/KOS_DOC/).

Before running the program you must edit it to set 3 variables. Once they are defined for a craft they do not need to be further modified.

`thrusterCount` is the number of thrusters **that are capable of forward thrust**. Make sure you don't include linear thrusters not pointed backwards along your ship.

`kN` is the amount of force (in kilonewtons) **each individual thruster** produces. I would suggest using [RCS Build Aid](http://forum.kerbalspaceprogram.com/threads/35996-0-23-RCS-Build-Aid-v0-4-4-New-average-center-of-mass-marker) to get this number as it tells you the exact force properly calculated for offset thrust due to thruster angle and placement.

`isp` the ISP of your thrusters can be found in the VAB part menu or in the right-click menu in flight mode. Currently the program assumes all thrusters are rated the same ISP.

After defining the craft-specific variables you must create a maneuver node you want carried out. Once the maneuver node is in place and set how you want, run the program:

`run rcsthrustcontroller(1).`

The single parameter passed to the program is the amount of thrust you want to apply for the maneuver. This value ranges from 0-1, so half thrust would be .5. It is recommended that for maneuvers with little Δv you lower your thrust to retain accuracy in the maneuver, as it is carried out based on time.

Once the program runs, if it doesn't detect a maneuver node it will exit and tell you. If a node is detected, it will inform you of the amount of time needed to complete the maneuver and start counting down. This countdown marks the beginning of RCS thrust, not the time of the maneuver node itself. It is directly tied to the game time so any physics lag will not affect its accuracy.

This program will **not** orient your craft. To do this, you must manually orient it or, if you are dealing with signal delay or future planned lack of connection, use the Remote Tech flight computer. The image below demonsrates a queue of commands to allow the maneuver to properly execute.

![Fig1](http://i.imgur.com/eUNQ6S6.jpg)

First the computer is commanded to orient the craft towards the maneuver node using the NODE button. Then 30s later the NODE button is clicked again to toggle it off, after which SAS is immediately toggled back on. This is done because holding orientation with the Flight Computer while thrusting with RCS will cause oscillation to build up and spin the craft. SAS should be enabled during the thrust, which occured 10s after SAS was switched on in the above example.

Once the thrust is complete the program will terminate and remove the maneuver node (but not any future ones you may have created). You will see the following output in the console.

![Fig2](http://i.imgur.com/eKCVBAo.jpg)

You can cancel the program at any time by deleting the maneuver node.

##Future Additions

- **Remote Tech integration** - when kOS and RT2 play nice together again, the option to enforce signal delay will be available. Applications in this case would be changes to the maneuver node and cancellation of the maneuver node.
- **Node Monitoring** - adjust to changes in the node (time, Δv amount) so that you don't have to delete and re-make the node, re-run the program for changes to take effect.
- **Adaptable Thruster Properties** - once kOS can [access part information more readily](http://forum.kerbalspaceprogram.com/threads/68089-0-24-kOS-Scriptable-Autopilot-System-v0-13-1-2014-7-18?p=1366067&viewfull=1#post1366067), users will no longer need to manually set the 3 thruster properties
- **Multiple ISP Thrusters** - allow for thrusters that don't all have the same ISP
 
##Credits

Nivekk for creating the kOS mod /
erendrake for maintaining and updating the kOS mod /
Steven Mading for great support on the forums (also a kOS dev) /
Lilleman for node existence checking routine
