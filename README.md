# lxr-weapons ![Version](https://img.shields.io/badge/version-1.0.0-blue) ![Status](https://img.shields.io/badge/status-active-brightgreen) ![License](https://img.shields.io/github/license/LXRCore/lxr-weapons)

**lxr-weapons** is a weapon management system designed for the **LXRCore** framework in RedM. It includes features such as weapon repair points, custom repair costs, ammo limits, durability multipliers, and more, all configurable in a highly modular setup.

## Features

- Define weapon repair points with coordinates.
- Custom repair costs for different weapon categories (pistols, rifles, shotguns, etc.).
- Set maximum ammo limits for various weapon groups.
- Weapon durability system with customizable multipliers for each weapon.
- Easily extendable configuration for adding more weapons or modifying existing settings.

## Installation

1. Clone or download the repository and place it in your `lxr` directory.
2. Add the following to your `server.cfg`:

```bash
ensure lxr-core
ensure lxr-weapons
```

---

## Configuration

All the configuration options are located in `config.lua`. Below is a fully modular horizontal version of the configuration system:

### Weapon Repair Points

These points define the locations where players can repair their weapons.

```lua
Config.WeaponRepairPoints = {
    [1] = {coords = vector3(1417.818, 268.0298, 89.61942)}, [2] = {coords = vector3(-276.40, 803.20, 119.40)}
}
```

You can add or remove points by defining additional entries like `[2]` or modifying the vector coordinates.

### Weapon Repair Costs

Define the repair costs for different weapon categories, such as pistols or rifles. You can easily extend this list by adding more weapon types.

```lua
Config.WeaponRepairCosts = {
    ["pistol"] = 100, ["revolver"] = 200, ["repeater"] = 300, ["rifle"] = 300, ["shotgun"] = 400
}
```

### Maximum Ammo

Set the maximum ammo limits for each weapon group. For example, pistols have a limit of 6 rounds, and rifles have 12. You can easily extend this configuration by adding new weapon groups.

```lua
Config.MaxAmmo = {
    [`GROUP_PISTOL`] = 6, [`GROUP_RIFLE`] = 12, [`GROUP_REVOLVER`] = 6, [`GROUP_SHOTGUN`] = 6, [`GROUP_BOW`] = 6
}
```

### Weapon Durability Multipliers

Each weapon type can have a custom durability multiplier that controls how quickly it degrades. The lower the multiplier, the faster the weapon loses durability. This system is entirely flexible, and you can add or remove weapons easily.

```lua
Config.DurabilityMultiplier = {
    -- Handguns
    [`weapon_revolver_cattleman`] = 0.15, [`weapon_revolver_schofield`] = 0.15, [`weapon_revolver_navy`] = 0.15, 
    [`weapon_pistol_volcanic`] = 0.15, [`weapon_pistol_semiauto`] = 0.15,

    -- Rifles
    [`weapon_rifle_varmint`] = 0.15, [`weapon_rifle_springfield`] = 0.15, [`weapon_rifle_boltaction`] = 0.15,

    -- Shotguns
    [`weapon_shotgun_doublebarrel`] = 0.15, [`weapon_shotgun_semiauto`] = 0.15,

    -- Bows
    [`weapon_bow`] = 0.15, [`weapon_bow_improved`] = 0.15
}
```

### Adding More Weapons or Configurations

You can extend any section by simply adding more entries following the pattern provided. For example, if you want to add a new weapon type to the durability list, simply insert it like this:

```lua
[`weapon_new_weapon`] = 0.10
```

---

## License

This project is licensed under the MIT License.

## Credits

- **LXRCore** framework
- Inspired by **qbr-weapons** for the **QBCore** framework.

---
