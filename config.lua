--[[
    ██╗     ██╗  ██╗██████╗       ██╗    ██╗███████╗ █████╗ ██████╗  ██████╗ ███╗   ██╗███████╗
    ██║     ╚██╗██╔╝██╔══██╗      ██║    ██║██╔════╝██╔══██╗██╔══██╗██╔═══██╗████╗  ██║██╔════╝
    ██║      ╚███╔╝ ██████╔╝█████╗██║ █╗ ██║█████╗  ███████║██████╔╝██║   ██║██╔██╗ ██║███████╗
    ██║      ██╔██╗ ██╔══██╗╚════╝██║███╗██║██╔══╝  ██╔══██║██╔═══╝ ██║   ██║██║╚██╗██║╚════██║
    ███████╗██╔╝ ██╗██║  ██║      ╚███╔███╔╝███████╗██║  ██║██║     ╚██████╔╝██║ ╚████║███████║
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝       ╚══╝╚══╝ ╚══════╝╚═╝  ╚═╝╚═╝      ╚═════╝ ╚═╝  ╚═══╝╚══════╝

    LXR Core - Weapons

    Every gun is an item with a serial and a condition. Using it draws it,
    using it again holsters it. Cartridges are items too: loading them moves
    rounds from the satchel into a per-calibre pool the server owns and the
    game ped mirrors. Shots wear the gun down; kits, oil and whetstones bring
    it back; a gunsmith repairs, fits parts and engraves at 1899 prices.

    Brand:       LXRCore — Lux Empire eXperience RedM Core
    Product:     wolves.land / The Land of Wolves
    Developer:   iBoss21 / LXRCore
    Website:     https://www.lxrcore.com
    Discord:     https://discord.gg/GAhk8cgXe9
    GitHub:      https://github.com/LXRCore

    Version: 3.0.0
    Performance Target: 0.00 ms idle (one thread only while a gun is in hand)

    © 2026 iBoss21 / LXRCore | lxrcore.com | All Rights Reserved
]]

Config = Config or {}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ LANGUAGE ██████████████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████
Config.Lang = 'en'

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ WIELDING ══════════════════════════════════════════════
-- ████████████████████████████████████████████████████████████████████████████████
-- Carry limits per category come from the core (LXRShared.WeaponCategories.maxCarry).
-- attach: where each holster slot lives on the ped (game attach points).
Config.Wield = {
    dual = true,                 -- a second sidearm goes to the left holster when the record allows it
    drawInHand = true,           -- draw straight into the hands (false: into the holster, the wheel picks it)
    dropOnDeath = true,          -- guns leave the hands when the character dies (they stay in the satchel)
    holsterOnLogout = true,      -- the loadout is rebuilt from scratch on the next login
    attach = {
        sidearm = { 2, 3 },      -- PISTOL_R, PISTOL_L
        longarm = { 9, 10 },     -- RIFLE, RIFLE_ALTERNATE
        melee   = { 4 },         -- KNIFE
        thrown  = { 6 },         -- THROWER
        bow     = { 7 },         -- BOW
        kit     = { 11 },        -- LANTERN
    },
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ AMMUNITION ════════════════════════════════════════════
-- ████████████████████████████████████████████████████████████████████████████████
-- One pool per cartridge (item name = calibre), persisted in character metadata.
Config.Ammo = {
    maxPool = 200,               -- rounds of one calibre a character carries loaded
    maxPoolByClass = { ammo_rifle_elephant = 20, ammo_shotgun = 60, ammo_shotgun_slug = 40, ammo_shotgun_incendiary = 20, ammo_shotgun_explosive = 10,
                       ammo_arrow = 40, ammo_arrow_improved = 40, ammo_arrow_smallgame = 40, ammo_arrow_poison = 20, ammo_arrow_fire = 20, ammo_arrow_dynamite = 5 },
    loadPerUse = 0,              -- rounds moved per use of a cartridge item; 0 = the whole stack (capped by the pool)
    returnToSatchel = true,      -- the gunsmith panel can unload a pool back into cartridge items
    -- loading rounds: a short progress with the cartridge-handling animation and the calibre's box in hand
    -- (dictionary and clip from the game's animation list; props from the object list — all verified names)
    loadMs = 2500,
    loadAnim = { dict = 'mech_inventory@crafting@fallbacks@modify_bullets', clip = 'loop' },
    loadProps = {                -- item prefix → prop model; the arrow bundle for every arrow kind
        ammo_revolver = 'p_ammo_revolver', ammo_pistol = 'p_ammo_pistol', ammo_repeater = 'p_ammo_repeater',
        ammo_rifle = 'p_ammo_rifle', ammo_shotgun = 'p_ammo_shotgun', ammo_22 = 'p_ammo_rifle', ammo_arrow = 'p_ammo_arrow',
    },
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ CONDITION ═════════════════════════════════════════════
-- ████████████████████████████████████████████████████████████████████████████████
-- Quality lives in the item's info (0–100). Each shot costs `degrade` from the core record
-- (percent), scaled here. At `jamAt` the gun refuses to fire until it is cleaned or repaired.
Config.Condition = {
    degradeMult = 1.0,
    jamAt = 0,
    reportEveryMs = 3000,        -- the client batches shots and reports them this often
    warnAt = { 25, 10 },         -- one warning per threshold as the gun wears
    -- field care: item → { restore = points, only = { category... } | nil }
    care = {
        cleaning_kit = { restore = 60 },
        gun_oil      = { restore = 20 },
        whetstone    = { restore = 50, only = { 'melee', 'bow' } },
    },
    careMs = 6000,
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ GUNSMITHS ═════════════════════════════════════════════
-- ████████████████████████████████████████████████████████████████████████████████
-- The gunsmith repairs, fits and removes components, engraves, and unloads pools.
-- Ammunition and new guns are sold by lxr-shops.
Config.Gunsmiths = {
    -- optional per counter: jobs = { gunsmith = 0 } locks it to a job (name → minimum grade)
    { id = 'valentine',  label = 'Valentine Gunsmith',  coords = vector3(-285.60, 776.07, 119.36), blip = true },
    { id = 'saintdenis', label = 'Saint Denis Gunsmith', coords = vector3(2717.10, -1247.30, 50.78), blip = true, priceMult = 1.25 },
    { id = 'rhodes',     label = 'Rhodes Gunsmith',     coords = vector3(1326.32, -1321.07, 77.04), blip = true },
    { id = 'tumbleweed', label = 'Tumbleweed Gunsmith', coords = vector3(-5516.68, -2936.11, -1.35), blip = true, priceMult = 1.1 },
    { id = 'annesburg',  label = 'Annesburg Gunsmith',  coords = vector3(2938.82, 1329.22, 44.60),  blip = true, priceMult = 1.15 },
}

-- Prices in 1899 dollars. A full repair of a $30 revolver costs about a fifth of a new one;
-- parts carry the core's component price; engravings are labour.
Config.Prices = {
    repairPct = 0.20,            -- share of the item's value for 0 → 100
    repairMin = 0.50,
    fitLabour = 0.75,            -- fitting any component
    removeLabour = 0.25,
    componentMult = 1.0,         -- against LXRShared.WeaponComponents[key].price
    unload = 0,
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ COMPONENTS ════════════════════════════════════════════
-- ████████████████████████████████████████████████████████████████████████████████
-- The gunsmith vocabulary is the core's (LXRShared.WeaponComponents). A fitted part is
-- stored in info.components and given to the game weapon by component name:
--   COMPONENT_<WEAPON WITHOUT 'WEAPON_'>_<PART>   e.g. COMPONENT_REVOLVER_CATTLEMAN_GRIP_IVORY
-- Override single keys here when the game names differ. Cosmetic parts never change stats.
Config.Components = {
    pattern = 'COMPONENT_%s_%s',
    names = {
        -- key = { part = 'GRIP_IVORY' }  -- the second placeholder
        grip_ivory = { part = 'GRIP_IVORY' }, grip_pearl = { part = 'GRIP_PEARL' }, grip_wood = { part = 'GRIP_WOOD' },
        barrel_long = { part = 'BARREL_LONG' }, barrel_short = { part = 'BARREL_SHORT' },
        sight_improved = { part = 'SIGHT_IMPROVED' }, stock_improved = { part = 'STOCK_IMPROVED' }, rifling_improved = { part = 'RIFLING_IMPROVED' },
        scope_short = { part = 'SCOPE_SHORT' }, scope_medium = { part = 'SCOPE_MEDIUM' }, scope_long = { part = 'SCOPE_LONG' },
        finish_blued = { part = 'FINISH_BLUED' }, finish_nickel = { part = 'FINISH_NICKEL' }, finish_silver = { part = 'FINISH_SILVER' }, finish_gold = { part = 'FINISH_GOLD' },
        engraving_simple = { part = 'ENGRAVING_SIMPLE' }, engraving_floral = { part = 'ENGRAVING_FLORAL' }, engraving_scroll = { part = 'ENGRAVING_SCROLL' },
        wrap_leather = { part = 'WRAP_LEATHER' },
    },
    oneOfGroup = true,           -- one barrel, one grip, one finish… fitting replaces the group
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ SECURITY ══════════════════════════════════════════════
-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ COMBAT ════════════════════════════════════════════════
-- ████████████████████████████████████████████████████████████████████████████████
Config.Combat = {
    damage = { ranged = 1.0, melee = 1.0,      -- SET_PLAYER_WEAPON_DAMAGE_MODIFIER / _MELEE_, applied when the gun in hand changes
        byCategory = { revolver = 1.0, pistol = 1.0, repeater = 1.0, rifle = 1.0, shotgun = 1.0, sniper = 1.0, bow = 1.0 } },
    noSprintWhileAiming = true,                -- the sprint control is held down while the player aims
    infiniteAmmo = 'admin',                    -- /infiniteammo needs this group (false disables the command)
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ INSPECTION ════════════════════════════════════════════
-- ████████████████████████████████████████████████████████████████████████████████
-- The game's own weapon-handling animations (names from the animation list): /inspect turns the gun in the
-- hands (base_enter → base_sweep → base_exit), the gunsmith holds it up while the counter is open, and field
-- care plays the cleaning loop. One dictionary per category.
Config.Inspect = {
    command = 'inspect',
    dicts = {
        revolver = 'mech_inspection@weapons@shortarms@cattleman@base',
        pistol   = 'mech_inspection@weapons@shortarms@semi_auto@base',
        repeater = 'mech_inspection@weapons@longarms@repeater_winchester@base',
        rifle    = 'mech_inspection@weapons@longarms@rifle_bolt_action@base',
        shotgun  = 'mech_inspection@weapons@longarms@shotgun_double_barrel@base',
        sniper   = 'mech_inspection@weapons@longarms@sniper_rolling_block@base',
    },
}

-- the gunsmith counter: a camera on the gun in hand — drag turns, the wheel zooms, W/S raise and lower
Config.GunsmithCamera = {
    enabled = true,
    fov = 28.0, fovRange = { 12.0, 45.0 },
    offset = vector3(0.0, 1.35, 0.55),      -- from the ped: forward, up
    look = vector3(0.0, 0.25, 0.55),
    heightRange = { -0.4, 0.4 },
    transitionMs = 400,
}

Config.Security = {
    rateLimit = { windowMs = 2000, burst = 12 },
    maxShotsPerReport = 40,      -- more than this in one report is a modified client
    promptKey = 0xF3830D8E,      -- J
    promptDistance = 2.5,
    gunsmithDistance = 4.0,
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ DEBUG ═════════════════════════════════════════════════
-- ████████████████████████████████████████████████████████████████████████████████
Config.Debug = { printBanner = true, log = false }
