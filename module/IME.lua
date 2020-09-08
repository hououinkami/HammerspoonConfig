k = require("hs.keycodes")
-- 判断英文输入法的种类
local roma = false
for key, value in pairs(k.methods()) do
	if value == "Romaji" then
		roma = true
	end
end
if roma == true then
	eng = "com.apple.inputmethod.Kotoeri.Roman"
	inputs = {"拼音 - 簡体字", "英字", "ひらがな"}
else
	eng = "com.apple.keylayout.ABC"
	inputs = {"简体拼音", "ABC", "平假名"}
end
local script = [[tell application "System Events" to tell process "TextInputMenuAgent" to tell (1st menu bar item of menu bar 2) to {click (menu item "tomethod" of menu 1), click}]]
-- 切换为拼音
local function Chinese()
	--hs.osascript.applescript(script:gsub("tomethod",inputs[1]))
	--k.currentSourceID("com.apple.inputmethod.SCIM.ITABC")
	k.setMethod("Pinyin - Simplified")
end
-- 切换为日文
local function Japanese()
	--hs.osascript.applescript(script:gsub("tomethod",inputs[3]))
	--k.currentSourceID("com.apple.inputmethod.Kotoeri.Japanese")
	k.setMethod("Hiragana")
end
-- 切换为英文
local function English()
	--hs.osascript.applescript(script:gsub("tomethod",inputs[2]))
	--k.currentSourceID(eng)
	k.setMethod("Romaji")
end
-- 切换输入法快捷键
hs.hotkey.bind(hyper, '/', Chinese)
hs.hotkey.bind(hyper, ',', English)
hs.hotkey.bind(hyper, '.', Japanese)
-- 设置App对应的输入法
local App2Ime = {
	{'/System/Library/CoreServices/Finder.app', 'Chinese'},
	{'/System/Library/CoreServices/Spotlight.app', 'Chinese'},
	{'/Applications/Hammerspoon.app', 'Chinese'},
	{'/Applications/System Preferences.app', 'Chinese'},
	{'/Applications/Utilities/Terminal.app', 'English'},
	{'/Applications/Visual Studio Code.app', 'English'},
	{'/System/Applications/Music.app', 'Japanese'},
	{'/Applications/Safari.app', 'Chinese'},
	{'/Applications/WeChat.app', 'Chinese'},
	{'/Applications/QQ.app', 'Chinese'},
	{'/Applications/企业微信.app', 'Chinese'},
	{'/Applications/Google Chrome.app', 'Chinese'},
	{'/Applications/Preview.app', 'Chinese'},
	{'/Applications/Microsoft Word.app', 'Chinese'},
	{'/Applications/Microsoft Excel.app', 'Chinese'},
	{'/Applications/Microsoft PowerPoint.app', 'Chinese'},
	{'/Applications/Pages.app', 'Chinese'},
	{'/Applications/Numbers.app', 'Chinese'},
	{'/Applications/Keynote.app', 'Chinese'},
	{'/Applications/XLD.app', 'Japanese'},
		}
-- 记录App输入法状态
function imeStash()
	local imehistory = {}
	if hs.window.frontmostWindow() ~= nil then
		if hs.window.frontmostWindow():application() ~= nil then
			currentapp = hs.window.frontmostWindow():application():path()
		end
	end
	local currentime = k.currentSourceID()
	if #imehistory > 50 then
		table.remove(App2Ime)
	end
	local imetable = {currentapp, currentime}
	local exist = false
	for idx,val in ipairs(App2Ime) do
		if val[1] == currentapp then
			exist = true
		end
	end
	if exist == false then
		table.insert(App2Ime, imetable)
	end
	return App2Ime
end
-- 自动切换输入法
function updateFocusAppInputMethod()
	if hs.window.frontmostWindow() ~= nil then
		if hs.window.frontmostWindow():application() ~= nil then
			focusAppPath = hs.window.frontmostWindow():application():path()
		end
	end
	for index, app in pairs(imeStash()) do
		local appPath = app[1]
		local expectedIme = app[2]
		if focusAppPath == appPath then
			ime = expectedIme
			break
		end
	end
	if ime == 'English' then
		English()
		--k.currentSourceID(eng)
	elseif ime == 'Chinese' then
		Chinese()
		--k.currentSourceID("com.apple.inputmethod.SCIM.ITABC")
	elseif ime == 'Japanese' then
		Japanese()
		--k.currentSourceID("com.apple.inputmethod.Kotoeri.Japanese")
	end
end
-- 监视App启动或终止并切换输入法成对应方式
function applicationWatcher(appName, eventType, appObject)
	if (eventType == hs.application.watcher.activated) then
		updateFocusAppInputMethod()
	end
end
appWatcher = hs.application.watcher.new(applicationWatcher)
appWatcher:start()
-- 查看当前激活窗口的App路径及名称
hs.hotkey.bind({'ctrl', 'option', 'command'}, ".", function()
		hs.pasteboard.setContents(hs.window.focusedWindow():application():path())
		hs.alert.show("App Path:        "
			..hs.window.focusedWindow():application():path()
			.."\n"
			.."App Name:      "
			..hs.window.focusedWindow():application():name()
			.."\n"
			.."IME Source ID:  "
			..hs.keycodes.currentSourceID())
	end)
