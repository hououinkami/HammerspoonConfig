-- Hammerspoon设置
hs.preferencesDarkMode = true
hotkey = require "hs.hotkey"
hyperkey = {'⌘⌃⇧'}
hyper = {'⌃⌥'}
Hyper = {'⌘⌃⌥'}
keymap = {'⌃'}
hotkey.bind(hyperkey, "r", hs.reload)
hotkey.bind(hyperkey, "p", hs.openPreferences)
hotkey.bind({'⌥'}, "z", hs.toggleConsole)
-- 组件加载管理
local module_list = {
	"module.Network",
	"module.Music",
	"module.Window",
	"module.Space",
	"module.Spotlightlike",
	"module.IME",
	"module.AppKeyMap",	
	"module.Hotkey",	
	--"module.DesktopWidget",
	--"module.test",
}
for _, v in ipairs(module_list) do
	require (v)
end
-- 自动更新
local owner = hs.host.localizedName()
if not string.find(owner,"カミ") then
	require "module.autoupdate"
end