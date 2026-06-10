# $creaming Base: 2D Nextbot Framework

![Framework icon](icon.jpg)

A lightweight, no-nonsense framework for creating 2D NextBots in Garry's Mod.  
Fill out one shared.lua — and your NextBot is alive.  
No complex setup, no spaghetti code.

Originally built for personal use.  
Now released for everyone.

[![Steam Workshop](https://img.shields.io/badge/Steam-Workshop-blue?style=for-the-badge&logo=steam)](https://steamcommunity.com/sharedfiles/filedetails/?id=3742089194)

## What's Inside

- **Base entity** (`base_screaming`) — AI, movement, sprites, hitboxes
- **Core** (`sb_core.lua`) — registration, logging, auto-fallbacks
- **Spawnmenu** (`sb_mainmenu.lua`, `sb_settings.lua`) — custom Q-menu tab, sliders
- **Modules** (`screaming_modules/`) — colors, icons, mine fix
- **Debugger** (`sb_debugger.lua`) — diagnostic tool for AI pathfinding

---

## Quick Start

### 1. Install the base
Subscribe on Steam Workshop or copy `$creaming_base` into `garrysmod/addons/`

### 2. Create your NextBot
Create folder `lua/entities/[your bot name]/` with `shared.lua`:

```lua
ENT.Base = "base_screaming"
ENT.Type = "nextbot"
ENT.PrintName = "[your bot name]"
ENT.Category = "$creaming Base"
ENT.Spawnable = true
ENT.Folder = "entities/[your bot name]"

ENT.AddonName = "[your addon name]"
ENT.SpriteMaterial = "[your bot name]/sprite"
ENT.SpriteSize = 90

ScreamingBase.RegisterNextbot(ENT)
```

### 3. Add a sprite
Put your `.vtf` file in `materials/[your bot name]/sprite.vtf`

### 4. Done
Your NextBot is ready. Spawn it from `Q-menu → $creaming Base → [your addon]`

## Configuration

### settings.json

Create `settings/npc_[your bot name].json`:

```json
{
    "LockSettings": false,
    "base_speed": 320,
    "max_speed": 550,
    "accel_step": 15,
    "drift_force": 600,
    "godmode": true,
    "hp": 999999,
    "damage": 100,
    "teleport_enable": false,
    "teleport_dist": 2500,
    "hitbox": {
        "shape": "cylinder",
        "width": 32,
        "height": 72
    }
}
```

### Hitbox Shapes

- `cylinder` — Default, vertical box
- `sphere` — Cube with equal sides
- `box` — Rectangular box

### LockSettings

When `true` — sliders in Q-menu are disabled (grayed out).  
Players cannot change settings in-game.

## All shared.lua Fields

| Field | Type | Default | Description |
|---|---|---|---|
| `PrintName` | string | **required** | Name in spawnmenu |
| `Category` | string | **required** | Must be `$creaming Base` |
| `Folder` | string | **required** | Path to entity folder |
| `AddonName` | string | `""` | Folder name in spawnmenu tree |
| `AddonIcon` | string | `"folder"` | Icon from icon database |
| `AddonColor` | string | `"white"` | Color from color database |
| `SubType` | string | `""` | Subfolder inside addon |
| `TreeIcon` | string | `"monkey"` | NPC icon in tree |
| `Color` | string | `"white"` | NPC color |
| `SpriteMaterial` | string | `""` | Path to `.vtf` sprite (no extension) |
| `SpriteAnimated` | bool | `false` | `.gif` animation |
| `SpriteSize` | number | `90` | Sprite size in world units |
| `ChaseMusic` | string | `""` | Looping chase music |
| `AttackSound` | string | `""` | Sound on attack |
| `KillIconMaterial` | string | `""` | Killfeed icon path |

## Automatic Fallbacks

| Missing | Fallback |
|---|---|
| Sprite | Black square |
| Sounds | Silence |
| Killicon | Default GMod icon |
| Spawnmenu icon | Default GMod icon |
| settings.json | Default values |

---

## Modules

Located in `screaming_modules/`. Loaded automatically.

| Module | File | Description |
|---|---|---|
| Colors | `sh_colors.lua` | ~100 named colors |
| Icons | `sh_icons.lua` | ~90 GMod icon16 paths |
| Mine Fix | `sh_mine_fix.lua` | Laser mines react to NextBots |

Create your own `.lua` file in `screaming_modules/` — it will be loaded on startup.

---

## Debugger

`Q-menu → $creaming Base → Tools → Debugger`

When held:
- Green trail — bot's path
- Red line — movement direction
- Green line — line to target
- Console logs every second: map, bot position, player position, distance

---

## Hooks for Developers

```lua
hook.Add("ScreamingBase_OnNextbotPreCreate", "[your addon name]", function(class, data)
    -- Modify data before registration
end)

hook.Add("ScreamingBase_OnNextbotPostCreate", "[your addon name]", function(class, data)
    -- Do something after registration
end)
```

---

## Spawnmenu Structure (example)

```
$creaming Base
├── 📁 My Addon
│ ├── 📁 SubType
│ │ └── 🍉 My NPC
│ └── 🍉 NPC without subtype
├── 📁 NonFolder
└── 📁 Tools
└── 🔧 Debugger
```

---

## Console Logging

- `[INFO]` — green
- `[WARNING]` — yellow
- `[ERROR]` — red

---

## Future Plans

I'm planning to add a spawnpoint system with respawn timers, patrol AI with agro radius, a jumpscare system, screen effects, and ULX integration. No promises on when — but it's coming.

---

## Credits

Created by **$creaming Eagle**

---

BOYKISSER SCREAMER

```

                    .  .                                                        
                  .  @%                                 .   .@&  .              
                 .  @  #&                                *@.  .@  .             
                .  @     (@                        .   @,      .@  .            
               .  @        &#  .          ..     .  *@          ((              
                 &,          @/    @   ,&@#    .   @             @  .           
              .  @             @.  /&       *@,  *&              @  .           
                #(               @  %@         %@#               @. .           
                @,              @&                               @. .           
                @,                                               @  .           
                *%                                               @              
              .  @                                              @.              
                 *&    %@@@@@@@@@@@%        ,@@@@@@@@@@@@      @.               
            .     .@    ,&   *@@@@@%        *@@@@@@   #/    .@/                 
              (@&@@@@@  %*   ,@@@@@(        ,@@@@@@    @        &%              
               .@,       @    #@@@@          (@@@@    %/      @/                
              .   *@   /(             ,,/           .% /(   &#                  
                 .@    (%.             %*    @.      **       @/  .             
              .  @                 *#,                  .    ,(@@               
                         (@%.                     #@@(           .              
                        ..  @,  ,/##             *@   .                         
                          .   &&                   #%  .                        
                           .  (@                     @  .                        
                          . .@@@@@                    @  .                      
                           ..  .@                     /(                        
                               @                       @                        
                              ...........................                       
```
