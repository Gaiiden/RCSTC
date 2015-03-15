declare parameter thrust.

// currently the only hard-coded value. Change as needed
set kN to 0.97.         // use RCS Build Aid to get accurate kN for your individual thrusters

// no touchy!
set e to 2.7182.
set thrustLength to 0.
set bNodeExist to false.
set bConnected to false.
set bSAS to false.
set bDirtyNode to true.
set bMainLoop to true.
set thrusters to list().
set nodeETA to -1.
set nodeDV to -1.
set lastHudMsg to 0.

// code courtesy of Lilleman (kOS thread post #1364)
set iNodeETA to (time:seconds + 126144000).
set tempNode to node(iNodeETA,-500,0,0). // radial out used to move off orbit for ppl to create their own nodes
add tempNode.

// make note of whether SAS is on
if sas { set bSAS to true. }.

// monitor time warp
when warp > 0 and bNodeExist then
{
  if warp > 5
  {
    // less than 3hrs remaining
    if nextnode:eta - (thrustLength/2) < 10800 { set warp to 5. }.
  }
  else if warp = 5
  {
    // less than 10min remaining
    if nextnode:eta - (thrustLength/2) < 600 { set warp to 4. }.
  }
  else if warp = 4
  {
    // less than 3min remaining
    if nextnode:eta - (thrustLength/2) < 180 { set warp to 3. }.
  }
  else if warp = 3
  {
    // less than 1min remaining
    if nextnode:eta - (thrustLength/2) < 60 { set warp to 2. }.
  }
  else if warp = 2
  {
    // less than 30sec remaining
    if nextnode:eta - (thrustLength/2) < 30 { set warp to 1. }.
  }
  else if warp = 1
  {
    // less than 10sec remaining
    if nextnode:eta - (thrustLength/2) < 10 { set warp to 0. }.
  }.
  preserve.
}.

// trigger to begin burn
when nextnode:eta - (thrustLength/2) <= 0 then
{
  print "Commencing thrust".
  rcs on.
  set ship:control:fore to 1.
  set thrustBeginTime to time.
}.

// trigger to cancel the thrust
when abort then
{
  print "Aborting maneuver" at (0,8).

  // clean up if needed
  if rcs
  {
    set ship:control:fore to 0.
    set ship:control:neutralize to true.
    rcs off.
  }
  remove tempNode.
  shutdown.
}.

clearscreen.
abort off.
print "RCS Thrust Control Initializing...".
print "checking for connection to Mission Control...".

// Check if we have any control units on this craft
list parts in partList.
for part in partList
{
  for module in part:modules
  {
    if module = "modulespu"
    {
      if part:getmodule(module):getfield("spu") = "operational." { set bConnected to true. }.
    }.
  }.
}.

// if we didn't find a control unit, we can't run
if not bConnected
{
  print "No connection!".
  shutdown.
}.
print "Connection confirmed".
print "Initializing thrusters...".

// blip the RCS jets to find out what environ we're in
rcs on.
set ship:control:fore to 0.1.
wait 0.1.
set ship:control:fore to 0.
set ship:control:neutralize to true.
rcs off.

// look for thrusters
list parts in partList.
for part in partList
{
  for module in part:modules
  {
    if module = "modulercs"
    {
      // if the rcs port is enabled, add it and log ISP
      if part:getmodule(module):hasevent("disable rcs port")
      {
        set isp to part:getmodule(module):getfield("rcs isp").
        thrusters:add(part).
      }.
    }.
  }.
}.

if thrusters:length = 0
{
  print "No RCS thrusters found!".
  shutdown.
}.

hudtext("found " + thrusters:length + " active thruster(s) totaling " + kN * thrusters:length + "kN of thrust", 10, 2, 35, green, false).
hudtext("with an ISP of " + isp + " set to " + thrust + "% throttle", 10, 2, 35, green, false).
print "Initialization complete!".
print " ".
print "waiting for maneuver node...".
print " ".
print " ".

// monitor for manuver nodes
until bMainLoop = false
{
  if not bNodeExist
  {
    // check that a node exists for us to use
    if nextnode:eta < tempNode:eta
    {
      set bNodeExist to true.
      // snap future node back to normal so it doesn't make things look weird when modifying prior node
      set tempNode:radialout to 0.
    }.
  }
  else
  {
    // if there is no burn executing
    if not rcs
    {
			// check on node settings.
			if round(nextnode:deltav:mag,3) <> nodeDV
			{
				set nodeDV to round(nextnode:deltav:mag,3).
				set bDirtyNode to true.

				// ensure we have enough dV to carry out the maneuver fully, warn user if not
				list resources in shipRes.
				for res in shipRes { if res:name = "monopropellant" { set monoMass to res:amount. }. }.
				set dV to isp*9.82*ln(ship:mass/(ship:mass-(monoMass*.004))).
				if dV < nodeDV
				{
					// prevent HUD spam
					if time - lastHudMsg > 10
					{
						hudtext("WARNING! Craft only contains " + round(dV,2) + "m/s dV!", 10, 2, 50, yellow, false).
						set lastHudMsg to time.
					}
				}.
			}.
			if nextnode:eta <> nodeETA
			{
				set nodeETA to nextnode:eta.
				set bDirtyNode to true.
			}.

			// update the time needed for the thrust?
			if bDirtyNode
			{
				set bDirtyNode to false.

				set thrustLength to (ship:mass * 9.81 * isp / ((thrust/100)*(thrusters:length*kN))) * (1 - (e^((nextnode:deltav:mag*-1)/(9.81 * isp)))).
				print "monitoring " + round(nextnode:deltav:mag,3) + "m/s dV manuever node...  " at(0, 6).
				print round(thrustLength,2) + "s of thrust required at " + thrust + "% throttle  " at(0, 7).
			}.

			// wait for the maneuver and provide a countdown timer
			lock timeRemaining to (time + nextnode:eta - (thrustLength/2)) - time.
      if timeRemaining >= 0
  		{
        print "Time remaining until thrust: " + timeRemaining:Clock at (0,8).
      }.

      // did the user node get deleted?
			if nextnode:eta = tempNode:eta
			{
				set bNodeExist to false.
				set tempNode:radialout to 500.
				print "                                               " at (0,6).
				print "                                               " at (0,7).
				print "                                               " at (0,8).
				print "waiting for maneuver node..." at (0,6).
			}.
    }
    else
    {
			if time - thrustBeginTime >= thrustLength
			{
				print "Thrust Complete!".
				rcs off.
				remove nextnode.
				set ship:control:fore to 0.
				set ship:control:neutralize to true.
				remove tempNode.
				print " ". // forces the program end message down a line
				set bMainLoop to false.
			}.
		}.
  }.

  wait 0.001.
}.

// if SAS was set to node, ending the program (deleting the node) will turn it off. Turn SAS back on?
if not sas and bSAS { sas on. }.
