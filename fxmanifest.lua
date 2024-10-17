fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

description 'LXR-Weapons'
version '1.0.2'

shared_scripts {
	'@lxr-core/shared/locale.lua',
	'locales/en.lua',
	'config.lua',
}

server_script 'server/main.lua'
client_script 'client/main.lua'

lua54 'yes'
