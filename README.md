# 🐺 lxr-weapons

![Version](https://img.shields.io/badge/version-1.0.2-blue)
![Status](https://img.shields.io/badge/status-active-brightgreen)
![License](https://img.shields.io/github/license/LXRCore/lxr-weapons)
![RedM](https://img.shields.io/badge/game-RedM-red)
![Framework](https://img.shields.io/badge/framework-LXR--Core%20%7C%20RSG--Core%20%7C%20VORP-blueviolet)

> **The Land of Wolves 🐺** — Georgian RP | მგლების მიწა - რჩეულთა ადგილი!
>
> Developer: **iBoss21 / The Lux Empire** | [wolves.land](https://www.wolves.land) | [Discord](https://discord.gg/CrKcWdfd3A) | [Store](https://theluxempire.tebex.io)

---

**lxr-weapons** is a production-grade weapon management system for **RedM**, built for the **LXR-Core** framework with full multi-framework support. It features weapon repair points, customisable repair costs, ammo limits, a durability degradation system, and a clean, modular configuration — all styled to the wolves.land / LXR codebase standard.

## ═══════════════════════════════════════════════════════════
## Features

- 🔧 Configurable weapon repair points with world coordinates
- 💰 Custom repair costs per weapon category (pistols, revolvers, rifles, shotguns, etc.)
- 🔫 Maximum ammo limits per weapon group
- ⚙️ Per-weapon durability multipliers controlling degradation rate
- 🌐 Multi-framework support (LXR-Core primary, RSG-Core, VORP, RedEM:RP, QBR, QR, Standalone)
- 🛡️ Resource name protection guard at runtime
- 📢 Branded startup banner printed to server console
- 🌍 Locale system (English included, easily extendable)

## ═══════════════════════════════════════════════════════════
## Framework Support

| Framework       | Status        |
|-----------------|---------------|
| LXR-Core        | ✅ Primary    |
| RSG-Core        | ✅ Primary    |
| VORP Core       | ✅ Supported  |
| RedEM:RP        | ✅ Compatible |
| QBR-Core        | ✅ Compatible |
| QR-Core         | ✅ Compatible |
| Standalone      | ✅ Fallback   |

## ═══════════════════════════════════════════════════════════
## Installation

1. Place the `lxr-weapons` folder into your server's resource directory (e.g. `resources/[lxr]/`).
2. Add the following to your `server.cfg`:

```bash
ensure lxr-core
ensure lxr-weapons
```

> ⚠️ The resource folder **must** be named `lxr-weapons`. A runtime guard will throw an error if the name does not match.

---

## Configuration

All options are in `config.lua`. Below is a summary of each section.

### Weapon Repair Points

Locations where players can bring weapons for repair.

```lua
Config.WeaponRepairPoints = {
    [1] = {coords = vector3(1417.818, 268.0298, 89.61942)}
}
```

Add additional entries with incrementing keys and new `vector3` coordinates.

### Weapon Repair Costs

Cost (in-game cash) to repair each weapon category.

```lua
Config.WeaponRepairCosts = {
    ["pistol"]   = 100,
    ["revolver"] = 200,
    ["repeater"] = 300,
    ["rifle"]    = 300,
    ["shotgun"]  = 400
}
```

### Maximum Ammo Limits

Maximum ammo capacity per weapon group hash.

```lua
Config.MaxAmmo = {
    [`GROUP_PISTOL`]   = 6,
    [`GROUP_RIFLE`]    = 12,
    [`GROUP_REVOLVER`] = 6,
    [`GROUP_SHOTGUN`]  = 6,
    [`GROUP_BOW`]      = 6
}
```

### Weapon Durability Multipliers

Controls how quickly each weapon degrades per bullet fired. Lower value = slower degradation.

```lua
Config.DurabilityMultiplier = {
    [`weapon_revolver_cattleman`] = 0.15,
    [`weapon_rifle_boltaction`]   = 0.15,
    [`weapon_shotgun_doublebarrel`] = 0.15,
    [`weapon_bow`]                = 0.15
    -- ... add more as needed
}
```

### Framework Selection

```lua
Config.Framework = 'auto' -- or: 'lxr-core', 'rsg-core', 'vorp_core', 'redem_roleplay', 'qbr-core', 'qr-core', 'standalone'
```

---

## ═══════════════════════════════════════════════════════════
## Credits

- Script Author: **iBoss21 / The Lux Empire** for The Land of Wolves
- Framework: **LXRCore**
- Inspired by: **qbr-weapons** for the QBCore framework

---

## License

© 2026 iBoss21 / The Lux Empire | [wolves.land](https://www.wolves.land) | All Rights Reserved

This project is licensed under the MIT License.

---

*🐺 The Land of Wolves — ისტორია ცოცხლდება აქ! (History Lives Here!)*

