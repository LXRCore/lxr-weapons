# Changelog

## 3.0.0 — 2026-09-17

Rebuilt on the LXRCore v3 native API. Nothing of the earlier multi-framework build remains.

* Serialised guns: draw / holster by using the item; holsters by category with dual sidearms
* Per-calibre ammunition pools in character metadata, mirrored to the ped, clamped from the server
* Wear per shot from the core record; warnings, jam at zero; field care with kits, oil, whetstones
* Gunsmith counter on the LXR UI Kit: repair on the ledger value, parts by group, engravings, unloading
* Events `lxr:weapons:drawn` / `lxr:weapons:holstered`, state bag `weapon`, `Disarm` for the law
* Locales EN / KA, offline tests, LXR Night / LXR Morning
