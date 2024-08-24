---@param phrases string[]
---@param flags? { headshot?: boolean, noscope?: boolean, dominated?: number, attackerblind?: boolean, thrusmoke?: boolean, revenge?: number, assister?: number, weapon?: string }
---@return table
local function new_phrase(phrases, flags)
    return {
        list = phrases,
        flags = flags,
    };
end;

return {
    new_phrase({
        'Арбузы заказывали?', 'Как нет?', 'Ну держи тогда хуем по лбу'
    })

};
