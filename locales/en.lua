--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-WEAPONS — Locale: English (canonical)
     Developer   : iBoss21 | Brand : LXRCore | https://www.lxrcore.com
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

Locale.Register('en', {
    prompt = { open = 'Open', gunsmith = '%{name}' },
    error = {
        not_yours = 'That gun is not in your satchel.', too_many = 'You are carrying enough of those.', no_dual = 'That gun cannot be paired.',
        no_holster = 'No free holster for that.', pool_full = 'You cannot carry more %{label}.', nothing_in_hand = 'Hold the weapon you want to tend.',
        wrong_care = 'That will not help this weapon.', pristine = 'It is in perfect condition already.', jammed = '%{label} jammed — it needs cleaning.',
        rate = 'Slow down.', invalid = 'That request is not valid.', too_far = 'Step up to the counter.', no_money = 'You cannot afford that. Total: $%{amount}.',
        no_fit = 'That part does not fit this weapon.', fitted = 'That part is already on it.', too_heavy = 'Your satchel cannot take that many rounds.',
    },
    info = {
        loaded = 'Loaded %{n} × %{label}.', cared = '%{label} is at %{q}%%.', wearing = '%{label} is wearing down (%{q}%%).', holstered = '%{label} put away.',
        paid = 'Paid $%{amount}.', unloaded = '%{n} rounds returned to your satchel.',
    },
    ui = {
        gunsmith = 'Gunsmith', caring = 'Tending %{label}', weapons = 'Your guns', none = 'Nothing in the satchel', condition = 'Condition', repair = 'Repair',
        parts = 'Parts', ammo = 'Loaded cartridges', unload = 'Unload', close = 'Leave', cash = 'Cash', fitted = 'Fitted', fit = 'Fit', remove = 'Remove',
        damage = 'Damage', range = 'Range', rate = 'Rate of fire', accuracy = 'Accuracy', reload = 'Reload', serial = 'Serial', maker = 'Maker', era = 'Pattern',
        clip = 'Rounds', drawn = 'On you', stowed = 'In the satchel', cosmetic = 'Cosmetic', pristine = 'Like new', jammed = 'Jammed', hint_close = 'leave',
        stats = 'Handling', group_barrel = 'Barrel', group_sight = 'Sights', group_scope = 'Scope', group_grip = 'Grip', group_stock = 'Stock', group_rifling = 'Rifling',
        group_finish = 'Finish', group_engrave = 'Engraving', group_wrap = 'Wrap', rounds = 'rounds', pick = 'Pick a gun on the left',
    },
})
