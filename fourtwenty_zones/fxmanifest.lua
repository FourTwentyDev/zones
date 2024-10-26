fx_version 'cerulean'
game 'gta5'

author 'Your Name'
description 'Advanced Zone Management System'
version '1.0.0'

shared_scripts {
    'shared/config.lua'
}

client_scripts {
    'client/main.lua',
    'client/editor.lua',
    'client/visualization.lua',
    'client/zoneviewer.lua'
}

server_scripts {
    'server/*.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

dependencies {
    '/server:5848',
    '/onesync'
}