--[[
    ██╗     ██╗  ██╗██████╗        ██╗    ██╗███████╗ █████╗ ██████╗  ██████╗ ███╗   ██╗███████╗
    ██║     ╚██╗██╔╝██╔══██╗       ██║    ██║██╔════╝██╔══██╗██╔══██╗██╔═══██╗████╗  ██║██╔════╝
    ██║      ╚███╔╝ ██████╔╝█████╗ ██║ █╗ ██║█████╗  ███████║██████╔╝██║   ██║██╔██╗ ██║███████╗
    ██║      ██╔██╗ ██╔══██╗╚════╝ ██║███╗██║██╔══╝  ██╔══██║██╔═══╝ ██║   ██║██║╚██╗██║╚════██║
    ███████╗██╔╝ ██╗██║  ██║       ╚███╔███╔╝███████╗██║  ██║██║     ╚██████╔╝██║ ╚████║███████║
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝        ╚══╝╚══╝ ╚══════╝╚═╝  ╚═╝╚═╝      ╚═════╝ ╚═╝  ╚═══╝╚══════╝

    🐺 LXR Weapons System — Server Script

    ═══════════════════════════════════════════════════════════════════════════════
    SERVER INFORMATION
    ═══════════════════════════════════════════════════════════════════════════════

    Server:    The Land of Wolves 🐺
    Developer: iBoss21 / The Lux Empire
    Website:   https://www.wolves.land
    Discord:   https://discord.gg/CrKcWdfd3A
    Store:     https://theluxempire.tebex.io

    ═══════════════════════════════════════════════════════════════════════════════

    © 2026 iBoss21 / The Lux Empire | wolves.land | All Rights Reserved
]]


local sharedWeapons = exports['lxr-core']:GetWeapons()
local sharedItems = exports['lxr-core']:GetItems()

---------------------------------------------------------------------
---- EVENTS
---------------------------------------------------------------------

RegisterNetEvent('lxr-weapons:server:UsedThrowable', function(name, slot)
    local src = source
    local Player = exports['lxr-core']:GetPlayer(src)
    if not Player then return end
    Player.Functions.RemoveItem(name, 1, slot)
end)

RegisterNetEvent("lxr-weapons:server:UpdateWeaponData", function(slot, amount, quality)
    local src = source
    local Player = exports['lxr-core']:GetPlayer(src)
    if not Player then return end
    local amount = tonumber(amount)
    if not slot or not Player.PlayerData.items[slot] then return end
    if quality then
        if not Player.PlayerData.items[slot].info.quality then
            Player.PlayerData.items[slot].info.quality = 100
        end
        Player.PlayerData.items[slot].info.quality -= quality
    end
    Player.PlayerData.items[slot].info.ammo = amount
    Player.Functions.SetInventory(Player.PlayerData.items[slot], slot)
end)

RegisterNetEvent("lxr-weapons:server:TakeBackWeapon", function(data)
    local src = source
    local Player = exports['lxr-core']:GetPlayer(src)
    local itemdata = Config.WeaponRepairPoints[data.index].IsRepairing.WeaponData
    itemdata.info.quality = 100
    Player.Functions.AddItem(itemdata.name, 1, false, itemdata.info)
    TriggerClientEvent('inventory:client:ItemBox', src, sharedItems[itemdata.name], "add")
    Config.WeaponRepairPoints[data.index].IsRepairing = nil
    GlobalState.WeaponRepairPoints = Config.WeaponRepairPoints
end)

---------------------------------------------------------------------
---- ITEMS
---------------------------------------------------------------------

for i=1, #Ammos do
    exports['lxr-core']:CreateUseableItem("ammo_"..Ammos[i], function(source, item)
        TriggerClientEvent('lxr-weapons:client:AddAmmo', source, 'AMMO_'..Ammos[i]:upper(), 6, item)
    end)
end

---------------------------------------------------------------------
---- CALLBACKS
---------------------------------------------------------------------

exports['lxr-core']:CreateCallback("lxr-weapons:server:RepairWeapon", function(source, cb, data)
    local src = source
    local Player = exports['lxr-core']:GetPlayer(src)
    local minute = 60 * 1000
    local Timeout = math.random(5 * minute, 10 * minute)
    local itemData = Player.PlayerData.items[data.slot]
    local WeaponData = sharedWeapons[joaat(itemData.name)]
    local WeaponClass = string.match(WeaponData.ammotype, "_(.+)"):lower()
    if itemData then
        if itemData.info.quality then
            if itemData.info.quality ~= 100 then
                if Player.Functions.RemoveMoney('cash', Config.WeaponRepairCosts[WeaponClass]) then
                    Config.WeaponRepairPoints[data.index].IsRepairing = {WeaponData = itemData}
                    Player.Functions.RemoveItem(itemData.name, 1, data.slot)
                    TriggerClientEvent('inventory:client:ItemBox', src, sharedItems[itemData.name], "remove")
                    TriggerClientEvent("lxr-weapons:client:CheckWeapon", src, itemData.name)
                    GlobalState.WeaponRepairPoints = Config.WeaponRepairPoints
                    SetTimeout(Timeout, function()
                        TriggerClientEvent('LXRCore:Notify', src, 9, Lang:t('success.weapon_ready'), 5000, 0, 'hud_textures', 'check', 'COLOR_WHITE')
                        Config.WeaponRepairPoints[data.index].IsRepairing.Ready = true
                        GlobalState.WeaponRepairPoints = Config.WeaponRepairPoints
                    end)
                    cb(true)
                else
                    cb(false)
                end
            else
                TriggerClientEvent("LXRCore:Notify", src, 9, Lang:t('error.no_damage_on_weapon'), 5000, 0, 'mp_lobby_textures', 'cross', 'COLOR_WHITE')
                cb(false)
            end
        else
            TriggerClientEvent("LXRCore:Notify", src, 9, Lang:t('error.no_damage_on_weapon'), 5000, 0, 'mp_lobby_textures', 'cross', 'COLOR_WHITE')
            cb(false)
        end
    else
        TriggerClientEvent('LXRCore:Notify', src, 9, Lang:t('error.no_weapon_in_hand'), 5000, 0, 'mp_lobby_textures', 'cross', 'COLOR_WHITE')
        TriggerClientEvent('weapons:client:SetCurrentWeapon', src, {}, false)
        cb(false)
    end
end)
