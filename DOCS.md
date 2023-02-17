Documentation for the reanimation
===============

# Base Settings.
   - __VelocityForce__ = `Int` - Multiplies force of the velocity, recommended & default: 10. (Before: DisableFlingingOnTouch / Works only if DisableMovementVelocity is false.)  
   
   - __AntiSleepForce__ = `Int` - Multiplies force of the antisleep, recommended & default: 1. (The number is divided by **110** / The larger number, then more shaky it is (but also more stabler))  
   
   - __DisableMovementVelocity__ = `Boolean` - Disables movement velocity, might be helpful to bypass anticheats, can jitter/delay. 
   
   - __AntiVoid__ = `Boolean` - Whenever you fall into the void, it will bring you to spawnpoint.  
   
   - __LoadLibrary__ = `Boolean` - If you are converting a script, this will fix "RBXLibrary" errors for yourself
   
   - __SingleThread__ = `Boolean` - Changes the way loops work, instead of making each loop for each part, it will put them all in a table and will fire from just 2 loops, might be better or worse in perfomance for some computers.  
   
# Rig Settings.
   - __R15ToR6__ = `Boolean` - If your rig is r15 and you want to make it r6 to support other scripts, set it to true.  
  
   - __EnableAnims__ = `Boolean` - Disables base animations, might be somewhat helpful.
  
   - __FullNoclip__ = `Boolean` - Completely disables your collisions that let's you walk through objects, might break on swimming physics. 
  
   - __HeadMovementMethod__ = `Boolean` - Enabling this, it will call breakjoints and kill you, then instantly removes ur animate once you respawn, and using setdesiredangle it will allow the head to rotate in Z axis (maybe not the best but surely something).
    
   - __KeepWeldedHair__ = `Boolean` - Keeps hair and head accessories aligned to head.
  
# Bullet Settings.
   - __Bullet__ = `Boolean` - Enables ability to fling people from distance.
      - to get the bullet part, just use this global: __bulletpart__
      - You might as well use hats to replace the fling part with something else (Leave ["FlingHat"] Boolean Blank if you dont want to repace)
      - ["FlingHat"] = `Boolean` - Change "Boolean" to tha Hats ingame name (Best to use dex to find it)
   - __BulletOnLoad__ = `Boolean` - Loads test range fling script after reanimating if this and bullet is enabled.


# Variables.
   - global-env `global_env = (getgenv and getgenv()) or _G` : Global variables, while getgenv() also works I want the script to support exploits that lack this function  
     
   - bullet_disconnected = `boolean` - If true, the highlighted part/Bullet will no longer be cframed, you can always redo this effect if you set it to false again. (unless the part is gone) 
     
   - signals: Table - You can store RBXSignal events right here that you want to disconnect on death using [table.insert].  
     
   - hatlist: Instance - Stores hat data.
     
   - stopped: Boolean - Checks if player is alive or not, useful if you want to break while true loops.  
     
   - CloneRigs: Table - Preloaded rigs.   
     
   - bulletpart: Instance -  Basically gets te bullet part.   
  
   - bulletatacking: Boolean - Toggles bullet movement if `BulletOnLoad` is true
   
# Information
- If you want to preload the rigs everytime you inject your exploit so later the game doesn't freeze for a second, simply create a autoexec script with the linked script below:
```lua
local global_env = (getgenv and getgenv()) or _G
if not global_env.CloneRigs then
   global_env.CloneRigs = {
      ["R6"] = game:GetObjects("rbxassetid://8440552086")[1],
      ['R15'] = game:GetObjects("rbxassetid://10213333320")[1]
   }
end
```  
  
- Explorer path:  

![image](https://user-images.githubusercontent.com/121241384/216994252-cd8634b6-073b-484e-9fd2-000b9051babf.png)


