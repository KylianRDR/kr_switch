fx_version 'cerulean'
game 'gta5'

name 'Advanced Damage System'
description 'Système de dégâts avancé avec états de santé et interface médicale'
version '2.0.0'

ui_page 'nui/index.html'

files {
    'nui/index.html',
    'nui/style.css',
    'nui/script.js'
}

shared_scripts {
    'config.lua'
}

client_scripts {
    'client.lua',
    'target_client.lua'
}

server_scripts {
    'server.lua'
}

dependencies {
    'ox_target',
    'es_extended'
}