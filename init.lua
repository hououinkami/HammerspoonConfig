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
-- 定义快捷键修饰键
hyper_ccs = {'⌘⌃⇧'}
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
if not string.find(owner,"Kami") then
	require "module.autoupdate"
end