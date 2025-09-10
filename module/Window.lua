--------**--------
-- 变量设置
--------**--------
win.animationDuration = 0
resizeStep = 20
local winhistory = {}
local windowMeta = {}
local winhistoryMap = {}
-- 记录窗口初始位置
function windowStash(window)
    local winid = window:id()
    local winf = window:frame()
    if #winhistory > 50 then
        local removed = table.remove(winhistory, 1)
        winhistoryMap[removed[1]] = nil
    end
	-- local winstru = {winid, winf}
    -- table.insert(winhistory, winstru) 注释掉本栏后面几行取消注释该行和前一行，则为记录窗口历史
    if not winhistoryMap[winid] then
        local winstru = {winid, winf}
        table.insert(winhistory, winstru)
        winhistoryMap[winid] = #winhistory
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
		self.id = self.window:id()
		self.screen = self.window:screen()
		self.resolution = self.screen:fullFrame()
		self.windowFrame = self.window:frame()
		self.screenFrame2 = self.screen:frame()
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
		changeFocusedWindowDimensions(function(window)
			window:move({
				this.screenFrame2.x + (this.screenFrame2.w * x), 
				this.screenFrame2.y + (this.screenFrame2.h * y), 
				this.screenFrame2.w * w, 
				this.screenFrame2.h * h
			})
		end)
	elseif x == "center" then
		-- this.window:centerOnScreen()
		this.window:move({
			(this.screenFrame2.w - this.windowFrame.w) / 2, 
			(this.screenFrame2.h - this.windowFrame.h) / 2, 
			this.windowFrame.w, 
			this.windowFrame.h
		})
	elseif x == "fullscreen" then
		this.window:toggleFullScreen()
	elseif x == "reset" then
		for idx,val in ipairs(winhistory) do
			if val[1] == this.id then
				changeFocusedWindowDimensions(function(window)
					window:setFrame(val[2])
				end)
			end
		end
	-- 平移至贴近屏幕边缘
	elseif x == "toleft" then
		if this.windowFrame.x > 0 then
			this.window:move({
				0,
				(this.screenFrame2.h - this.windowFrame.h) / 2,
				this.windowFrame.w,
				this.windowFrame.h
			})
		else
			this.window:moveOneScreenWest()
		end
	elseif x == "toright" then
		if this.windowFrame.x + this.windowFrame.w < this.screenFrame2.w then
			this.window:move({
				this.screenFrame2.w - this.windowFrame.w,
				(this.screenFrame2.h - this.windowFrame.h) / 2,
				this.windowFrame.w,
				this.windowFrame.h
			})
		else
			this.window:moveOneScreenEast()
		end
	elseif x == "toup" then
		if this.windowFrame.y > 0 then
			this.window:move({
				this.windowFrame.x,
				0,
				this.windowFrame.w,
				this.windowFrame.h
			})
		else
			this.window:moveOneScreenNorth()
		end
	elseif x == "todown" then
		if this.windowFrame.y + this.windowFrame.h < this.screenFrame2.h then
			this.window:move({
				this.windowFrame.x,
				this.screenFrame2.h + 22.5 - this.windowFrame.h,
				this.windowFrame.w,
				this.windowFrame.h
			})
		else
			this.window:moveOneScreenSouth()
		end
	-- 平滑调节窗口大小
	elseif x == "reLeft" then
		resizeWindow(this.window, "left", resizeStep)
	elseif x == "reRight" then
		resizeWindow(this.window, "right", resizeStep)
	elseif x == "reUp" then
		resizeWindow(this.window, "up", resizeStep)
	elseif x == "reDown" then
		resizeWindow(this.window, "down", resizeStep)
	end
end
-- 平滑调节窗口大小
function resizeWindow(window, dir, step)
	local frame = window:frame()
    local max = window:screen():frame()
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
    window:move(frame)
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

-- 处理有问题的App窗口
function changeFocusedWindowDimensions(action)
	local window = hs.window.focusedWindow()

	if not window then return end

	local app = window:application()
	local ax_app = hs.axuielement.applicationElement(app)

	-- original settings
	local was_enhanced = ax_app.AXEnhancedUserInterface
	local original_animation_duration = hs.window.animationDuration

	if was_enhanced then
		-- set & run action
		ax_app.AXEnhancedUserInterface = false
		hs.window.animationDuration = 0
		action(window)

		-- restore original settings
		hs.window.animationDuration = original_animation_duration
		ax_app.AXEnhancedUserInterface = was_enhanced
	else
		action(window)
	end
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
-- 半屏、居中、恢复
windowsManagement(hyper_oc, {
	left = function() pushCurrent(0, 0, 1/2, 1) end,
	right = function() pushCurrent(1/2, 0, 1/2, 1) end,
	up = function() pushCurrent(0, 0, 1, 1/2) end,
	down = function() pushCurrent(0, 1/2, 1, 1/2) end, 
	c = function() pushCurrent("center") end,
	["return"] = function() pushCurrent(0, 0, 1, 1) end,
	["delete"] = function() pushCurrent("reset") end,
}, true)
-- 移动
windowsManagement(hyper_co, {
	left = function() pushCurrent("toleft") end,
	right = function() pushCurrent("toright") end,
	up = function() pushCurrent("toup") end,
	down = function() pushCurrent("todown") end,
	c = function() pushCurrent("center") end,
	["return"] = function() pushCurrent(0, 0, 1, 1) end,
}, false)
-- 平滑调节大小
-- windowsManagement(hyper_coc, {
-- 	left = function() pushCurrent("reLeft") end,
-- 	right = function() pushCurrent("reRight") end,
-- 	up = function() pushCurrent("reUp") end,
-- 	down = function() pushCurrent("reDown") end,
-- }, true)

--------**--------
-- App窗口布局
--------**--------
-- 自定义App窗口布局
local layouts = {
	{
		name = {"Safari"},
	  	func = function(index, win)
			pushCurrent("fullscreen")
	  	end
	},
	{
		name = {"WeChat"},
		func = function(index, win)
			win:move({ desktopFrame.w / 2, (desktopFrame.h - win:frame().h) / 2, desktopFrame.w / 2, win:frame().h })
		end
	},
	{
		name = {"Telegram"},
		func = function(index, win)
			win:move({ 0, (desktopFrame.h - win:frame().h) / 2, desktopFrame.w / 2, win:frame().h })
		end
	},
}
-- 应用窗口布局
function applyLayout(layouts, app)
    if not app then return end
    
    local appName = app:title()
    
    for i, layout in ipairs(layouts) do
        local names = type(layout.name) == "table" and layout.name or {layout.name}
        
        for _, layAppName in ipairs(names) do
            if layAppName == appName and layout.func then
                local wins = app:allWindows()
                local counter = 1
                
                for j, win in ipairs(wins) do
                    if win:isVisible() then
                        layout.func(counter, win)
                        counter = counter + 1
                    end
                end
                return  -- 找到匹配后直接返回
            end
        end
    end
end
--------**--------
-- App手动窗口布局
--------**--------
hotkey.bind(hyper_ctrl, "`", function() applyLayout(layouts, win.focusedWindow():application()) end)
--------**--------
-- App自动窗口布局
--------**--------
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
    	hs.timer.doAfter(0.5, function()
			applyLayout(layouts, appObject)
		end)
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
hotkey.bind(hyper_coc, ".", function()
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
-- appWatcherForresize = app.watcher.new(applicationWatcher)
-- appWatcherForresize:start()