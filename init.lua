-- Hammerspoon设置
hs.preferencesDarkMode = true
hotkey = require "hs.hotkey"
hyperkey = {"ctrl", "command", "shift"}
hyper = {"ctrl", "option"}
Hyper = {"ctrl", "option", "command"}
hotkey.bind(hyperkey, "r", hs.reload)
hotkey.bind(hyperkey, "p", hs.openPreferences)
hotkey.bind({"option"}, "z", hs.toggleConsole)
-- 组件加载管理
local module_list = {
	"module.Music",
	"module.window",
	"module.Spotlightlike",
	"module.IME",
	"module.Network",
	--"module.DesktopWidget",
		}
for _, v in ipairs(module_list) do
	require (v)
end
-- Baby
local owner = hs.host.localizedName()
if owner ~= "鳳凰院カミのMacBook Pro" then
	require "module.autoupdate"
end