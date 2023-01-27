--------**--------
-- 变量设置
--------**--------
hs.window.animationDuration = 0
resizeStep = 10
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
		self.window = hs.window.focusedWindow()
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
    local window = hs.window.focusedWindow()
    pushWindow(window, x, y, w, h)
end
-- 按比例缩放指定窗口
function pushWindow(window, x, y, w, h)
    local frame = window:frame()
    local screen = window:screen()
    local max = screen:frame()
    frame.x = max.x + (max.w * x)
    frame.y = max.y + (max.h * y)
    frame.w = max.w * w
    frame.h = max.h * h
    window:setFrame(frame)
end
-- 平滑调节窗口大小
function resizeWindow(window, dir, step)
	local frame = window:frame()
    local screen = window:screen()
    local max = screen:frame()
	if dir == "right" then
		if frame.x + frame.w  < max.w then
			frame.w = frame.w + step
		else
			frame.x = frame.x + step
			frame.w = frame.w - step
		end
	elseif dir == "left" then
		if frame.x + frame.w  < max.w then
			frame.w = frame.w - step
		else
			frame.x = frame.x - step
			frame.w = frame.w + step
		end
	elseif dir == "up" then
		if frame.y + frame.h  < max.h then
			frame.h = frame.h - step
		else
			frame.y = frame.y - step
			frame.h = frame.h + step
		end
	elseif dir == "down" then
		if frame.y + frame.h  < max.h then
			frame.h = frame.h + step
		else
			frame.y = frame.y + step
			frame.h = frame.h - step
		end
	end
    window:setFrame(frame)
end
-- 撤销最近一次动作
function Undo()
	local cwin = hs.window.focusedWindow()
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
	local this = windowMeta.new()
	windowStash(this.window)
	pushWindow(this.window, 0, 0, 1/2, 1)
	--this.window:setFrame({ this.screenFrame.x, this.screenFrame.y, this.screenFrame.w / 2, this.screenFrame.h })
end
Resize.halfright = function ()
	local this = windowMeta.new()
	windowStash(this.window)
	pushWindow(this.window, 1/2, 0, 1/2, 1)
	--this.window:setFrame({ this.screenFrame.x+this.screenFrame.w / 2, this.screenFrame.y, this.screenFrame.w / 2, this.screenFrame.h })
end
Resize.halfup = function ()
	local this = windowMeta.new()
	windowStash(this.window)
	pushWindow(this.window, 0, 0, 1, 1/2)
	--this.window:setFrame({ this.screenFrame.x, this.screenFrame.y, this.screenFrame.w, this.screenFrame.h / 2 })
end
Resize.halfdown = function ()
	local this = windowMeta.new()
	windowStash(this.window)
	pushWindow(this.window, 0, 1/2, 1, 1/2)
	--this.window:setFrame({ this.screenFrame.x, this.screenFrame.y + this.screenFrame.h / 2, this.screenFrame.w, this.screenFrame.h / 2 })
end
Resize.maximize = function ()
	local this = windowMeta.new()
	windowStash(this.window)
	pushWindow(this.window, 0, 0, 1, 1)
	--this.window:setFrame({ x = this.resolution.x, y = this.resolution.y, w = this.resolution.w, h = this.resolution.h})
end
Resize.fullscreen = function ()
	local this = windowMeta.new()
	windowStash(this.window)
	this.window:toggleFullScreen()
end
Resize.center = function ()
	local this = windowMeta.new()
	windowStash(this.window)
	this.window:centerOnScreen()
end
Resize.reset = function ()
	local this = windowMeta.new()
	local thisid = this.window:id()
	for idx,val in ipairs(winhistory) do
		if val[1] == thisid then
			this.window:setFrame(val[2])
		end
	end
end
-- 平移至贴近屏幕边缘
Resize.toleft = function ()
	local this = windowMeta.new()
	windowStash(this.window)
	this.window:move({ 0, (this.screenFrame.h - this.windowFrame.h) / 2, this.windowFrame.w, this.windowFrame.h })
end
Resize.toright = function ()
	local this = windowMeta.new()
	windowStash(this.window)
	this.window:move({ this.screenFrame.w - this.windowFrame.w, (this.screenFrame.h - this.windowFrame.h) / 2, this.windowFrame.w, this.windowFrame.h })
end
Resize.toup = function ()
	local this = windowMeta.new()
	windowStash(this.window)
	this.window:move({ this.windowFrame.x, 0, this.windowFrame.w, this.windowFrame.h })
end
Resize.todown = function ()
	local this = windowMeta.new()
	windowStash(this.window)
	this.window:move({ this.windowFrame.x, this.screenFrame.h + 22.5 - this.windowFrame.h, this.windowFrame.w, this.windowFrame.h })
end
-- 
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
hotkey.bind(hyper, 'return', Resize.maximize)
hotkey.bind(Hyper, 'return', Resize.fullscreen)
windowsManagement(hyper, {
	left = Resize.halfleft,
	right = Resize.halfright,
	up = Resize.halfup,
	down = Resize.halfdown,
	c = Resize.center,
	delete = Resize.reset,
}, false)
windowsManagement({"option", "command"}, {
	left = Resize.toleft,
	right = Resize.toright,
	up = Resize.toup,
	down = Resize.todown,
}, false)
windowsManagement(Hyper, {
	left = function () 
		local this = windowMeta.new()
		if this.windowFrame.x > 0 then
			if this.windowFrame.x + this.windowFrame.w < this.screenFrame.w then
				Resize.toleft()
			else
				Resize.left()
			end
		else
			Resize.left()
		end
	end,
	right = function () 
		local this = windowMeta.new()
		if this.windowFrame.x + this.windowFrame.w < this.screenFrame.w then
			if this.windowFrame.x > 0 then
				Resize.toright()
			else
				Resize.right()
			end
		else
			Resize.right()
		end
	end,
	up = function () 
		local this = windowMeta.new()
		if this.windowFrame.y > 25 then
			if this.windowFrame.y + this.windowFrame.h < this.screenFrame.h then
				Resize.toup()
			else
				Resize.up()
			end
		else
			Resize.up()
		end
	end,
	down = function () 
		local this = windowMeta.new()
		if this.windowFrame.y + this.windowFrame.h < this.screenFrame.h then
			if this.windowFrame.y > 25 then
				Resize.todown()
			else
				Resize.down()
			end
		else
			Resize.down()
		end
	end,
	c = Resize.center,
	delete = Resize.reset,
}, true)
windowsManagement({"option", "command", "shift"}, {
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
  	local app = hs.application.find(appName)
  	if (app) then
    	applyLayout(layouts, app)
  	end
end
function applicationWatcher(appName, eventType, appObject)
	-- 激活窗口
	if (eventType == hs.application.watcher.activated) then
		if (appName == "QQ") then
			if appObject:focusedWindow() then
			  appObject:focusedWindow():move({ 20, 160, appObject:focusedWindow():frame().w, appObject:focusedWindow():frame().h })
			end
		elseif (appName == "WeChat") then
			if appObject:focusedWindow() then
				appObject:focusedWindow():move({ 810, 140, appObject:focusedWindow():frame().w, appObject:focusedWindow():frame().h })
			end
		elseif (appName == "") then
			if appObject:focusedWindow() and appObject:focusedWindow():title() then
				hs.osascript.applescript([[tell application "Music" to activate]])
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
  	if (eventType == hs.application.watcher.launched) then
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
  	if (eventType == hs.application.watcher.terminated) then  
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
hs.hotkey.bind(Hyper, ".", function()
	hs.pasteboard.setContents(hs.window.focusedWindow():application():path())
	hs.alert.show(
		"App Path:        "
		..hs.window.focusedWindow():application():path()
		.."\n"
		.."App Name:      "
		..hs.window.focusedWindow():application():name()
		.."\n"
		.."IME Source ID: "
		..hs.keycodes.currentSourceID()
		.."\n"
		.."Window Title:  "
		..hs.window.focusedWindow():title()
		.."\n"
		.."App Bundle ID: "
		..hs.window.focusedWindow():application():bundleID()
	)
end)
appWatcherForresize = hs.application.watcher.new(applicationWatcher)
appWatcherForresize:start()