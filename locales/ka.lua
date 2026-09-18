--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-WEAPONS — Locale: Georgian (ქართული)
     Developer   : iBoss21 | Brand : LXRCore | https://www.lxrcore.com
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

Locale.Register('ka', {
    prompt = { gunsmith = '%{name}' },
    error = {
        not_yours = 'ეს იარაღი შენს ჩანთაში არ არის.', too_many = 'ასეთი უკვე საკმარისი გაქვს.', no_dual = 'ამ იარაღის დაწყვილება არ შეიძლება.',
        no_holster = 'ამისთვის თავისუფალი ბუდე არ არის.', pool_full = 'მეტ %{label}-ს ვერ წაიღებ.', nothing_in_hand = 'ხელში აიღე იარაღი, რომლის მოვლაც გინდა.',
        wrong_care = 'ეს ამ იარაღს არ დაეხმარება.', pristine = 'ისედაც იდეალურ მდგომარეობაშია.', jammed = '%{label} დაიჭედა — გაწმენდა სჭირდება.',
        rate = 'შენელდი.', invalid = 'მოთხოვნა არასწორია.', too_far = 'დახლს მიუახლოვდი.', no_money = 'ეს არ გაქვს. სულ: $%{amount}.',
        no_fit = 'ეს ნაწილი ამ იარაღს არ ერგება.', fitted = 'ეს ნაწილი უკვე დაყენებულია.', too_heavy = 'ჩანთა ამდენ ვაზნას ვერ დაიტევს.',
    },
    info = {
        loaded = 'ჩაიტენა %{n} × %{label}.', cared = '%{label} — %{q}%%.', wearing = '%{label} ცვდება (%{q}%%).', holstered = '%{label} დამალულია.',
        paid = 'გადახდილია $%{amount}.', unloaded = '%{n} ვაზნა დაბრუნდა ჩანთაში.',
    },
    ui = {
        gunsmith = 'მეიარაღე', caring = '%{label}-ის მოვლა', weapons = 'შენი იარაღი', none = 'ჩანთაში არაფერია', condition = 'მდგომარეობა', repair = 'შეკეთება',
        parts = 'ნაწილები', ammo = 'ჩატენილი ვაზნები', unload = 'ამოტენა', close = 'წასვლა', cash = 'ნაღდი', fitted = 'დაყენებული', fit = 'დაყენება', remove = 'მოხსნა',
        damage = 'ზიანი', range = 'მანძილი', rate = 'სროლის სიხშირე', accuracy = 'სიზუსტე', reload = 'გადატენა', serial = 'სერია', maker = 'მწარმოებელი', era = 'ნიმუში',
        clip = 'ვაზნები', drawn = 'თან გაქვს', stowed = 'ჩანთაშია', cosmetic = 'დეკორატიული', pristine = 'როგორც ახალი', jammed = 'დაჭედილი', hint_close = 'წასვლა',
        stats = 'მახასიათებლები', group_barrel = 'ლულა', group_sight = 'სამიზნე', group_scope = 'ოპტიკა', group_grip = 'ტარი', group_stock = 'კონდახი', group_rifling = 'ხრახნილი',
        group_finish = 'დაფარვა', group_engrave = 'გრავიურა', group_wrap = 'შემოხვევა', rounds = 'ვაზნა', pick = 'აირჩიე იარაღი მარცხნივ',
    },
})
