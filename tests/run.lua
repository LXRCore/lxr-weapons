--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-WEAPONS — Offline tests: holsters, wear, prices, parts, locale parity
     Requires a sibling checkout of lxr-core (../lxr-core).
     Usage (from the lxr-weapons folder):  lua tests/run.lua [--mock out.js en|ka]
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

local CORE = os.getenv('LXR_CORE_PATH') or '../lxr-core'
package.path = CORE .. '/?.lua;' .. package.path
local ok = pcall(function() require('tests.lib.fxshim') end)
if not ok then print('lxr-core shim not found at ' .. CORE .. ' (set LXR_CORE_PATH)') os.exit(2) end
local Shim = require('tests.lib.fxshim')

for _, f in ipairs({ 'shared/main.lua', 'shared/locale.lua', 'locales/en.lua', 'config.lua', 'shared/catalog.lua', 'shared/items.lua', 'shared/prices.lua', 'shared/weapons.lua' }) do Shim.load(CORE .. '/' .. f) end
Config = nil
Locale = nil
Shim.load('shared/locale.lua')
Shim.load('locales/en.lua')
Shim.load('locales/ka.lua')
Shim.load('config.lua')
Shim.load('shared/wield.lua')
local W = LXRWeapons

local passed, failed = 0, 0
local function test(name, fn)
    local okT, err = xpcall(fn, debug.traceback)
    if okT then passed = passed + 1 print('  ^ ok   ' .. name) else failed = failed + 1 print('  x FAIL ' .. name .. '\n' .. err) end
end
local function eq(a, b, msg) if a ~= b then error((msg or 'eq') .. ': expected ' .. tostring(b) .. ' got ' .. tostring(a), 2) end end

print('lxr-weapons offline tests')

test('every weapon item resolves to a record and a holster', function()
    local n = 0
    for name, def in pairs(LXRShared.Items) do
        if def.type == 'weapon' then
            assert(W.IsWeaponItem(name), name .. ' has no record')
            local rec = W.Record(name)
            local slot = rec.slot or W.Category(rec).slot
            assert(Config.Wield.attach[slot], name .. ' slot ' .. tostring(slot) .. ' has no attach points')
            n = n + 1
        end
    end
    assert(n > 40, 'weapons: ' .. n)
end)

test('holsters: two revolvers pair, a third is refused, a rifle takes the back', function()
    local cat = W.Record('weapon_revolver_cattleman')
    local loadout = {}
    local a = assert(W.AttachFor(cat, loadout)) eq(a, 2)
    loadout.A = { name = cat.name, category = cat.category, attach = a }
    local b = assert(W.AttachFor(cat, loadout)) eq(b, 3)
    loadout.B = { name = cat.name, category = cat.category, attach = b }
    local c, why = W.AttachFor(cat, loadout)
    assert(c == nil and why == 'too_many', tostring(why))
    local lemat = W.Record('weapon_revolver_lemat')
    local _, why2 = W.AttachFor(lemat, { A = loadout.A })
    eq(why2, 'no_dual')
    local rifle = W.Record('weapon_rifle_springfield')
    eq(assert(W.AttachFor(rifle, loadout)), 9)
end)

test('wear and care', function()
    local rec = W.Record('weapon_revolver_cattleman')
    local q = W.Degrade(100, rec, 100)
    assert(q < 100 and q > 90, 'wear per 100 shots: ' .. q)
    eq(W.Degrade(0.01, rec, 5), 0)
    assert(W.Jammed(0) and not W.Jammed(1))
    eq(W.CareFor('cleaning_kit', rec), 60)
    eq(W.CareFor('whetstone', rec), nil)
    eq(W.CareFor('whetstone', W.Record('weapon_melee_knife')), 50)
end)

test('gunsmith prices sit on the 1899 ledger', function()
    local def = LXRShared.Items['weapon_revolver_cattleman']
    eq(W.RepairPrice(def, 100), 0)
    local full = W.RepairPrice(def, 0)
    assert(math.abs(full - def.value * Config.Prices.repairPct) < 0.01, 'full repair ' .. full)
    assert(W.RepairPrice(def, 99) >= Config.Prices.repairMin)
    local half = W.RepairPrice(def, 50, 1.25)
    assert(math.abs(half - def.value * Config.Prices.repairPct * 0.5 * 1.25) < 0.01, 'half at Saint Denis ' .. half)
    assert(W.FitPrice('grip_ivory') > W.FitPrice('grip_wood'))
    eq(W.FitPrice('nope'), nil)
end)

test('parts: one per group, only what the record allows, game names', function()
    local rec = W.Record('weapon_revolver_cattleman')
    assert(W.CanFit(rec, 'grip_ivory'))
    assert(not W.CanFit(rec, 'scope_long'))
    local list = W.Fit({}, 'grip_wood')
    list = W.Fit(list, 'grip_ivory')
    eq(#list, 1) eq(list[1], 'grip_ivory')
    list = W.Fit(list, 'barrel_long')
    eq(#list, 2)
    list = W.Strip(list, 'grip_ivory')
    eq(#list, 1) eq(list[1], 'barrel_long')
    eq(W.ComponentName(rec, 'grip_ivory'), 'COMPONENT_REVOLVER_CATTLEMAN_GRIP_IVORY')
    local s = W.Stats(rec, { 'barrel_long' })
    eq(s.range, rec.stats.range + 1)
    for _, key in ipairs(rec.components) do assert(LXRShared.WeaponComponents[key], 'unknown component ' .. key) end
end)

test('ammunition pools and chambers', function()
    local rec = W.Record('weapon_revolver_cattleman')
    assert(W.AmmoClass('ammo_revolver'))
    assert(not W.AmmoClass('bread'))
    assert(W.Chambers(rec, 'ammo_revolver_express'))
    assert(not W.Chambers(rec, 'ammo_rifle'))
    eq(W.LoadedFor(rec, { ammo_revolver = 30, ammo_revolver_express = 6, ammo_rifle = 20 }), 36)
    eq(W.PoolCap('ammo_revolver'), Config.Ammo.maxPool)
    eq(W.PoolCap('ammo_rifle_elephant'), 20)
    for class in pairs(Config.Ammo.maxPoolByClass) do assert(LXRShared.AmmoClasses[class], 'cap for unknown class ' .. class) end
    for item in pairs(Config.Condition.care) do assert(LXRShared.Items[item], 'care item missing from catalog: ' .. item) end
end)


test('locale parity', function()
    local en, ka = Locale.Bundles.en, Locale.Bundles.ka
    local missing = {}
    for k in pairs(en) do if ka[k] == nil then missing[#missing + 1] = k end end
    eq(#missing, 0, 'ka missing: ' .. table.concat(missing, ', '))
    for _, g in ipairs({ 'barrel', 'sight', 'scope', 'grip', 'stock', 'rifling', 'finish', 'engrave', 'wrap' }) do assert(en['ui.group_' .. g], 'group label ' .. g) end
    for key, c in pairs(LXRShared.WeaponComponents) do assert(en['ui.group_' .. c.group], key .. ' group ' .. c.group .. ' has no label') end
end)

print(('%d passed, %d failed'):format(passed, failed))

if arg and arg[1] == '--mock' and arg[2] then
    Config.Lang = arg[3] or 'en'
    local function item(name, serial, q, comps, drawn)
        local rec = W.Record(name) local def = LXRShared.Items[name]
        return { slot = 0, name = name, label = def.label, serial = serial, quality = q, category = rec.category, categoryLabel = W.Category(rec).label, maker = rec.maker, era = rec.era, clip = rec.clip, value = def.value,
                 components = comps, fits = rec.components or {}, stats = W.Stats(rec, comps), base = rec.stats, ammo = rec.ammo, ammoTypes = rec.ammoTypes, drawn = drawn }
    end
    local parts = {}
    for key, c in pairs(LXRShared.WeaponComponents) do parts[key] = { label = c.label, group = c.group, price = W.FitPrice(key), stat = c.stat, cosmetic = c.cosmetic == true } end
    local data = {
        shop = { id = 'valentine', label = 'Valentine Gunsmith', priceMult = 1 },
        weapons = { item('weapon_revolver_cattleman', '12AXB3QK821ZPMV', 62, { 'grip_ivory', 'barrel_long' }, true), item('weapon_revolver_schofield', '55KLM1RT904ABCD', 18, {}, true),
                    item('weapon_repeater_winchester', '31QWE7RT002ZXCV', 88, { 'scope_short' }, false), item('weapon_shotgun_doublebarrel', '09PLM4ZX771QAZW', 100, {}, false), item('weapon_melee_knife', '77BNM2AS110EDCR', 41, {}, false) },
        parts = parts, ammo = { { class = 'ammo_revolver', label = 'Revolver Cartridges', n = 74 }, { class = 'ammo_revolver_express', label = 'Express Revolver Cartridges', n = 12 }, { class = 'ammo_repeater', label = 'Repeater Cartridges', n = 40 }, { class = 'ammo_shotgun', label = 'Buckshot Shells', n = 16 } },
        cash = 38.25, prices = { repairPct = Config.Prices.repairPct, repairMin = Config.Prices.repairMin, remove = W.RemovePrice(1), unload = 0 }, returnToSatchel = true,
    }
    local f = assert(io.open(arg[2], 'w'))
    f:write('window.__LXR_MOCK__ = ' .. json.encode({ action = 'open', data = data, locale = Lang.bundle(), lang = Config.Lang, brand = { name = 'The Land of Wolves', theme = 'night' } }) .. ';\n')
    f:close()
    print('mock written to ' .. arg[2])
end
os.exit(failed == 0 and 0 or 1)
