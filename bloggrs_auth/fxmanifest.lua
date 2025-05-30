fx_version 'cerulean'
game 'gta5'

author 'Bloggrs'
description 'Bloggrs Authentication System for FiveM'
version '1.0.0'

dependencies {
    'mysql-async'
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'server/config.lua',
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/img/background.jpg',
    'html/img/bloggrs_logo.png',
}
