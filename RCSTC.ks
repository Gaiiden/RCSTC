clearscreen.

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
set thrusterPartsEnabled to list().
set thrusterPartsDisabled to list().
set nodeETA to -1.
set nodeDV to -1.
set lastHudMsg to 0.
set statusLine to 10.
set lineoffset to 0.
set thrustBeginTime to 99999999.  // prevent user enabling of RCS prior to automated enable crashing the program

// code courtesy of Lilleman (kOS thread post #1364)
set iNodeETA to (time:seconds + 126144000).
set tempNode to node(iNodeETA,-500,0,0). // radial out used to move off orbit for ppl to create their own nodes
add tempNode.

// make note of whether SAS is on
if sas { set bSAS to true. }.

// ensure no pre-mature abort
abort off.

// we can't initialize under time warp because RCS thrusters will not fire to give us ISP readings
if warp > 0 {
  print "coming out of time warp...".
  set warp to 0.
  wait 5.
  set lineOffset to lineOffset + 1.
}.

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
  print "Commencing thrust" at (0,statusLine+lineOffset).
  rcs on.
  set ship:control:fore to 1.
  set thrustBeginTime to time.
}.

function ThrustManager
{
  print "RCS Thrust Control Initializing...".

  // do we need to check for remote connection?
  if addons:rt:available
  {
    if not addons:rt:haslocalcontrol(ship)
    {
      print "checking for connection to Mission Control...".
      set lineOffset to lineOffset + 1.
      if not addons:rt:haskscconnection(ship)
      {
        print "No connection found!".
        return false.
      }.
      print "Connection confirmed".
      set lineOffset to lineOffset + 1.
    }.
  }.

  // look for thrusters
  print "Initializing thrusters...".
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
          thrusters:add(part:getmodule("modulercs")).
          thrusterPartsEnabled:add(part).
        }
        else
        {
          thrusterPartsDisabled:add(part).
        }.
      }.
    }.
  }.

  if thrusters:length = 0
  {
    print "No RCS thrusters found!".
    return false.
  }.

  // get thruster throttle
  set thrust to thrusters[0]:getfield("thrust limiter").

  hudtext("found " + thrusters:length + " active thruster(s) totaling " + kN * thrusters:length + "kN of thrust", 10, 2, 35, green, false).
  hudtext("with an ISP of " + isp + " set to " + round(thrust, 2) + "% throttle", 10, 2, 35, green, false).
  set highlighterEnabled to highlight(thrusterPartsEnabled, green).
  set highlighterDisabled to highlight(thrusterPartsDisabled, red).
  set highlightOut to time:seconds.
  print "Initialization complete!".
  print " ".
  print "waiting for maneuver node...".
  print " ".
  print " ".
  print " ".
  print " ".
  print " ".
  print " ".
  print " ".
  print " ".
  print " ".
  print " ".

  // monitor for manuver nodes
  until bMainLoop = false
  {
    // turn off the highlighting
    if time:seconds - highlightOut > 10 and highlighterEnabled:enabled
    {
      set highlighterEnabled:enabled to false.
      set highlighterDisabled:enabled to false.
    }.

    // does the user wish to cancel the maneuver?
    if abort
    {
      // delay the abort if this is a remote connection
      if addons:rt:available
      {
        if not addons:rt:haslocalcontrol(ship)
        {
          print "Transmitting abort command..." at (0,statusLine+lineOffset).
          set lineOffset to lineOffset + 1.
          if addons:rt:haskscconnection(ship)
          {
            wait addons:rt:kscdelay(ship).
          }.
        }.
      }.
      print "Aborting maneuver" at (0,statusLine+lineOffset).

      // clean up if needed
      if rcs
      {
        set ship:control:fore to 0.
        set ship:control:neutralize to true.
        rcs off.
      }
      remove tempNode.
      return false.
    }.

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
        for part in thrusters
        {
          if part:getfield("thrust limiter") <> thrust
          {
            set bDirtyNode to true.
            set thrust to part:getfield("thrust limiter").

            // don't allow a thrust setting of 0
            if thrust = 0 { set thrust to 1. }.
            break.
          }.
        }.
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

          // make sure all thrusters are equal
          for part in thrusters
          {
            part:setfield("thrust limiter", thrust).
          }.

          set thrustLength to (ship:mass * 9.81 * isp / ((thrust/100)*(thrusters:length*kN))) * (1 - (e^((nextnode:deltav:mag*-1)/(9.81 * isp)))).
          print "monitoring " + round(nextnode:deltav:mag,3) + "m/s dV manuever node...  " at(0, 6+lineOffset).
          print round(thrustLength,2) + "s of thrust required at " + thrust + "% throttle    " at(0, 7+lineOffset).
        }.

        // wait for the maneuver and provide a countdown timer
        lock timeRemaining to (time + nextnode:eta - (thrustLength/2)) - time.
        if timeRemaining >= 0
        {
          print "Time remaining until thrust: " + timeRemaining:Clock at (0,8+lineOffset).
        }.

        // did the user node get deleted?
        if nextnode:eta = tempNode:eta
        {
          set bNodeExist to false.
          set tempNode:radialout to 500.
          print "                                               " at (0,6+lineOffset).
          print "                                               " at (0,7+lineOffset).
          print "                                               " at (0,8+lineOffset).
        }.
      }
      else
      {
        if time - thrustBeginTime >= thrustLength
        {
          print "Thrust Complete!" at (0,statusLine+lineOffset+1).
          rcs off.
          remove nextnode.
          set ship:control:fore to 0.
          set ship:control:neutralize to true.
          remove tempNode.
          print " ". // forces the program end message down a line
          return true.
        }
        else if thrustBeginTime = 99999999
        {
            // prevent HUD spam
            if time - lastHudMsg > 10
            {
              hudtext("WARNING! RCS prematurely enabled. Program paused.", 10, 2, 50, yellow, false).
              set lastHudMsg to time.
            }
        }.
      }.
    }.

    wait 0.001.
  }.

  return true.
}.

ThrustManager().

// if SAS was set to node, ending the program (deleting the node) will turn it off. Turn SAS back on?
if not sas and bSAS { sas on. }.
