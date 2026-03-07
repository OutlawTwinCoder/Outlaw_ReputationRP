fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Outlaw Reputation Team'
description 'Hub modulaire de réputation ESX'
version '1.0.0'

ui_page 'ui/html/index.html'

shared_scripts {
    '@es_extended/imports.lua',
    'config/config_core.lua',
    'config/config_rep_types.lua',
    'config/config_permissions.lua',
    'config/config_integrations.lua',
    'config/config_custom_scripts.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'core/database.lua',
    'core/rep_manager.lua',
    'modules/business_rep.lua',
    'modules/crime_rep.lua',
    'modules/police_records.lua',
    'connectors/billing_esx.lua',
    'connectors/billing_okok.lua',
    'connectors/drugs.lua'
}

client_scripts {
    'client.lua'
}

files {
    'ui/html/index.html',
    'ui/css/style.css',
    'ui/js/app.js'
}
