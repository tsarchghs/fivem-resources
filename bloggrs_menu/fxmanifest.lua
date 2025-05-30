-- fxmanifest.lua
fx_version 'cerulean'
game 'gta5'

author 'Bloggrs Team'
description 'Persistent HUD: Bloggrs logo, cash/bank, server time (for logged-in players)'
version '1.0'

-- Server scripts
server_scripts {
    '@mysql-async/lib/MySQL.lua',    -- MySQL-Async resource
    'server.lua'                     -- Server-side script
}

-- Client scripts
client_scripts {
    'client.lua'                    -- Client-side script
}

-- Define the NUI (web UI) page and files
ui_page 'html/index.html'           -- HTML file for the HUD UI

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/img/bloggrs_logo.png'    -- Placeholder logo image
}

-- Declare mysql-async as the only dependency
dependencies {
    'mysql-async'
}