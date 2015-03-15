##Installation

Copy out the program .ks files to your KSP/Ships/Script folder once you have installed kOS v0.16.0 or later. If the folder is not there, create it or run KSP once first.

##Usage (with [Tweakable Everything](http://forum.kerbalspaceprogram.com/threads/64711-0-23-5-TweakableEverything-1-1-For-all-your-part-tweaking-needs))

For basic kOS usage (such as loading the program onto your craft) see the [kOS Docs](http://ksp-kos.github.io/KOS_DOC/tutorials/quickstart.html).

Before running the program you must edit it to set the thrust for your RCS block at the very beginning of the script. Once this is done you don't need to edit it again.

`kN` is the amount of force (in kilonewtons) **each individual thruster** produces. I would suggest using [RCS Build Aid](http://forum.kerbalspaceprogram.com/threads/35996-0-23-RCS-Build-Aid-v0-4-4-New-average-center-of-mass-marker) to get this number as it tells you the exact force properly calculated for offset thrust due to thruster angle and placement.

**Make sure any RCS thrusters you do not want this program to use have been disabled via the right-click menu**

You can now run the program

`run rcstc.`

Once the program runs, it will first ensure that you are connected to Mission Control. If you are not using Remote Tech or are not playing with signal delay, you can edit the program script and set `bConnected` to true where it is defined at the very top.

Next it will automatically detect all active RCS ports and perform a *very* short and low-thrust test burst of your RCS thruster ports to determine their ISP. **All ports in use should be using the same ISP**. It will then tell you on the HUD what it has found so you can confirm number, ISP and throttle setting.

Next the program will look for a maneuver node. If it doesn't detect a maneuver node it will wait until you create one. When a node is detected, it will first check to make sure your craft has the amount of Δv required to perform the maneuver. If you don't have enough Δv a warning message will inform you (and continue to inform you until you adjust or execute your maneuver) but the program will not cancel the node. It will next inform you of the amount of time needed to complete the maneuver and start counting down. This countdown marks the beginning of RCS thrust, not the time of the maneuver node itself. It is directly tied to the game time so any physics lag will not affect its accuracy.

At any time before the node executes you can alter the thrust limiter of your RCS, the position of the node and/or the prograde/radial/normal properties - the changes will be reflected in real time in the kOS output window. To change the RCS thrust limit, you only have to select and edit one active block and the rest will be set to the same value. If you delete the maneuver node you created the program will return to a wait state.

**do not delete the maneuver node created by the program. Doing so while no other node is present will create a run-time kOS error.**

If the time to thrust is a ways off, you can time warp as much as you please - the program will detect this and make sure to drop you out of warp 10 seconds prior to node execution. *note it will only monitor time accelleration if a user-made maneuver node is present*.

This program will **not** orient your craft. To do this, you must manually orient it or, if you are dealing with signal delay or future planned lack of connection, use the Remote Tech flight computer. 

Once the thrust is complete the program will terminate and remove the maneuver node (but not any future ones you may have created). If you had SAS set to target the node during the maneuver, the program's removal of the node will cause KSP to disable your SAS, but the program will make sure to toggle it back on if this was the case.

You can cancel the program at any time by pressing the Abort button. This will shutdown the kOS terminal and you will have to power it back on via the right-click menu on the part containing the kOS module.

##Usage (without Tweakable Everything)

If you do not have Tweakeable Everything installed to use the RCS thrust limiter, you can instead use the RCSTC(no TE) script file (rename it to RCSTC and delete the other version). Everything about the program stays the same except you must specify the throttle setting when the program is run and you can't change it without aborting & restarting the program. Example:

`run RCSTC(76).`

This will load the thrust controller at 76% throttle.

##Future Additions

- **Signal Delay Integration** - Loading the program will be delayed. Cancelling maneuvers will be delayed. Confirmation of the maneuver being completed and the script exiting will be delayed.
- **Thruster kN Detection** - Will allow the option to not have to set the `kN` variable manually
- **Multiple ISP Thrusters** - Allow for thrusters that don't all have the same ISP
- **Multiple kN Thrusters** - Allow for thrusters that don't all have the same kN
- **Optional Throttle Setting** - Allow for one file that can let the user choose to either set the throttle at the start or adjust via Tweakable Everything

##Known Issues

- The future node created by the script is there to avoid a run-time error that needs to be patched within kOS
- The future node initially has a radial out value to push it off the current orbit so that it can be selected by the user to place a node before it
- Regardless of whether you are using an actual kOS part or are using Module Manager to insert kOS functionality into another part (like a probe core) it **must not be a root part** of the craft. This is a known kOS issue
 
##Credits

Nivekk for creating the kOS mod /
erendrake for maintaining and updating the kOS mod /
Steven Mading for great support on the forums (also a kOS dev) /
Lilleman for node existence checking routine
