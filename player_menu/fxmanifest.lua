fx_version 'cerulean'
game 'gta5'

author 'Bloggrs'
description 'Bloggrs Player Menu & Inventory System'
version '1.0.0'

client_scripts {
    'client/main.lua',
    'client/inventory.lua',
    'client/keybinds.lua'
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'server/config.lua',
    'server/main.lua',
    'server/inventory.lua'
}

shared_scripts {
    'shared/items.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/img/bloggrs_logo.png',
    'html/img/background.jpg',
    'html/img/items/*.png'
}

dependencies {
    'bloggrs_auth'
}
