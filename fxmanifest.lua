fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'sobing4413 + refactor by Codex'
description 'Universal, modular, and secure ATM robbery script'

shared_scripts {
    'config.lua',
    'bridges/framework.lua',
    'bridges/inventory.lua',
    'bridges/dispatch.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

data_file 'DLC_ITYP_REQUEST' 'stream/loq_atm.ytyp'
