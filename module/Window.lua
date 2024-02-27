--------**--------
-- 变量设置
--------**--------
win.animationDuration = 0
resizeStep = 20
local winhistory = {}
local windowMeta = {}
-- 记录窗口初始位置
function windowStash(window)
	local winid = window:id()
	local winf = window:frame()
	if #winhistory > 50 then
		table.remove(winhistory)
	end
	local winstru = {winid, winf}
	-- table.insert(winhistory, winstru) 注释掉本栏后面几行取消注释该行则为记录窗口历史
	local exist = false
	for idx,val in ipairs(winhistory) do
		if val[1] == winid then
			exist = true
		end
	end
	if exist == false then
		table.insert(winhistory, winstru)
	end
end
-- 窗口定义
function windowMeta.new()
	local self = setmetatable(windowMeta, {
			__call = function (cls, ...)
				return cls.new(...)
			end,
		})
	if self ~= nil then
		self.window = win.focusedWindow()
		self.screen = self.window:screen()
		self.resolution = self.screen:fullFrame()
		self.windowFrame = self.window:frame()
		self.screenFrame = self.screen:frame()
	end
	return self
end

--------**--------
-- 窗口调节函数
--------**--------
-- 按比例缩放当前窗口
function pushCurrent(x, y, w, h)
	local this = windowMeta.new()
	windowStash(this.window)
	if type(x) == "number" then
		local frame = this.windowFrame
		frame.x = this.screenFrame.x + (this.screenFrame.w * x)
		frame.y = this.screenFrame.y + (this.screenFrame.h * y)
		frame.w = this.screenFrame.w * w
		frame.h = this.screenFrame.h * h
		this.window:setFrame(frame)
	elseif x == "fullscreen" then
		this.window:toggleFullScreen()
	elseif x == "center" then
		this.window:centerOnScreen()
	end
end
-- 平滑调节窗口大小
function resizeWindow(window, dir, step)
	local this = windowMeta.new()
	windowStash(this.window)
	local frame = this.windowFrame
    local max = this.screenFrame
	if dir == "right" then
		frame.w = frame.w + step
	elseif dir == "left" then
		frame.w = frame.w - step
	elseif dir == "up" then
		frame.h = frame.h - step
	elseif dir == "down" then
		frame.h = frame.h + step
	end
	if frame.x < max.x then
        frame.x = max.x
    end
    if frame.y < max.y then
        frame.y = max.y
    end
    if frame.w > max.w then
        frame.w = max.w
    end
    if frame.h > max.h then
        frame.h = max.h
    end
    this.window:move(frame)
end
-- 撤销最近一次动作
function Undo()
	local cwin = win.focusedWindow()
	local cwinid = cwin:id()
	for idx,val in ipairs(winhistory) do
        -- Has this window been stored previously?
		if val[1] == cwinid then
			cwin:setFrame(val[2])
		end
	end
end

--------**--------
-- 窗口动作函数
--------**--------
local Resize = {}
-- 半屏
Resize.halfleft = function ()
	pushCurrent(0, 0, 1/2, 1)
end
Resize.halfright = function ()
	pushCurrent(1/2, 0, 1/2, 1)
end
Resize.halfup = function ()
	pushCurrent(0, 0, 1, 1/2)
end
Resize.halfdown = function ()
	pushCurrent(0, 1/2, 1, 1/2)
end
Resize.maximize = function ()
	pushCurrent(0, 0, 1, 1)
end
Resize.fullscreen = function ()
	pushCurrent("fullscreen")
end
Resize.center = function ()
	pushCurrent("center")
end
Resize.reset = function ()
	local currentWindow = win.focusedWindow()
	local currentid = currentWindow:id()
	for idx,val in ipairs(winhistory) do
		if val[1] == currentid then
			currentWindow:setFrame(val[2])
		end
	end
end
-- 平移至贴近屏幕边缘
Resize.toleft = function ()
	local this = windowMeta.new()
	if this.windowFrame.x > 0 then
		windowStash(this.window)
		this.window:move({ 0, (this.screenFrame.h - this.windowFrame.h) / 2, this.windowFrame.w, this.windowFrame.h })
	else
		this.window:moveOneScreenWest()
	end
end
Resize.toright = function ()
	local this = windowMeta.new()
	if this.windowFrame.x + this.windowFrame.w < this.screenFrame.w then
		windowStash(this.window)
		this.window:move({ this.screenFrame.w - this.windowFrame.w, (this.screenFrame.h - this.windowFrame.h) / 2, this.windowFrame.w, this.windowFrame.h })
	else
		this.window:moveOneScreenEast()
	end
end
Resize.toup = function ()
	local this = windowMeta.new()
	if this.windowFrame.y > 0 then
		windowStash(this.window)
		this.window:move({ this.windowFrame.x, 0, this.windowFrame.w, this.windowFrame.h })
	else
		this.window:moveOneScreenNorth()
	end
end
Resize.todown = function ()
	local this = windowMeta.new()
	if this.windowFrame.y + this.windowFrame.h < this.screenFrame.h then
		windowStash(this.window)
		this.window:move({ this.windowFrame.x, this.screenFrame.h + 22.5 - this.windowFrame.h, this.windowFrame.w, this.windowFrame.h })
	else
		this.window:moveOneScreenSouth()
	end
end
Resize.right = function ()
	local this = windowMeta.new()
	windowStash(this.window)
	resizeWindow(this.window, "right", resizeStep)
end
Resize.left = function ()
	local this = windowMeta.new()
	windowStash(this.window)
	resizeWindow(this.window, "left", resizeStep)
end
Resize.up = function ()
	local this = windowMeta.new()
	windowStash(this.window)
	resizeWindow(this.window, "up", resizeStep)
end
Resize.down = function ()
	local this = windowMeta.new()
	windowStash(this.window)
	resizeWindow(this.window, "down", resizeStep)
end

--------**--------
-- 定义快捷键
--------**--------　
-- 快捷键绑定函数
function windowsManagement(hyperkey, keyFuncTable, holding)
	for key,fn in pairs(keyFuncTable) do
		if holding == true then
			hotkey.bind(hyperkey, key, fn, nil, fn)
		else
			hotkey.bind(hyperkey, key, fn)
		end
	end
end
hotkey.bind(hyper_oc, 'return', Resize.maximize)
hotkey.bind(hyper_coc, 'return', Resize.fullscreen)
windowsManagement(hyper_oc, {
	left = Resize.halfleft,
	right = Resize.halfright,
	up = Resize.halfup,
	down = Resize.halfdown,
	c = Resize.center,
	delete = Resize.reset,
}, false)
windowsManagement(hyper_co, {
	left = Resize.toleft,
	right = Resize.toright,
	up = Resize.toup,
	down = Resize.todown,
}, false)
windowsManagement(hyper_coc, {
	left = Resize.left,
	right = Resize.right,
	up = Resize.up,
	down = Resize.down,
	c = Resize.center,
	delete = Resize.reset,
}, true)
windowsManagement(hyper_cos, {
	left = Resize.left,
	right = Resize.right,
	up = Resize.up,
	down = Resize.down,
	c = Resize.center,
	delete = Resize.reset,
}, true)

--------**--------
-- App自动窗口布局
--------**--------　
-- 自定义App窗口布局
local layouts = {
	{
		name = {"Safari"},
	  	func = function(index, win)
			Resize.fullscreen()
	  	end
	},
	{
		name = {""},
		func = function(index, win)
			win:move({ 0, 140, win:frame().w, win:frame().h })
		end
	},
}
-- 应用窗口布局
function applyLayout(layouts, app)
	if (app) then
		local appName = app:title()
	  	for i, layout in ipairs(layouts) do
			if (type(layout.name) == "table") then
				for i, layAppName in ipairs(layout.name) do
					if (layAppName == appName) then
			  		-- hs.alert.show(appName)
			  			local wins = app:allWindows()
			  			local counter = 1
			  			for j, win in ipairs(wins) do
							if (win:isVisible() and layout.func) then
				  				layout.func(counter, win)
				  				counter = counter + 1
							end
			  			end
					end
		  		end
			elseif (type(layout.name) == "string") then
		  		if (layout.name == appName) then
					local wins = app:allWindows()
					local counter = 1
					for j, win in ipairs(wins) do
			  			if (win:isVisible() and layout.func) then
							layout.func(counter, win)
							counter = counter + 1
			  			end
					end
		  		end
			end
	  	end
	end
end
-- 设置触发函数
windowWatcher = {}
newWindowWatcher = {}
function windowWatcherListener(element, event, watcher, userData) 
	local appName = userData.name
  	local app = app.find(appName)
  	if (app) then
    	applyLayout(layouts, app)
  	end
end
function applicationWatcher(appName, eventType, appObject)
	-- 激活窗口
	if (eventType == app.watcher.activated) then
		if (appName == "QQ") then
			if appObject:focusedWindow() then
			  appObject:focusedWindow():move({ 20, 160, appObject:focusedWindow():frame().w, appObject:focusedWindow():frame().h })
			end
		elseif (appName == "WeChat") then
			if appObject:focusedWindow() then
				appObject:focusedWindow():move({ 810, 140, appObject:focusedWindow():frame().w, appObject:focusedWindow():frame().h })
			end
		elseif (appName == "Telegram") then
			if appObject:focusedWindow() then
				appObject:focusedWindow():move({ 20, 140, appObject:focusedWindow():frame().w, appObject:focusedWindow():frame().h })
			end
		elseif (appName == "") then
			if appObject:focusedWindow() and appObject:focusedWindow():title() then
				appObject:setFrontmost(true)
			end
			-- hs.osascript.applescript([[tell application "System Events" to tell process "Finder" to tell (menu bar 1's menu bar item 7) to {click (menu 1's menu item 16)}]])
			-- appObject:selectMenuItem({"ウィンドウ", "すべてを手前に移動"})
    	end
  	end
  	-- 启动App
  	if (eventType == app.watcher.launched) then
    	os.execute("sleep " .. tonumber(1))
    	applyLayout(layouts, appObject)
    	for i, aname in ipairs(newWindowWatcher) do
      		if (appName == aname) then      
        		if (not windowWatcher[aname]) then
          			-- hs.alert.show("Watching " .. appName)
          			windowWatcher[aname] = appObject:newWatcher(windowWatcherListener, { name = appName })
          			windowWatcher[aname]:start({hs.uielement.watcher.windowCreated})
        		end
      		end
    	end
	end
  	-- 退出App
  	if (eventType == app.watcher.terminated) then  
    	for i, aname in ipairs(newWindowWatcher) do
      		if (appName == aname) then      
        		if (windowWatcher[aname]) then
          			-- hs.alert.show("Stop watching " .. appName)
          			windowWatcher[aname]:stop()
          			windowWatcher[aname] = nil
        		end
      		end
    	end
  	end
end
-- 查看当前激活窗口的App路径及名称
hs.hotkey.bind(hyper_coc, ".", function()
	hs.pasteboard.setContents(win.focusedWindow():application():path())
	hs.alert.show(
		"App Path:        "
		..win.focusedWindow():application():path()
		.."\n"
		.."App Name:      "
		..win.focusedWindow():application():name()
		.."\n"
		.."IME Source ID: "
		..hs.keycodes.currentSourceID()
		.."\n"
		.."Window Title:  "
		..win.focusedWindow():title()
		.."\n"
		.."App Bundle ID: "
		..win.focusedWindow():application():bundleID()
	)
end)
appWatcherForresize = app.watcher.new(applicationWatcher)
appWatcherForresize:start()
