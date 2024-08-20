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
HOME = os.getenv("HOME")
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
hyper_shift = {'⇧'}
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
	"Music",
	"Window",
	"Space",
	"Spotlightlike",
	"IME",
	"Hotkey",
	-- "Network",
	-- "AppKeyMap",	
	-- "DesktopWidget",
	-- "test",
	"ring",
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

-- 当Music和歌词的配置文件文件更新时热更新
function reloadConfig(files)
    for _,file in pairs(files) do
		filenameExt = string.match(file, ".+/([^/]*%.%w+)$")
		local idx = filenameExt:match(".+()%.%w+$")
		if(idx) then
			filename = filenameExt:sub(1, idx-1)
		else
			filename = filenameExt
		end
		hotfix('config.' .. filename)
		if filename == "lyric" then
			lyrictext = nil
			Lyric.show(lyricTable)
		elseif filename == "music" then
			musicstate = nil
			musicBarUpdate()
		end
    end
end
ConfigWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/config", reloadConfig):start()