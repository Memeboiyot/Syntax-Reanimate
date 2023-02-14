
# Reanimation
- Discord: https://discord.gg/3Qr97C4BDn
- Animation Convertor from FD to FE.
- Works on any roblox third-party software (excluding studio) that runs on LUA-U or Lua 5.1  
  
# Information:
- Heavily Stable.
- Almost little to none delay
- Very Little To almost no jitter
- Comes with a lot of settings
- R15 and R6 Support.
- Comes with bullet flinging method ( Range Fling )
- Extremely Low FPS Drop

# Executor Requirements:
- Access to CoreGui
- Loadstring and `task` Library
- GetObjects Support  
  
# Credits:
- Lead Developer:
  - Gelatek: Everything
- Extra Help:
  - ProductionTake1: Motivation, Help with some optimization
  - Emper: Help with optimization


# Code:
```lua
local global_env = (getgenv and getgenv()) or _G
global_env.Settings = {
    -- Base Settings
    ["VelocityForce"] = 10,
    ["AntiSleepForce"] = 1,
    ["DisableMovementVelocity"] = false,
    ["SingleThread"] = true,
    ["AntiVoid"] = true,
    
    -- Rig Settings
    ["R15ToR6"] = false,
    ["EnableAnims"] = true,
    ["FullNoclip"] = false,
    ["KeepWeldedHair"] = true,
    ["HeadMovementMethod"] = false,
    
    -- Fling Settings
    ["BulletOnLoad"] = false,
    ["Bullet"] = false
}
loadstring(game:HttpGet("https://raw.githubusercontent.com/toldblock/Reanimation/main/main.lua"))()
```
