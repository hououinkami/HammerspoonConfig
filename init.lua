-- Hammerspoon设置及模块调用
hotkey = require "hs.hotkey"
win = require "hs.window"
spaces = require "hs.spaces"
ax = require "hs.axuielement"
app = require "hs.application"
as = require "hs.osascript"
c = require "hs.canvas"
img = require "hs.image"
timer = require "hs.timer"

-- 常用变量
local Config = {
    screenFrame = hs.screen.mainScreen():fullFrame(),
    desktopFrame = hs.screen.mainScreen():frame(),
    owner = hs.host.localizedName(),
    HOME = os.getenv("HOME"),
    darkMode = hs.preferencesDarkMode
}
_G.Config = Config

-- 定义快捷键修饰键
hyper_ccs = {'⌘⌃⇧'}
hyper_cs = {'⌘⇧'}
hyper_co = {'⌘⌥'}
hyper_oc = {'⌥⌃'}
hyper_coc = {'⌘⌥⌃'}
hyper_cos = {'⌘⌥⇧'}
hyper_cc = {'⌘⌃'}
hyper_cmd = {'⌘'}
hyper_opt = {'⌥'}
hyper_ctrl = {'⌃'}
hyper_shift = {'⇧'}

hyper_lcmd = {'lcmd'}
hyper_lopt = {'lopt'}
hyper_lctrl = {'lctrl'}
hyper_lshift = {'lshift'}
hyper_rcmd = {'rcmd'}
hyper_ropt = {'ropt'}
hyper_rctrl = {'rctrl'}
hyper_rshift = {'rshift'}

-- Hammerspoon快捷键
hotkey.bind(hyper_ccs, "r", hs.reload)
hotkey.bind(hyper_ccs, "q", function() hs.crash.crash() end)
hotkey.bind(hyper_ccs, "p", hs.openPreferences)
hotkey.bind(hyper_opt, "z", hs.toggleConsole)

-- 组件加载管理
local module_list = {
    { name = "Music",          exclude = { "mini" } },
    { name = "Window" },
    { name = "Space" },
    { name = "Spotlightlike" },
    { name = "IME" },
	-- { name = "Hotkey" },
    -- { name = "Network",     exclude = { "mini" } },
    -- { name = "AppKeyMap" },
    { name = "autoupdate",     exclude = { "Kami" } },
}

-- 模块按需加载函数
local function shouldLoad(module)
    if not module.exclude then return true end
    for _, keyword in ipairs(module.exclude) do
        if string.find(Config.owner, keyword, 1, true) then
			return false
		end
    end
    return true
end

for _, m in ipairs(module_list) do
    if shouldLoad(m) then
        require('module.' .. m.name)
    end
end

-- 是否加载测试模块的条件
local load_test_modules = false

-- 条件加载所有以test_开头的模块
if load_test_modules then
    local module_dir = hs.configdir .. "/module"
    for file in hs.fs.dir(module_dir) do
        -- 检查是否是以test_开头的Lua文件
        if string.match(file, "^test_.*%.lua$") then
            local module_name = string.gsub(file, "%.lua$", "")  -- 移除.lua后缀
			print(module_name)
            require('module.' .. module_name)
        end
    end
end

-- 当Music和歌词的配置文件文件更新时热更新
local function reloadConfig(files)
    for _,file in pairs(files) do
		local filenameExt = string.match(file, ".+/([^/]*%.%w+)$")
		local idx = filenameExt:match(".+()%.%w+$")
		local filename = idx and filenameExt:sub(1, idx-1) or filenameExt
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
ConfigWatcher = hs.pathwatcher.new(Config.HOME .. "/.hammerspoon/config", reloadConfig):start()