fx_version 'cerulean'
game 'gta5'

author 'Bloggrs'
description 'Player persistence: spawn, skin save/load, customizable character'
version '1.0.0'

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'server.lua',
    'sql_setup.lua',
    'commands.lua',
}

client_scripts {
    'client.lua'
}
