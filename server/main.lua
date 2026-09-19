--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-WEAPONS — Server: loadout, ammunition pools, wear, gunsmith
     ═══════════════════════════════════════════════════════════════════════════
     The server owns everything that matters:
       • the loadout — which serials are on the ped and where they hang
       • the ammunition pools — rounds per calibre in character metadata
       • condition — info.quality on the item, worn down by reported shots
       • the gunsmith ledger — repair, parts, engravings, unloading

     The client only mirrors: it gives the game ped what the server says it
     carries, sets the pools on the ped, and reports shots in batches.
     ═══════════════════════════════════════════════════════════════════════════
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

local LXRCore = exports['lxr-core']:GetCoreObject()
local LXR = exports['lxr-core']:GetLXR()
local W = LXRWeapons
local Inventory = LXRCore.Inventory
local RES = GetCurrentResourceName()

local loadouts = {}   -- src → { [serial] = { name, slot(inventory), category, attach, hash } }
local buckets = {}
local warned = {}     -- src → { [serial] = { [threshold] = true } }

local function limited(src)
    local b = buckets[src]
    local now = GetGameTimer()
    if not b or now - b.at > Config.Security.rateLimit.windowMs then b = { at = now, n = 0 } buckets[src] = b end
    b.n = b.n + 1
    return b.n > Config.Security.rateLimit.burst
end
local function player(src) return LXRCore.Functions.GetPlayer(src) end
local function notify(src, key, kind, vars) LXRCore.Notify(src, Lang:t(key, vars), kind or 'info') end
local function log(msg, data) if Config.Debug.log then LXRCore.Log.info('weapons', msg, data) end end
local function shopFor(id) for _, s in ipairs(Config.Gunsmiths) do if s.id == id then return s end end end
local function near(src, coords, dist)
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end
    return #(GetEntityCoords(ped) - vector3(coords.x, coords.y, coords.z)) <= dist
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🎒 SATCHEL HELPERS — always look the item up again, never trust the client
-- ═══════════════════════════════════════════════════════════════════════════════
local function slotBySerial(src, serial)
    for slot, it in pairs(Inventory.GetItems(src) or {}) do
        if it and it.info and it.info.serie == serial and W.IsWeaponItem(it.name) then return tonumber(slot), it end
    end
end

local function quality(it) return tonumber(it.info and it.info.quality) or 100 end
local function components(it) return (it.info and type(it.info.components) == 'table') and it.info.components or {} end

local function setInfo(src, slot, it, patch)
    local info = {}
    for k, v in pairs(it.info or {}) do info[k] = v end
    for k, v in pairs(patch) do info[k] = v end
    Inventory.SetMetadata(src, slot, info)
    it.info = info
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🔫 AMMUNITION POOLS — metadata.ammo = { [cartridge item] = rounds }
-- ═══════════════════════════════════════════════════════════════════════════════
local function pools(P)
    local a = P.PlayerData.metadata.ammo
    if type(a) ~= 'table' then a = {} end
    return a
end
local function savePools(P, a)
    local clean = {}
    for k, v in pairs(a) do v = math.floor(tonumber(v) or 0) if v > 0 then clean[k] = v end end
    P.Functions.SetMetaData('ammo', clean)
    return clean
end
local function syncAmmo(src, P)
    TriggerClientEvent('lxr-weapons:client:ammo', src, pools(P))
end

local function addAmmo(src, class, n)
    local P = player(src)
    if not P or not W.AmmoClass(class) then return 0 end
    local a = pools(P)
    local before = tonumber(a[class]) or 0
    local after = math.max(0, math.min(W.PoolCap(class), before + (tonumber(n) or 0)))
    a[class] = after
    savePools(P, a)
    syncAmmo(src, P)
    return after - before
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🧤 LOADOUT
-- ═══════════════════════════════════════════════════════════════════════════════
local function loadoutOf(src) loadouts[src] = loadouts[src] or {} return loadouts[src] end

local function drawnName(src)
    for _, l in pairs(loadoutOf(src)) do if l.inHand then return l.name end end
end
local function publish(src)
    Player(src).state:set('weapon', drawnName(src) or false, true)
end

local function give(src, serial, it, rec, attach, inHand)
    local l = loadoutOf(src)
    l[serial] = { name = it.name, category = rec.category, attach = attach, hash = rec.hash, inHand = inHand }
    TriggerClientEvent('lxr-weapons:client:give', src, {
        name = it.name, hash = rec.hash, serial = serial, attach = attach, inHand = inHand,
        quality = quality(it), components = components(it), label = it.label,
    })
    LXRCore.Emit('lxr:weapons:drawn', nil, src, it.name, serial)
    publish(src)
end

local function takeBack(src, serial, reason)
    local l = loadoutOf(src)
    local e = l[serial]
    if not e then return end
    l[serial] = nil
    TriggerClientEvent('lxr-weapons:client:take', src, { serial = serial, hash = e.hash, attach = e.attach, reason = reason })
    LXRCore.Emit('lxr:weapons:holstered', nil, src, e.name, serial, reason)
    publish(src)
end

local function disarm(src, reason)
    for serial in pairs(loadoutOf(src)) do takeBack(src, serial, reason or 'disarm') end
end

-- using the weapon item: draw, or holster if it is already out
local function useWeapon(src, item)
    local P = player(src)
    local rec = W.Record(item.name)
    if not P or not rec then return end
    local serial = item.info and item.info.serie
    local slot, it = slotBySerial(src, serial)
    if not slot then return notify(src, 'error.not_yours', 'error') end
    if loadoutOf(src)[serial] then return takeBack(src, serial, 'holster') end
    local attach, why = W.AttachFor(rec, loadoutOf(src))
    if not attach then return notify(src, 'error.' .. why, 'error', { label = it.label }) end
    give(src, serial, it, rec, attach, Config.Wield.drawInHand)
    log('drawn', { source = src, item = it.name, serial = serial })
end

-- using a cartridge item: how many rounds the pool can take from this stack
local function loadable(src, P, name, slot)
    local held = Inventory.GetItem(src, name, tonumber(slot)) or Inventory.GetItem(src, name)
    if not held then return nil end
    local want = Config.Ammo.loadPerUse > 0 and math.min(Config.Ammo.loadPerUse, held.amount) or held.amount
    local room = W.PoolCap(name) - (tonumber(pools(P)[name]) or 0)
    return held, math.min(want, room)
end

-- using a cartridge item: the client plays the loading, then confirms; the rounds move on the confirm
local loading = {}   -- src → { name, slot, at }
local function useAmmo(src, item)
    local P = player(src)
    local class = W.AmmoClass(item.name)
    if not P or not class then return end
    local held, n = loadable(src, P, item.name, item.slot)
    if not held then return end
    if n <= 0 then return notify(src, 'error.pool_full', 'error', { label = held.label }) end
    if loading[src] and GetGameTimer() - loading[src].at < Config.Ammo.loadMs + 2000 then return end
    loading[src] = { name = item.name, slot = held.slot, at = GetGameTimer() }
    TriggerClientEvent('lxr-weapons:client:load', src, { item = item.name, label = held.label, n = n, ms = Config.Ammo.loadMs })
end
RegisterNetEvent('lxr-weapons:server:loaded', function(name)
    local src = source
    if limited(src) then return end
    local pending = loading[src]
    loading[src] = nil
    local P = player(src)
    if not P or not pending or pending.name ~= name or not W.AmmoClass(name) then return end
    local held, n = loadable(src, P, name, pending.slot)
    if not held or n <= 0 then return end
    if not Inventory.RemoveItem(src, name, n, held.slot, 'ammo loaded') then return end
    addAmmo(src, name, n)
    notify(src, 'info.loaded', 'success', { n = n, label = held.label })
end)

-- field care on the gun in hand
local function useCare(src, item)
    local P = player(src)
    if not P then return end
    local serial
    for s, l in pairs(loadoutOf(src)) do if l.inHand then serial = s end end
    if not serial then return notify(src, 'error.nothing_in_hand', 'error') end
    local slot, it = slotBySerial(src, serial)
    if not slot then return end
    local rec = W.Record(it.name)
    local restore = W.CareFor(item.name, rec)
    if not restore then return notify(src, 'error.wrong_care', 'error') end
    if quality(it) >= 100 then return notify(src, 'error.pristine', 'error') end
    TriggerClientEvent('lxr-weapons:client:care', src, { item = item.name, label = LXRShared.Items[item.name].label, ms = Config.Condition.careMs, serial = serial })
end

RegisterNetEvent('lxr-weapons:server:cared', function(item, serial)
    local src = source
    if limited(src) then return end
    local P = player(src)
    local def = LXRShared.Items[item]
    if not P or not def or not Config.Condition.care[item] then return end
    local held = Inventory.GetItem(src, item)
    if not held then return end
    local slot, it = slotBySerial(src, serial)
    if not slot or not loadoutOf(src)[serial] then return end
    local rec = W.Record(it.name)
    local restore = W.CareFor(item, rec)
    if not restore then return end
    if def.use and def.use.consume == false then
        -- durable tools wear a little instead of vanishing
        local q = quality(held) - 5
        if q <= 0 then Inventory.RemoveItem(src, item, 1, held.slot, 'worn out') else
            local info = {} for k, v in pairs(held.info or {}) do info[k] = v end info.quality = q
            Inventory.SetMetadata(src, held.slot, info)
        end
    else
        if not Inventory.RemoveItem(src, item, 1, held.slot, 'weapon care') then return end
    end
    local q = math.min(100, quality(it) + restore)
    setInfo(src, slot, it, { quality = q })
    warned[src] = warned[src] or {} warned[src][serial] = nil
    TriggerClientEvent('lxr-weapons:client:condition', src, serial, q)
    notify(src, 'info.cared', 'success', { label = it.label, q = math.floor(q) })
end)

-- shots reported by the client: wear + pool
RegisterNetEvent('lxr-weapons:server:shots', function(serial, n, class)
    local src = source
    if limited(src) then return end
    local P = player(src)
    n = math.floor(tonumber(n) or 0)
    if not P or n <= 0 then return end
    if n > Config.Security.maxShotsPerReport then
        return LXRCore.Log.exploit('weapons', 'impossible shot count', { source = src, n = n, serial = serial })
    end
    local e = loadoutOf(src)[serial]
    if not e then return end
    local slot, it = slotBySerial(src, serial)
    if not slot then return takeBack(src, serial, 'lost') end
    local rec = W.Record(it.name)
    -- pool
    if type(class) == 'string' and W.Chambers(rec, class) then
        local a = pools(P)
        a[class] = math.max(0, (tonumber(a[class]) or 0) - n)
        savePools(P, a)
    end
    -- wear
    local q = W.Degrade(quality(it), rec, n)
    if q ~= quality(it) then
        setInfo(src, slot, it, { quality = q })
        warned[src] = warned[src] or {} warned[src][serial] = warned[src][serial] or {}
        for _, th in ipairs(Config.Condition.warnAt) do
            if q <= th and not warned[src][serial][th] then warned[src][serial][th] = true notify(src, 'info.wearing', 'warning', { label = it.label, q = math.floor(q) }) end
        end
        TriggerClientEvent('lxr-weapons:client:condition', src, serial, q)
        if W.Jammed(q) then notify(src, 'error.jammed', 'error', { label = it.label }) end
    end
end)

-- the client saw the gun leave the ped (satchel removal, drop) — confirm and forget it
RegisterNetEvent('lxr-weapons:server:gone', function(serial)
    local src = source
    if limited(src) then return end
    if not loadoutOf(src)[serial] then return end
    if slotBySerial(src, serial) then return end -- still in the satchel: the client is wrong, give it back
    takeBack(src, serial, 'gone')
end)

RegisterNetEvent('lxr-weapons:server:inHand', function(serial)
    local src = source
    if limited(src) then return end
    local l = loadoutOf(src)
    for s, e in pairs(l) do e.inHand = (s == serial) end
    publish(src)
end)

-- the satchel changed: anything on the ped that is no longer owned comes off
AddEventHandler('lxr:inventory:changed', function(src)
    local l = loadouts[src]
    if not l then return end
    for serial in pairs(l) do if not slotBySerial(src, serial) then takeBack(src, serial, 'lost') end end
end)

AddEventHandler('lxr:meta:changed', function(src, key, val)
    if key == 'isdead' and val and Config.Wield.dropOnDeath then disarm(src, 'death') end
end)

RegisterNetEvent('lxr-weapons:server:ready', function()
    local src = source
    local P = player(src)
    if not P then return end
    if Config.Wield.holsterOnLogout then loadouts[src] = {} end
    syncAmmo(src, P)
    publish(src)
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🔨 GUNSMITH
-- ═══════════════════════════════════════════════════════════════════════════════
local function catalogue(src)
    local out = {}
    for slot, it in pairs(Inventory.GetItems(src) or {}) do
        if it and W.IsWeaponItem(it.name) then
            local rec = W.Record(it.name)
            local def = LXRShared.Items[it.name]
            out[#out + 1] = {
                slot = tonumber(slot), name = it.name, label = def.label, serial = it.info and it.info.serie, quality = quality(it),
                category = rec.category, categoryLabel = W.Category(rec).label, maker = rec.maker, era = rec.era, clip = rec.clip, value = def.value,
                components = components(it), fits = rec.components or {}, stats = W.Stats(rec, components(it)), base = rec.stats,
                ammo = rec.ammo, ammoTypes = rec.ammoTypes, drawn = loadoutOf(src)[it.info and it.info.serie] ~= nil,
            }
        end
    end
    table.sort(out, function(a, b) return a.slot < b.slot end)
    return out
end

local function panel(src, shop)
    local P = player(src)
    local parts = {}
    for key, c in pairs(LXRShared.WeaponComponents) do
        parts[key] = { label = c.label, group = c.group, price = W.FitPrice(key, shop.priceMult), stat = c.stat, cosmetic = c.cosmetic == true, rarity = c.rarity }
    end
    local ammo = {}
    for class, n in pairs(pools(P)) do ammo[#ammo + 1] = { class = class, label = LXRShared.Items[class] and LXRShared.Items[class].label or class, n = n } end
    table.sort(ammo, function(a, b) return a.class < b.class end)
    return {
        shop = { id = shop.id, label = shop.label, priceMult = shop.priceMult or 1 },
        weapons = catalogue(src), parts = parts, ammo = ammo, cash = P.PlayerData.money.cash,
        prices = { repairPct = Config.Prices.repairPct, repairMin = Config.Prices.repairMin, remove = W.RemovePrice(shop.priceMult), unload = Config.Prices.unload },
        returnToSatchel = Config.Ammo.returnToSatchel,
    }
end

LXR.RPC.Register('lxr-weapons:gunsmith:open', function(src, shopId)
    if limited(src) then return false, 'rate' end
    local shop = shopFor(shopId)
    if not player(src) or not shop then return false, 'invalid' end
    if not near(src, shop.coords, Config.Security.gunsmithDistance) then return false, 'too_far' end
    return true, panel(src, shop), Lang.bundle(), LXRCore.Brand
end)

local function charge(P, amount)
    if amount <= 0 then return true end
    if P.PlayerData.money.cash < amount then return false end
    return P.Functions.RemoveMoney('cash', amount, 'gunsmith')
end

LXR.RPC.Register('lxr-weapons:gunsmith:repair', function(src, shopId, serial)
    if limited(src) then return false, 'rate' end
    local P, shop = player(src), shopFor(shopId)
    if not P or not shop or not near(src, shop.coords, Config.Security.gunsmithDistance) then return false, 'invalid' end
    local slot, it = slotBySerial(src, serial)
    if not slot then return false, 'invalid' end
    local price = W.RepairPrice(LXRShared.Items[it.name], quality(it), shop.priceMult)
    if price <= 0 then return false, 'pristine' end
    if not charge(P, price) then return false, 'no_money', price end
    setInfo(src, slot, it, { quality = 100 })
    warned[src] = warned[src] or {} warned[src][serial] = nil
    if loadoutOf(src)[serial] then TriggerClientEvent('lxr-weapons:client:condition', src, serial, 100) end
    log('repair', { source = src, serial = serial, price = price })
    return true, panel(src, shop), price
end)

LXR.RPC.Register('lxr-weapons:gunsmith:fit', function(src, shopId, serial, key)
    if limited(src) then return false, 'rate' end
    local P, shop = player(src), shopFor(shopId)
    if not P or not shop or not near(src, shop.coords, Config.Security.gunsmithDistance) then return false, 'invalid' end
    local slot, it = slotBySerial(src, serial)
    if not slot then return false, 'invalid' end
    local rec = W.Record(it.name)
    if type(key) ~= 'string' or not W.CanFit(rec, key) then return false, 'no_fit' end
    for _, k in ipairs(components(it)) do if k == key then return false, 'fitted' end end
    local price = W.FitPrice(key, shop.priceMult)
    if not charge(P, price) then return false, 'no_money', price end
    local list = W.Fit(components(it), key)
    setInfo(src, slot, it, { components = list })
    if loadoutOf(src)[serial] then TriggerClientEvent('lxr-weapons:client:components', src, serial, rec.hash, list) end
    log('fit', { source = src, serial = serial, key = key, price = price })
    return true, panel(src, shop), price
end)

LXR.RPC.Register('lxr-weapons:gunsmith:strip', function(src, shopId, serial, key)
    if limited(src) then return false, 'rate' end
    local P, shop = player(src), shopFor(shopId)
    if not P or not shop or not near(src, shop.coords, Config.Security.gunsmithDistance) then return false, 'invalid' end
    local slot, it = slotBySerial(src, serial)
    if not slot then return false, 'invalid' end
    local has = false
    for _, k in ipairs(components(it)) do if k == key then has = true end end
    if not has then return false, 'invalid' end
    local price = W.RemovePrice(shop.priceMult)
    if not charge(P, price) then return false, 'no_money', price end
    local rec = W.Record(it.name)
    local list = W.Strip(components(it), key)
    setInfo(src, slot, it, { components = list })
    if loadoutOf(src)[serial] then TriggerClientEvent('lxr-weapons:client:components', src, serial, rec.hash, list) end
    return true, panel(src, shop), price
end)

LXR.RPC.Register('lxr-weapons:gunsmith:unload', function(src, shopId, class)
    if limited(src) then return false, 'rate' end
    local P, shop = player(src), shopFor(shopId)
    if not P or not shop or not near(src, shop.coords, Config.Security.gunsmithDistance) then return false, 'invalid' end
    if not Config.Ammo.returnToSatchel or not W.AmmoClass(class) then return false, 'invalid' end
    local a = pools(P)
    local n = math.floor(tonumber(a[class]) or 0)
    if n <= 0 then return false, 'invalid' end
    if not Inventory.CanCarry(src, class, n) then return false, 'too_heavy' end
    if not charge(P, Config.Prices.unload) then return false, 'no_money', Config.Prices.unload end
    a[class] = 0
    savePools(P, a)
    Inventory.AddItem(src, class, n, nil, nil, 'ammo unloaded')
    syncAmmo(src, P)
    return true, panel(src, shop), n
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🚀 BOOT — register every weapon, cartridge and care item as usable
-- ═══════════════════════════════════════════════════════════════════════════════
CreateThread(function()
    local guns, ammo, care = 0, 0, 0
    for name, def in pairs(LXRShared.Items) do
        if def.type == 'weapon' and W.Record(name) then LXRCore.Items.RegisterUsable(name, useWeapon) guns = guns + 1
        elseif W.AmmoClass(name) then LXRCore.Items.RegisterUsable(name, useAmmo) ammo = ammo + 1
        elseif Config.Condition.care[name] then LXRCore.Items.RegisterUsable(name, useCare) care = care + 1 end
    end
    if Config.Debug.printBanner then
        print(('^1[lxr-weapons]^7 v%s — %d weapons, %d cartridges, %d care items usable; %d gunsmiths'):format(GetResourceMetadata(RES, 'version', 0), guns, ammo, care, #Config.Gunsmiths))
    end
end)

AddEventHandler('playerDropped', function() loadouts[source] = nil buckets[source] = nil warned[source] = nil loading[source] = nil end)
AddEventHandler('lxr:player:unloaded', function(src) loadouts[src] = nil warned[src] = nil end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- 📤 EXPORTS
-- ═══════════════════════════════════════════════════════════════════════════════
exports('GetLoadout', function(src) return loadoutOf(src) end)
exports('GetDrawn', drawnName)
exports('IsArmed', function(src) return next(loadoutOf(src)) ~= nil end)
exports('Disarm', disarm)
exports('Holster', function(src, serial) takeBack(src, serial, 'holster') end)
exports('GetAmmo', function(src, class) local P = player(src) return P and (tonumber(pools(P)[class]) or 0) or 0 end)
exports('AddAmmo', addAmmo)
exports('SetQuality', function(src, serial, q)
    local slot, it = slotBySerial(src, serial)
    if not slot then return false end
    q = math.max(0, math.min(100, tonumber(q) or 100))
    setInfo(src, slot, it, { quality = q })
    if loadoutOf(src)[serial] then TriggerClientEvent('lxr-weapons:client:condition', src, serial, q) end
    return true
end)
exports('Catalogue', catalogue)
