--[[
    ██╗     ██╗  ██╗██████╗        ██╗    ██╗███████╗ █████╗ ██████╗  ██████╗ ███╗   ██╗███████╗
    ██║     ╚██╗██╔╝██╔══██╗       ██║    ██║██╔════╝██╔══██╗██╔══██╗██╔═══██╗████╗  ██║██╔════╝
    ██║      ╚███╔╝ ██████╔╝█████╗ ██║ █╗ ██║█████╗  ███████║██████╔╝██║   ██║██╔██╗ ██║███████╗
    ██║      ██╔██╗ ██╔══██╗╚════╝ ██║███╗██║██╔══╝  ██╔══██║██╔═══╝ ██║   ██║██║╚██╗██║╚════██║
    ███████╗██╔╝ ██╗██║  ██║       ╚███╔███╔╝███████╗██║  ██║██║     ╚██████╔╝██║ ╚████║███████║
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝        ╚══╝╚══╝ ╚══════╝╚═╝  ╚═╝╚═╝      ╚═════╝ ╚═╝  ╚═══╝╚══════╝

    🐺 LXR Core - Weapons System

    This configuration file controls the weapon management system for RedM.
    Players can manage weapon repair, ammunition, and durability tracking.
    Each weapon type has configurable repair costs, ammo limits, and degradation rates.

    ═══════════════════════════════════════════════════════════════════════════════
    SERVER INFORMATION
    ═══════════════════════════════════════════════════════════════════════════════

    Server:      The Land of Wolves 🐺
    Tagline:     Georgian RP 🇬🇪 | მგლების მიწა - რჩეულთა ადგილი!
    Description: ისტორია ცოცხლდება აქ! (History Lives Here!)
    Type:        Serious Hardcore Roleplay
    Access:      Discord & Whitelisted

    Developer:   iBoss21 / The Lux Empire
    Website:     https://www.wolves.land
    Discord:     https://discord.gg/CrKcWdfd3A
    GitHub:      https://github.com/iBoss21
    Store:       https://theluxempire.tebex.io

    ═══════════════════════════════════════════════════════════════════════════════

    Version: 1.0.2
    Performance Target: Optimized for minimal server overhead and client FPS impact

    Tags: RedM, Georgian, SeriousRP, Whitelist, Weapons, Repair, Durability, Ammo

    Framework Support:
    - LXR Core (Primary)
    - RSG Core (Compatible)
    - VORP Core (Compatible)
    - RedEM:RP (Compatible)
    - QBR Core (Compatible)
    - QR Core (Compatible)
    - Standalone (Compatible)

    ═══════════════════════════════════════════════════════════════════════════════
    CREDITS
    ═══════════════════════════════════════════════════════════════════════════════

    Script Author: iBoss21 / The Lux Empire for The Land of Wolves

    © 2026 iBoss21 / The Lux Empire | wolves.land | All Rights Reserved
]]

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🐺 RESOURCE NAME PROTECTION - RUNTIME CHECK
-- ═══════════════════════════════════════════════════════════════════════════════

local REQUIRED_RESOURCE_NAME = "lxr-weapons"
local currentResourceName = GetCurrentResourceName()

if currentResourceName ~= REQUIRED_RESOURCE_NAME then
    error(string.format([[

        ═══════════════════════════════════════════════════════════════════════════════
        ❌ CRITICAL ERROR: RESOURCE NAME MISMATCH ❌
        ═══════════════════════════════════════════════════════════════════════════════

        Expected: %s
        Got: %s

        This resource is branded and must maintain the correct name.
        Rename the folder to "%s" to continue.

        🐺 wolves.land - The Land of Wolves

        ═══════════════════════════════════════════════════════════════════════════════

    ]], REQUIRED_RESOURCE_NAME, currentResourceName, REQUIRED_RESOURCE_NAME))
end

Config = {}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ SERVER BRANDING & INFO ████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.ServerInfo = {
    name = 'The Land of Wolves 🐺',
    tagline = 'Georgian RP 🇬🇪 | მგლების მიწა - რჩეულთა ადგილი!',
    description = 'ისტორია ცოცხლდება აქ!', -- History Lives Here!
    type = 'Serious Hardcore Roleplay',
    access = 'Discord & Whitelisted',

    -- Contact & Links
    website = 'https://www.wolves.land',
    discord = 'https://discord.gg/CrKcWdfd3A',
    github = 'https://github.com/iBoss21',
    store = 'https://theluxempire.tebex.io',

    -- Developer Info
    developer = 'iBoss21 / The Lux Empire',

    -- Tags
    tags = {'RedM', 'Georgian', 'SeriousRP', 'Whitelist', 'Weapons', 'Repair', 'Durability', 'Ammo'}
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ FRAMEWORK CONFIGURATION ███████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

--[[
    Framework Priority (in order):
    1. LXR-Core (Primary)
    2. RSG-Core (Primary)
    3. VORP Core (Supported)
    4. RedEM:RP (Optional - if detected)
    5. QBR-Core (Optional - if detected)
    6. QR-Core (Optional - if detected)
    7. Standalone (Fallback)
]]

Config.Framework = 'auto' -- 'auto' or manual: 'lxr-core', 'rsg-core', 'vorp_core', 'redem_roleplay', 'qbr-core', 'qr-core', 'standalone'

-- Framework-specific settings
Config.FrameworkSettings = {
    ['lxr-core'] = {
        resource = 'lxr-core',
        notifications = 'ox_lib',
        inventory = 'lxr-inventory',
        target = 'ox_target',
        events = {
            server = 'lxr-core:server:%s',
            client = 'lxr-core:client:%s',
            callback = 'lxr-core:callback:%s'
        }
    },
    ['rsg-core'] = {
        resource = 'rsg-core',
        notifications = 'ox_lib',
        inventory = 'rsg-inventory',
        target = 'ox_target',
        events = {
            server = 'RSGCore:Server:%s',
            client = 'RSGCore:Client:%s',
            callback = 'RSGCore:Callback:%s'
        }
    },
    ['vorp_core'] = {
        resource = 'vorp_core',
        notifications = 'vorp',
        inventory = 'vorp_inventory',
        target = 'vorp_core',
        events = {
            server = 'vorp:server:%s',
            client = 'vorp:client:%s'
        }
    },
    ['redem_roleplay'] = {
        resource = 'redem_roleplay',
        notifications = 'redem',
        inventory = 'redem_inventory',
        target = 'redem_target',
        events = {
            server = 'redem:%s:server',
            client = 'redem:%s:client'
        }
    },
    ['qbr-core'] = {
        resource = 'qbr-core',
        notifications = 'ox_lib',
        inventory = 'qbr-inventory',
        target = 'ox_target',
        events = {
            server = 'QBR:Server:%s',
            client = 'QBR:Client:%s'
        }
    },
    ['qr-core'] = {
        resource = 'qr-core',
        notifications = 'ox_lib',
        inventory = 'qr-inventory',
        target = 'ox_target',
        events = {
            server = 'QR:Server:%s',
            client = 'QR:Client:%s'
        }
    },
    ['standalone'] = {
        notifications = 'print',
        inventory = 'none',
        target = 'none'
    }
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ DEBUG SETTINGS ████████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.Debug = false -- Enable debug prints and extra logging

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ WEAPON REPAIR POINTS ██████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

-- Define locations where players can bring weapons for repair.
-- Add additional entries with incrementing numeric keys and vector3 coordinates.

Config.WeaponRepairPoints = {
    [1] = {coords = vector3(1417.818, 268.0298, 89.61942)}
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ WEAPON REPAIR COSTS ███████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

-- Repair cost per weapon category (in-game currency).
-- Keys must match weapon class names derived from ammotype (e.g. "pistol", "revolver").

Config.WeaponRepairCosts = {
    ["pistol"]   = 100,
    ["revolver"] = 200,
    ["repeater"] = 300,
    ["rifle"]    = 300,
    ["shotgun"]  = 400
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ MAXIMUM AMMO LIMITS ███████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

-- Maximum ammo capacity per weapon group hash.
-- Extend by adding new GROUP_ entries.

Config.MaxAmmo = {
    [`GROUP_PISTOL`]   = 6,
    [`GROUP_RIFLE`]    = 12,
    [`GROUP_REVOLVER`] = 6,
    [`GROUP_SHOTGUN`]  = 6,
    [`GROUP_BOW`]      = 6
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ WEAPON DURABILITY MULTIPLIERS █████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

-- Controls how quickly each weapon degrades per bullet fired.
-- Lower value = slower degradation. Add any weapon hash to extend.

Config.DurabilityMultiplier = {
    -- Handguns
    [`weapon_revolver_cattleman`]         = 0.15,
    [`weapon_revolver_cattleman_mexican`] = 0.15,
    [`weapon_revolver_doubleaction_gambler`] = 0.15,
    [`weapon_revolver_schofield`]         = 0.15,
    [`weapon_revolver_lemat`]             = 0.15,
    [`weapon_revolver_navy`]              = 0.15,
    [`weapon_pistol_volcanic`]            = 0.15,
    [`weapon_pistol_m1899`]               = 0.15,
    [`weapon_pistol_mauser`]              = 0.15,
    [`weapon_pistol_semiauto`]            = 0.15,
    [`weapon_repeater_carbine`]           = 0.15,
    [`weapon_repeater_winchester`]        = 0.15,
    [`weapon_repeater_henry`]             = 0.15,
    [`weapon_repeater_evans`]             = 0.15,

    -- Rifles
    [`weapon_rifle_varmint`]              = 0.15,
    [`weapon_rifle_springfield`]          = 0.15,
    [`weapon_rifle_boltaction`]           = 0.15,
    [`weapon_rifle_elephant`]             = 0.15,
    [`weapon_sniperrifle_rollingblock`]   = 0.15,
    [`weapon_sniperrifle_rollingblock_exotic`] = 0.15,
    [`weapon_sniperrifle_carcano`]        = 0.15,

    -- Shotguns
    [`weapon_shotgun_doublebarrel`]       = 0.15,
    [`weapon_shotgun_doublebarrel_exotic`] = 0.15,
    [`weapon_shotgun_sawedoff`]           = 0.15,
    [`weapon_shotgun_semiauto`]           = 0.15,

    -- Bows
    [`weapon_bow_improved`]               = 0.15,
    [`weapon_bow`]                        = 0.15
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ END OF CONFIGURATION ██████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

-- Startup banner
CreateThread(function()
    Wait(1000)
    print([[

        ═══════════════════════════════════════════════════════════════════════════════

            ██╗     ██╗  ██╗██████╗        ██╗    ██╗███████╗ █████╗ ██████╗  ██████╗ ███╗   ██╗███████╗
            ██║     ╚██╗██╔╝██╔══██╗       ██║    ██║██╔════╝██╔══██╗██╔══██╗██╔═══██╗████╗  ██║██╔════╝
            ██║      ╚███╔╝ ██████╔╝█████╗ ██║ █╗ ██║█████╗  ███████║██████╔╝██║   ██║██╔██╗ ██║███████╗
            ██║      ██╔██╗ ██╔══██╗╚════╝ ██║███╗██║██╔══╝  ██╔══██║██╔═══╝ ██║   ██║██║╚██╗██║╚════██║
            ███████╗██╔╝ ██╗██║  ██║       ╚███╔███╔╝███████╗██║  ██║██║     ╚██████╔╝██║ ╚████║███████║
            ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝        ╚══╝╚══╝ ╚══════╝╚═╝  ╚═╝╚═╝      ╚═════╝ ╚═╝  ╚═══╝╚══════╝

        ═══════════════════════════════════════════════════════════════════════════════
        🐺 WEAPONS SYSTEM - SUCCESSFULLY LOADED
        ═══════════════════════════════════════════════════════════════════════════════

        Version:       1.0.2
        Server:        ]] .. Config.ServerInfo.name .. [[

        Framework:     Auto-detect enabled
        Repair Points: ]] .. #Config.WeaponRepairPoints .. [[

        Debug:         ]] .. (Config.Debug and 'ENABLED' or 'DISABLED') .. [[

        ═══════════════════════════════════════════════════════════════════════════════

        Developer:     iBoss21 / The Lux Empire
        Website:       https://www.wolves.land
        Discord:       https://discord.gg/CrKcWdfd3A

        ═══════════════════════════════════════════════════════════════════════════════

    ]])
end)
