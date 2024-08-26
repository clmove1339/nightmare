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
        '1'
    }),
    new_phrase({
        'ez'
    }),
    new_phrase({
        'арбузы заказывали?', 'как нет?', 'ну держи тогда хуем по лбу'
    }),
    new_phrase({
        'вот это я тебя тапнул', 'ты не реви только'
    }, { headshot = true }),
    new_phrase({
        'брат ты куда под руку лезешь', 'не видишь банан летит?'
    }, { assister = 1 }),
    new_phrase({
        'бро нужно тренироваться', 'а то ты совсем слабый что-то'
    }, { weapon = 'taser' }),
    new_phrase({
        'зарезал свинку', 'пойдешь на сало'
    }, { weapon = 'knife' }),
    new_phrase({
        'КТО ЗДЕСЬ???', 'сорри не видел тебя даже'
    }, { attackerblind = true }),
    new_phrase({
        'парни кто надымил?', 'не видно же ничего'
    }, { thrusmoke = true }),
    new_phrase({
        'кому вообще нужен прицел?', 'особенно когда ты играешь с nightmare.lua'
    }, { noscope = true }),
    new_phrase({
        'by', 'nightmare'
    }),
    new_phrase({
        'ахХАЫФХ', 'а чит то сегодня пенит'
    }, { headshot = true }),
    new_phrase({
        'по головешке твоей', 'лови'
    }, { headshot = true, noscope = true }),
    new_phrase({
        'ты тут или афк?', 'скорее всего даже афкшник справился бы лучше'
    }),
    new_phrase({
        'сколько стоит лоботомия?', 'потому что кажется ты ее уже проходил'
    }),
    new_phrase({
        'куда пропал?', 'о, ты все еще здесь', 'так тихо что я уже скучаю'
    }),
    new_phrase({
        'что ты делаешь когда не умираешь?', 'а стоп', 'ты же всегда умираешь'
    }),
    new_phrase({
        'проверь свою мышь', 'возможно она сломалась', 'хотя нет', 'это просто ты'
    }),
    new_phrase({
        'у тебя есть страховка?', 'с таким хэдшотом пора думать о ней'
    }, { headshot = true }),
    new_phrase({
        'еще один килл без прицела', 'может тебе свой прицел продать?'
    }, { noscope = true }),
    new_phrase({
        'брат', 'мне дали нож чтобы резать хлеб', 'а не твои шансы на победу'
    }, { weapon = 'knife' }),
    new_phrase({
        'поспи'
    }, { headshot = true, revenge = 1 }),
    new_phrase({
        'вкусно?', 'это тебе за прошлый раз',
    }, { revenge = 1 }),
    new_phrase({
        'ты бы лучше на тренировку пошел', 'слабый какой-то'
    }, { dominated = 1 }),
    new_phrase({
        'каково это когда тебя доминируют?', 'не переживай', 'бывает'
    }, { dominated = 1 }),
    new_phrase({
        'извини, ты тут как-то лишний', 'я сам могу убрать мусор'
    }, { assister = 1 }),
    new_phrase({
        'ты бы хоть выстрелил', 'что?', 'не увидел просто',
    }, { attackerblind = true }),
    new_phrase({
        'прям в глаз', 'ну почти'
    }, { headshot = true }),
    new_phrase({
        'by the night', 'be the night', 'buy the nightmare.lua'
    }, { noscope = true, headshot = true }),
    new_phrase({
        'чувствуешь nightmare?', 'это не случайность, это возможность'
    }, { weapon = 'taser' }),
    new_phrase({
        'nightmare.lua делает это снова', 'даже в дыму ты не спрячешься'
    }, { thrusmoke = true }),
    new_phrase({
        'играть с nightmare.lua — это как включить легкий режим', 'разве нет?'
    }),
    new_phrase({
        'nightmare.lua: кошмары становятся реальностью', 'особенно для тебя'
    }, { headshot = true }),
    new_phrase({
        'мой скрипт сильнее твоих навыков', 'согласен?'
    }),
    new_phrase({
        'nightmare.lua: и снова хэдшот', 'бросай прицел', 'он тебе не поможет'
    }, { noscope = true, headshot = true }),
    new_phrase({
        'уже боишься?', 'это всего лишь nightmare.lua', 'настала твоя очередь страдать'
    }, { dominated = 1 }),
    new_phrase({
        'кошмары?', 'нет, это просто скрипт', 'nightmare.lua всегда готова'
    }),
    new_phrase({
        'лучше чем твой последний скрипт', 'nightmare.lua не оставит шансов'
    }, { headshot = true }),
    new_phrase({
        'выключил прицел?', 'не беда', 'nightmare.lua и так справится'
    }, { noscope = true }),
    new_phrase({
        'пуки', 'каки', 'какашечки'
    }),
    new_phrase({
        'killed by: ', 'by banan', 'by sqwat', 'by clmove', 'by seizex'
    }),
    new_phrase({
        '1', 'оттарабанен by metamod.cc', 'ой то есть by nightmare.lua'
    }, { headshot = true }),
    new_phrase({
        'ДО СЛОБОДЫ ДОЕДУ???', 'Автобус идет до слободы',
    })
};
