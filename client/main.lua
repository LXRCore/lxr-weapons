--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-WEAPONS — Client: the ped mirrors the server's loadout
     ═══════════════════════════════════════════════════════════════════════════
     Nothing here decides anything. The server says "carry this serial at
     this attach point with this condition", the client gives it to the ped;
     the server says "these pools", the client sets the ped's ammunition;
     the ped's ammunition drops, the client reports the shots. One thread
     runs only while something is carried; the gunsmith is prompts + NUI.
     ═══════════════════════════════════════════════════════════════════════════
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

local LXRCore = exports['lxr-core']:GetCoreObject()
local LXR = exports['lxr-core']:GetLXR()
local W = LXRWeapons
local N = Citizen.InvokeNative

local carried = {}      -- serial → { name, hash, attach, quality, components, inHand }
local pools = {}        -- class item → rounds (server copy)
local lastAmmo = {}     -- class item → rounds last seen on the ped
local inHand = nil      -- serial currently in the hands
local running = false
local session = nil     -- gunsmith session { shop }
local blips = {}

local ADD_DEFAULT = joaat('ADD_REASON_DEFAULT')
local REMOVE_DEFAULT = joaat('REMOVE_REASON_DEFAULT')
local UNARMED = joaat('WEAPON_UNARMED')

local function ped() return PlayerPedId() end
local function toast(key, kind, vars) LXRCore.Notify(Lang:t(key, vars), kind or 'info') end

-- the inspection dictionary for a carried gun (by the core record's category)
local function inspectDict(e)
    local rec = e and W.Record(e.name)
    return rec and Config.Inspect.dicts[rec.category] or nil
end
local function loadDict(dict)
    if not dict then return false end
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local t = GetGameTimer() + 2000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < t do Wait(10) end
    return HasAnimDictLoaded(dict)
end


-- ═══════════════════════════════════════════════════════════════════════════════
-- 🔫 GIVE / TAKE
-- ═══════════════════════════════════════════════════════════════════════════════
local function weaponObject(attach)
    local obj = GetCurrentPedWeaponEntityIndex(ped(), attach)
    if obj and obj ~= 0 then return obj end
end

local function applyCondition(e)
    if not e then return end
    local obj = weaponObject(e.attach)
    if obj then SetWeaponDegradation(obj, 1.0 - (e.quality or 100) / 100) end
end

local function applyComponents(e)
    local rec = W.Record(e.name)
    if not rec then return end
    for _, key in ipairs(e.components or {}) do
        GiveWeaponComponentToEntity(ped(), joaat(W.ComponentName(rec, key)), e.hash, true)
    end
end

-- the ped's rounds follow the server's pools: by difference, with the add / remove natives — a plain
-- SET on a calibre the ped holds no weapon for is ignored by the game (arrows, throwables), a delta is not
local function setPoolsOnPed()
    local p = ped()
    for class, c in pairs(LXRShared.AmmoClasses) do
        local want = tonumber(pools[class]) or 0
        local have = GetPedAmmoByType(p, c.hash)
        if want > have then AddAmmoToPedByType(p, c.hash, want - have, ADD_DEFAULT)
        elseif want < have then RemoveAmmoFromPedByType(p, c.hash, have - want, REMOVE_DEFAULT) end
        lastAmmo[class] = want
    end
end

local function give(d)
    local p = ped()
    if not HasWeaponAssetLoaded(d.hash) then
        RequestWeaponAsset(d.hash, 31, 0)
        local t = GetGameTimer() + 3000
        while not HasWeaponAssetLoaded(d.hash) and GetGameTimer() < t do Wait(10) end
    end
    GiveWeaponToPed(p, d.hash, 0, d.inHand == true, d.inHand ~= true, d.attach, false, 0.5, 1.0, ADD_DEFAULT, true, 0.0, false)
    carried[d.serial] = { name = d.name, hash = d.hash, attach = d.attach, quality = d.quality or 100, components = d.components or {}, inHand = d.inHand }
    if Config.Wield.dual then SetAllowDualWield(p, true) end
    Wait(50)
    setPoolsOnPed()
    applyComponents(carried[d.serial])
    applyCondition(carried[d.serial])
    if d.inHand then inHand = d.serial end
    running = true
end

local function take(d)
    local p = ped()
    local e = carried[d.serial]
    carried[d.serial] = nil
    if inHand == d.serial then inHand = nil end
    if e and HasPedGotWeapon(p, e.hash, 0, false) then
        RemoveWeaponFromPed(p, e.hash, true, REMOVE_DEFAULT)
        -- a twin of the same model stays: give it back
        for _, other in pairs(carried) do
            if other.hash == e.hash then
                GiveWeaponToPed(p, other.hash, 0, false, true, other.attach, false, 0.5, 1.0, ADD_DEFAULT, true, 0.0, false)
                Wait(50)
                applyComponents(other) applyCondition(other)
            end
        end
    end
    if d.reason == 'death' or d.reason == 'disarm' then
        -- nothing to say, the server already did
    elseif d.reason == 'holster' then toast('info.holstered', 'info', { label = e and (LXRShared.Items[e.name] or {}).label or '' })
    end
end

RegisterNetEvent('lxr-weapons:client:give', function(d) give(d) end)
RegisterNetEvent('lxr-weapons:client:take', function(d) take(d) end)
RegisterNetEvent('lxr-weapons:client:ammo', function(a) pools = a or {} setPoolsOnPed() end)
RegisterNetEvent('lxr-weapons:client:condition', function(serial, q)
    local e = carried[serial]
    if not e then return end
    e.quality = q
    applyCondition(e)
end)
RegisterNetEvent('lxr-weapons:client:components', function(serial, hash, list)
    local e = carried[serial]
    if not e then return end
    local rec = W.Record(e.name)
    for _, key in ipairs(e.components or {}) do RemoveWeaponComponentFromPed(ped(), joaat(W.ComponentName(rec, key)), hash) end
    e.components = list or {}
    applyComponents(e)
end)

-- the satchel lost a weapon item (lxr-inventory tells us by name); the server confirms by serial
RegisterNetEvent('lxr-weapons:client:removed', function(name)
    for serial, e in pairs(carried) do
        if e.name == name then TriggerServerEvent('lxr-weapons:server:gone', serial) end
    end
end)

-- loading rounds: progress with the cartridge-handling animation and the calibre's box, then the server moves them
local function loadProp(item)
    for prefix, model in pairs(Config.Ammo.loadProps or {}) do
        if item:sub(1, #prefix) == prefix and (item:sub(#prefix + 1, #prefix + 1) == '' or item:sub(#prefix + 1, #prefix + 1) == '_') then return model end
    end
end
RegisterNetEvent('lxr-weapons:client:load', function(d)
    if exports['lxr-nui']:IsProgressActive() then return end
    local p = ped()
    local a = Config.Ammo.loadAnim
    local prop
    if a and a.dict then
        RequestAnimDict(a.dict)
        local t = GetGameTimer() + 2000
        while not HasAnimDictLoaded(a.dict) and GetGameTimer() < t do Wait(10) end
        if HasAnimDictLoaded(a.dict) then TaskPlayAnim(p, a.dict, a.clip, 4.0, -4.0, -1, 31, 0.0, false, false, false)
        else print(('^3[lxr-weapons]^7 load: animation dictionary %s did not load'):format(a.dict)) end
    end
    local model = loadProp(d.item or '')
    if model then
        local hash = joaat(model)
        RequestModel(hash)
        local t = GetGameTimer() + 2000
        while not HasModelLoaded(hash) and GetGameTimer() < t do Wait(10) end
        if HasModelLoaded(hash) then
            local c = GetEntityCoords(p)
            prop = CreateObject(hash, c.x, c.y, c.z, true, true, false)
            AttachEntityToEntity(prop, p, GetEntityBoneIndexByName(p, 'SKEL_L_Hand'), 0.08, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
            SetModelAsNoLongerNeeded(hash)
        end
    end
    local done = nil
    exports['lxr-nui']:Progress({ label = Lang:t('ui.loading', { label = d.label, n = d.n }), duration = d.ms or 2500, canCancel = true }, function(ok) done = ok end)
    while done == nil do Wait(50) end
    ClearPedTasks(p)
    if prop then DeleteEntity(prop) end
    if a and a.dict then RemoveAnimDict(a.dict) end
    if done then TriggerServerEvent('lxr-weapons:server:loaded', d.item) end
end)

-- field care: progress while holding the gun, then the server applies it
RegisterNetEvent('lxr-weapons:client:care', function(d)
    if exports['lxr-nui']:IsProgressActive() then return end
    local done = nil
    local dict = inspectDict(carried[d.serial])
    if loadDict(dict) then TaskPlayAnim(ped(), dict, 'clean_loop', 4.0, -4.0, -1, 1, 0.0, false, false, false) end
    exports['lxr-nui']:Progress({ label = Lang:t('ui.caring', { label = d.label }), duration = d.ms, canCancel = true }, function(ok) done = ok end)
    while done == nil do Wait(50) end
    ClearPedTasks(ped())
    if dict then RemoveAnimDict(dict) end
    if done then TriggerServerEvent('lxr-weapons:server:cared', d.item, d.serial) end
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🔁 THE ONE THREAD — hands, shots, jams. Runs only while something is carried.
-- ═══════════════════════════════════════════════════════════════════════════════
-- damage modifiers follow the gun in hand (Config.Combat.damage)
local function applyDamage(e)
    local rec = e and W.Record(e.name)
    local d = Config.Combat.damage
    local mult = rec and (d.byCategory[rec.category] or d.ranged) or d.ranged
    SetPlayerWeaponDamageModifier(PlayerId(), mult + 0.0)
    SetPlayerMeleeWeaponDamageModifier(PlayerId(), (d.melee or 1.0) + 0.0)
end
local infinite = false
RegisterNetEvent('lxr-weapons:client:infiniteAmmo', function()
    infinite = not infinite
    SetPedInfiniteAmmoClip(ped(), infinite)
    toast(infinite and 'info.infinite_on' or 'info.infinite_off', 'info')
end)

-- /inspect: turn the gun in the hands
local inspecting = false
local function inspect()
    if inspecting then return end
    local e = inHand and carried[inHand]
    local dict = inspectDict(e)
    if not dict then return toast('error.nothing_to_inspect', 'error') end
    if not loadDict(dict) then return end
    inspecting = true
    local p = ped()
    TaskPlayAnim(p, dict, 'base_enter', 4.0, -4.0, -1, 0, 0.0, false, false, false)
    Wait(900)
    TaskPlayAnim(p, dict, 'base_sweep', 4.0, -4.0, -1, 0, 0.0, false, false, false)
    Wait(2600)
    TaskPlayAnim(p, dict, 'base_exit', 4.0, -4.0, -1, 0, 0.0, false, false, false)
    Wait(800)
    RemoveAnimDict(dict)
    inspecting = false
end
RegisterCommand(Config.Inspect.command or 'inspect', function() CreateThread(inspect) end, false)

local function serialInHand()
    local ok, hash = GetCurrentPedWeapon(ped(), true, 0, false)
    if not ok or not hash or hash == UNARMED then return nil end
    local pick
    for serial, e in pairs(carried) do
        if e.hash == hash then
            if serial == inHand then return serial end
            pick = pick or serial
        end
    end
    return pick
end

local function reportShots()
    local p = ped()
    local fired = {}
    for class, c in pairs(LXRShared.AmmoClasses) do
        local n = GetPedAmmoByType(p, c.hash)
        local last = lastAmmo[class] or 0
        if n < last then fired[class] = last - n
        elseif n > last and n > (tonumber(pools[class]) or 0) then
            -- the ped gained rounds the server never gave: put it back
            SetPedAmmoByType(p, c.hash, tonumber(pools[class]) or 0)
            n = tonumber(pools[class]) or 0
        end
        lastAmmo[class] = n
    end
    if not next(fired) then return end
    for class, n in pairs(fired) do
        pools[class] = math.max(0, (tonumber(pools[class]) or 0) - n)
        local serial = inHand
        if not serial then
            for s, e in pairs(carried) do local rec = W.Record(e.name) if rec and W.Chambers(rec, class) then serial = s break end end
        end
        if serial then TriggerServerEvent('lxr-weapons:server:shots', serial, n, class) end
    end
end

CreateThread(function()
    local nextReport = 0
    local lastHand = false
    while true do
        if not running then Wait(500) else
            if not next(carried) then running = false else
                local now = GetGameTimer()
                local s = serialInHand()
                if s ~= inHand then
                    inHand = s
                    for serial, e in pairs(carried) do e.inHand = (serial == s) end
                    TriggerServerEvent('lxr-weapons:server:inHand', s)
                end
                local e = s and carried[s]
                if s ~= lastHand then lastHand = s applyDamage(e) end
                if e and W.Jammed(e.quality) then
                    DisableControlAction(0, 0x07CE1E61, true) -- attack
                    DisableControlAction(0, 0xF84FA74F, true) -- aim
                    Wait(0)
                elseif e and Config.Combat.noSprintWhileAiming and IsPlayerFreeAiming(PlayerId()) then
                    DisableControlAction(0, 0x8FFC75D6, true) -- sprint, only while aiming
                    Wait(0)
                else
                    Wait(150)
                end
                if now >= nextReport then nextReport = now + Config.Condition.reportEveryMs reportShots() end
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🔨 GUNSMITH — prompts, blips, NUI
-- ═══════════════════════════════════════════════════════════════════════════════
-- the counter camera: one scripted cam on the hands; the page nudges it (drag turns the ped, wheel zooms, W/S height)
local cam = nil
local camState = { fov = 28.0, h = 0.0 }
local function camUpdate()
    local C = Config.GunsmithCamera
    local p = ped()
    local pos = GetOffsetFromEntityInWorldCoords(p, C.offset.x, C.offset.y, C.offset.z + camState.h)
    local look = GetOffsetFromEntityInWorldCoords(p, C.look.x, C.look.y, C.look.z + camState.h)
    if not cam then
        cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        SetCamCoord(cam, pos.x, pos.y, pos.z)
        PointCamAtCoord(cam, look.x, look.y, look.z)
        SetCamFov(cam, camState.fov)
        SetCamActive(cam, true)
        RenderScriptCams(true, true, C.transitionMs or 400, true, true)
    else
        SetCamCoord(cam, pos.x, pos.y, pos.z)
        PointCamAtCoord(cam, look.x, look.y, look.z)
        SetCamFov(cam, camState.fov)
    end
end
local function camOff()
    if not cam then return end
    RenderScriptCams(false, true, Config.GunsmithCamera.transitionMs or 400, true, true)
    DestroyCam(cam, false) cam = nil
end
-- hold the selected gun up for the camera (only a carried gun can be shown)
local shownDict = nil
local function showGun(serial)
    local e = serial and carried[serial]
    local p = ped()
    if shownDict then ClearPedTasks(p) RemoveAnimDict(shownDict) shownDict = nil end
    if not e then return end
    SetCurrentPedWeapon(p, e.hash, true)
    local dict = inspectDict(e)
    if loadDict(dict) then
        TaskPlayAnim(p, dict, 'base_enter', 4.0, -4.0, -1, 0, 0.0, false, false, false)
        shownDict = dict
        SetTimeout(900, function() if shownDict == dict and session then TaskPlayAnim(p, dict, 'base_idle_pose', 4.0, -4.0, -1, 1, 0.0, false, false, false) end end)
    end
end
RegisterNUICallback('show', function(d, cb) if session then showGun(d.serial) end cb({}) end)
RegisterNUICallback('nudge', function(d, cb)
    if not session or not cam then return cb({}) end
    local C = Config.GunsmithCamera
    local p = ped()
    if d.turn then SetEntityHeading(p, (GetEntityHeading(p) + (tonumber(d.turn) or 0)) % 360) end
    if d.zoom then camState.fov = math.max(C.fovRange[1], math.min(C.fovRange[2], camState.fov - (tonumber(d.zoom) or 0) * 3.0)) end
    if d.height then camState.h = math.max(C.heightRange[1], math.min(C.heightRange[2], camState.h + (tonumber(d.height) or 0) * 0.05)) end
    camUpdate()
    cb({})
end)

local function close()
    if not session then return end
    session = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    showGun(nil)
    camOff()
end

local function open(shop)
    if session then return end
    local ok, data, bundle, brand = LXR.RPC.Server('lxr-weapons:gunsmith:open', shop.id)
    if not ok then return toast('error.' .. tostring(data), 'error') end
    session = { shop = shop }
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', data = data, locale = bundle, brand = brand or LXRCore.Brand, lang = Config.Lang })
    if Config.GunsmithCamera.enabled then
        camState = { fov = Config.GunsmithCamera.fov, h = 0.0 }
        camUpdate()
        if data.weapons and data.weapons[1] then showGun(data.weapons[1].serial) end
    end
end

local function rpc(name, ...)
    if not session then return { ok = false } end
    local ok, res, extra = LXR.RPC.Server(name, session.shop.id, ...)
    if not ok then
        toast('error.' .. tostring(res), 'error', { amount = extra })
        return { ok = false, why = res }
    end
    return { ok = true, data = res, amount = extra }
end

RegisterNUICallback('close', function(_, cb) close() cb({ ok = true }) end)
RegisterNUICallback('repair', function(d, cb) local r = rpc('lxr-weapons:gunsmith:repair', d.serial) if r.ok then toast('info.paid', 'success', { amount = r.amount }) end cb(r) end)
RegisterNUICallback('fit', function(d, cb) local r = rpc('lxr-weapons:gunsmith:fit', d.serial, d.key) if r.ok then toast('info.paid', 'success', { amount = r.amount }) end cb(r) end)
RegisterNUICallback('strip', function(d, cb) local r = rpc('lxr-weapons:gunsmith:strip', d.serial, d.key) if r.ok then toast('info.paid', 'success', { amount = r.amount }) end cb(r) end)
RegisterNUICallback('unload', function(d, cb) local r = rpc('lxr-weapons:gunsmith:unload', d.class) if r.ok then toast('info.unloaded', 'success', { n = r.amount }) end cb(r) end)
RegisterNUICallback('sound', function(d, cb) PlaySoundFrontend(d.name or 'NAV_UP', d.set or 'HUD_SHOP_SOUNDSET', true, 0) cb({}) end)

CreateThread(function()
    for _, s in ipairs(Config.Gunsmiths) do
        LXRCore.Functions.Door('lxr-weapons:' .. s.id, s.coords, { label = Lang:t('prompt.gunsmith', { name = s.label }), action = Lang:t('prompt.open'), distance = Config.Security.promptDistance, control = Config.Security.promptKey }, function() open(s) end)
        if s.blip then
            local blip = N(0x554D9D53F696D002, 1664425300, s.coords.x, s.coords.y, s.coords.z)
            if blip and blip ~= 0 then
                N(0x74F74D3207ED525C, blip, joaat('blip_shop_gunsmith'), true)
                N(0x9CB1A1623062F402, blip, s.label)
                if GetResourceState('lxr-mapcolor') == 'started' then pcall(function() N(0x662D364ABF16DE2F, blip, exports['lxr-mapcolor']:modifier('gunsmith')) end) end
                blips[#blips + 1] = blip
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🔌 LIFECYCLE
-- ═══════════════════════════════════════════════════════════════════════════════
local function hello()
    carried = {} inHand = nil lastAmmo = {}
    TriggerServerEvent('lxr-weapons:server:ready')
end
RegisterNetEvent('lxr:client:loaded', hello)
RegisterNetEvent('lxr:client:unloaded', function() carried = {} inHand = nil running = false close() end)
AddEventHandler('onResourceStart', function(res) if res == GetCurrentResourceName() and LocalPlayer.state.isLoggedIn then hello() end end)
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, b in ipairs(blips) do RemoveBlip(b) end
    close()
end)

exports('GetDrawn', function() return inHand and carried[inHand] and carried[inHand].name or nil end)
exports('IsArmed', function() return next(carried) ~= nil end)
exports('Carried', function() return carried end)
exports('OpenGunsmith', function(id) for _, s in ipairs(Config.Gunsmiths) do if s.id == id then open(s) end end end)
