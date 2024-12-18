-- For support join my discord: https://discord.gg/Z9Mxu72zZ6

author "Andyyy#7666"
description "Clothing store for ND framework"
version "2.0.0"

fx_version "cerulean"
game "gta5"
lua54 "yes"

shared_scripts {
    "@ND_Core/init.lua",
    "@ox_lib/init.lua",
    "config.lua"
}
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    "source/server.lua"
} 
client_script "source/client.lua"

dependencies {
    "ND_Core",
    "fivem-appearance",
    "ox_lib"
}
