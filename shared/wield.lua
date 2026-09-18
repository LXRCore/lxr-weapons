--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-WEAPONS — Shared rules: holsters, wear, prices, components
     ═══════════════════════════════════════════════════════════════════════════
     Pure functions over the core's weapon records (LXRShared.Weapons,
     WeaponCategories, WeaponComponents, AmmoClasses). No natives, no state:
     the server, the client and the offline tests all run the same code.

     A loadout is { [serial] = { name, category, slot, attach } }: the guns
     the character currently carries on the ped.
     ═══════════════════════════════════════════════════════════════════════════
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

LXRWeapons = LXRWeapons or {}
local W = LXRWeapons

local function cats() return LXRShared.WeaponCategories or {} end
local function comps() return LXRShared.WeaponComponents or {} end

---The core record for an item name, model or hash.
function W.Record(ref) return LXRShared.GetWeapon and LXRShared.GetWeapon(ref) or nil end

---Is this item a weapon item at all.
function W.IsWeaponItem(name)
    local def = LXRShared.Items and LXRShared.Items[name]
    return def ~= nil and def.type == 'weapon' and W.Record(name) ~= nil
end

function W.Category(rec) return cats()[rec.category] or {} end

---Where a drawn weapon hangs: the first free attach point of its slot.
---@return integer|nil attach, string|nil why
function W.AttachFor(rec, loadout)
    local cat = W.Category(rec)
    local slot = rec.slot or cat.slot or 'sidearm'
    local points = Config.Wield.attach[slot] or Config.Wield.attach.sidearm
    local carried, used = 0, {}
    for _, l in pairs(loadout or {}) do
        if l.category == rec.category then carried = carried + 1 end
        if l.attach then used[l.attach] = true end
    end
    if carried >= (cat.maxCarry or 1) then return nil, 'too_many' end
    for i, p in ipairs(points) do
        if not used[p] then
            if slot == 'sidearm' and i > 1 and not (Config.Wield.dual and rec.dual) then return nil, 'no_dual' end
            return p
        end
    end
    return nil, 'no_holster'
end

---Condition after `shots` rounds.
function W.Degrade(quality, rec, shots)
    local per = (tonumber(rec.degrade) or 0.05) * (Config.Condition.degradeMult or 1)
    local q = (tonumber(quality) or 100) - per * math.max(0, tonumber(shots) or 0)
    return math.max(0, math.min(100, math.floor(q * 100 + 0.5) / 100))
end

function W.Jammed(quality) return (tonumber(quality) or 100) <= (Config.Condition.jamAt or 0) end

---Field care: what an item restores on a record, nil when it does not apply.
function W.CareFor(item, rec)
    local c = Config.Condition.care[item]
    if not c then return nil end
    if c.only then
        local ok = false
        for _, cat in ipairs(c.only) do if cat == rec.category then ok = true end end
        if not ok then return nil end
    end
    return c.restore
end

local function round2(n) return math.floor(n * 100 + 0.5) / 100 end

---Gunsmith repair from `quality` to 100, on the item's 1899 value.
function W.RepairPrice(def, quality, mult)
    local value = tonumber(def and def.value) or 0
    local missing = math.max(0, 100 - (tonumber(quality) or 100)) / 100
    if missing <= 0 then return 0 end
    local p = math.max(Config.Prices.repairMin, value * Config.Prices.repairPct * missing)
    return round2(p * (mult or 1))
end

function W.CanFit(rec, key)
    for _, k in ipairs(rec.components or {}) do if k == key then return comps()[key] ~= nil end end
    return false
end

function W.FitPrice(key, mult)
    local c = comps()[key]
    if not c then return nil end
    return round2(((c.price or 0) * (Config.Prices.componentMult or 1) + Config.Prices.fitLabour) * (mult or 1))
end

function W.RemovePrice(mult) return round2(Config.Prices.removeLabour * (mult or 1)) end

---New component list with `key` fitted (one per group when configured).
function W.Fit(list, key)
    local c = comps()[key]
    local out = {}
    for _, k in ipairs(list or {}) do
        local other = comps()[k]
        if k ~= key and not (Config.Components.oneOfGroup and c and other and other.group == c.group) then out[#out + 1] = k end
    end
    out[#out + 1] = key
    return out
end

function W.Strip(list, key)
    local out = {}
    for _, k in ipairs(list or {}) do if k ~= key then out[#out + 1] = k end end
    return out
end

---Game component name for a fitted part.
function W.ComponentName(rec, key)
    local o = Config.Components.names[key]
    local part = o and o.part or key:upper()
    local model = rec.name:upper():gsub('^WEAPON_', '')
    return (Config.Components.pattern):format(model, part)
end

---Stats 1–10 with the fitted parts applied.
function W.Stats(rec, list)
    local out = {}
    for k, v in pairs(rec.stats or {}) do out[k] = v end
    for _, key in ipairs(list or {}) do
        local c = comps()[key]
        for k, d in pairs(c and c.stat or {}) do out[k] = math.max(1, math.min(10, (out[k] or 5) + d)) end
    end
    return out
end

---Rounds of a calibre a character may hold loaded.
function W.PoolCap(class) return Config.Ammo.maxPoolByClass[class] or Config.Ammo.maxPool end

---Cartridge item → class record, nil for anything else.
function W.AmmoClass(item) return LXRShared.AmmoClasses and LXRShared.AmmoClasses[item] or nil end

---Does the record chamber this cartridge.
function W.Chambers(rec, item)
    for _, a in ipairs(rec.ammoTypes or {}) do if a == item then return true end end
    return rec.ammo == item
end

---Total loaded rounds a record can fire from a pool table { class = n }.
function W.LoadedFor(rec, pool)
    local n = 0
    for _, a in ipairs(rec.ammoTypes or {}) do n = n + (tonumber(pool and pool[a]) or 0) end
    if #(rec.ammoTypes or {}) == 0 and rec.ammo then n = tonumber(pool and pool[rec.ammo]) or 0 end
    return n
end
