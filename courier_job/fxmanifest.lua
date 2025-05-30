fx_version 'cerulean'
game 'gta5'

author 'Bloggrs'
description 'Weed Courier Job System'
version '1.0.0'

ui_page 'html/index.html'

client_scripts {
    'config.lua',
    'client/main.lua'
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'config.lua',
    'server/main.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/img/logo.png'
}

dependencies {
    'bloggrs_auth', -- Dependency on your authentication system
    'mysql-async'  -- MySQL dependency
}
