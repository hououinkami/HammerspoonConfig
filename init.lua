-- Hammerspoon设置及模块调用
hs.preferencesDarkMode = true
hotkey = require "hs.hotkey"
win = require "hs.window"
spaces = require "hs.spaces"
ax = require "hs.axuielement"
app = require "hs.application"
as = require "hs.osascript"
c = require "hs.canvas"
img = require "hs.image"
-- 常用变量
screenFrame = hs.screen.mainScreen():fullFrame()
desktopFrame = hs.screen.mainScreen():frame()
menubarHeight = desktopFrame.y
owner = hs.host.localizedName()
-- 定义快捷键修饰键
hyper_ccs = {'⌘⌃⇧'}
hyper_cs = {'⌘⇧'}
hyper_co = {'⌘⌥'}
hyper_oc = {'⌥⌃'}
hyper_coc = {'⌘⌥⌃'}
hyper_cos = {'⌘⌥⇧'}
hyper_cc = {'⌘⌃'}
hyper_cmd = {'⌘'}
hyper_ctrl = {'⌃'}
hyper_opt = {'⌥'}
-- Hammerspoon快捷键
hotkey.bind(hyper_ccs, "r", hs.reload)
hotkey.bind(hyper_ccs, "q", function() hs.crash.crash() end)
hotkey.bind(hyper_ccs, "p", hs.openPreferences)
hotkey.bind(hyper_opt, "z", hs.toggleConsole)
-- 判断系统显示模式
function appearanceIsDark()
	asSuccess, asObj, asDesc = hs.osascript.applescript("tell application \"System Events\" to tell appearance preferences to return dark mode")
	return asObj
end
if appearanceIsDark() then
	darkMode = true
else
	darkMode = false
end
-- 组件加载管理
local owner = hs.host.localizedName()
local module_list = {
	"Network",
	"Music",
	"Window",
	"Space",
	"Spotlightlike",
	"IME",
	"AppKeyMap",	
	"Hotkey",	
	--"DesktopWidget",
	--"test",
}
for _, v in ipairs(module_list) do
	if v == 'Network' or v == 'Music' then
		if not string.find(owner,"mini") then
			require ('module.' .. v)
		end
	else
		require ('module.' .. v)
	end
end
if not string.find(owner,"Kami") then
	require ('module.autoupdate')
end
