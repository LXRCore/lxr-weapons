# Changelog

## 3.0.0 — 2026-09-19
* Loading cartridges is a thing you see: a progress with the game's cartridge-handling animation (`mech_inventory@crafting@fallbacks@modify_bullets`) and the calibre's ammunition box or the arrow bundle in hand; the rounds move when it finishes (`lxr-weapons:client:load` → `lxr-weapons:server:loaded`, re-validated on the server). `Config.Ammo.loadMs / loadAnim / loadProps`.
* Fix: the ped's rounds follow the pools by difference with `AddAmmoToPedByType` / `RemoveAmmoFromPedByType` — the plain set was ignored by the game for calibres the ped held no gun for (arrows loaded before the bow was drawn showed nothing).
* Gunsmiths are lxr-interact cards instead of native prompts.
* LXRCore v3 release line: every resource ships as 3.0.0 from here (the entries below are the road to it).

## 3.0.0 — 2026-09-17

Rebuilt on the LXRCore v3 native API. Nothing of the earlier multi-framework build remains.

* Serialised guns: draw / holster by using the item; holsters by category with dual sidearms
* Per-calibre ammunition pools in character metadata, mirrored to the ped, clamped from the server
* Wear per shot from the core record; warnings, jam at zero; field care with kits, oil, whetstones
* Gunsmith counter on the LXR UI Kit: repair on the ledger value, parts by group, engravings, unloading
* Events `lxr:weapons:drawn` / `lxr:weapons:holstered`, state bag `weapon`, `Disarm` for the law
* Locales EN / KA, offline tests, LXR Night / LXR Morning
