--------**--------
-- 变量设置
--------**--------
win.animationDuration = 0
resizeStep = 10
screenFrame = hs.screen.mainScreen():fullFrame()
desktopFrame = hs.screen.mainScreen():frame()
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
    local window = win.focusedWindow()
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

--------**--------
-- 点击桌面时显示桌面
--------**--------
-- 获取App菜单栏文字项目
getmenubarItemLeft = function(app)
    local appElement = ax.applicationElement(app)
    local MenuElements = {}
    if appElement then
        for i = #appElement, 1, -1 do
            local entity = appElement[i]
            if entity.AXRole == "AXMenuBar" then
                for j = 1, #entity, 1 do
                    local menuBarEntity = entity[j]
                    if menuBarEntity then
                        if menuBarEntity.AXSubrole ~= "AXMenuExtra" then
                            table.insert(MenuElements, menuBarEntity)
                        end
                    end
                end
                return MenuElements
            end
        end
    end
end

-- 获取App菜单栏图标
getmenubarItemRight = function(app)
    local appElement = ax.applicationElement(app)
    local extraMenuElements = {}
    if appElement then
        for i = #appElement, 1, -1 do
            local entity = appElement[i]
            if entity.AXRole == "AXMenuBar" then
                for j = 1, #entity, 1 do
                    local menuBarEntity = entity[j]
                    if menuBarEntity then
                        if menuBarEntity.AXSubrole == "AXMenuExtra" then
                            table.insert(extraMenuElements, menuBarEntity)
                        end
                    end
                end
                return extraMenuElements
            end
        end
    end
end
-- 获取菜单尺寸
getmenuFrame = function()
    -- 菜单栏菜单
    local MenuElements = getmenubarItemLeft(app.frontmostApplication())
    if MenuElements then
        if #MenuElements > 0 then
            for k = 1, #MenuElements, 1 do
                local isSelected = MenuElements[k].AXSelected
                if isSelected == true then
                    menuFrame = MenuElements[k][1].AXFrame
                    return menuFrame
                end
            end
        end
    end
    -- 菜单栏图标
    -- local allApp = app.runningApplications()
    -- for _,a in ipairs (allApp) do
    --     local extraMenuElements = getmenubarItemRight(a)
    --     if extraMenuElements then
    --         if #extraMenuElements > 0 then
    --             for k = 1, #extraMenuElements, 1 do
    --                 local isSelected = extraMenuElements[k].AXSelected
    --                 if isSelected == true then
    --                     menuFrame = extraMenuElements[k].AXFrame
    --                     return menuFrame
    --                 end
    --                 break
    --             end
    --         end
    --     end
    -- end
end
-- 获取菜单栏文字菜单最右端位置
getMenu = function()
    local Menu = getmenubarItemLeft(app.frontmostApplication())
    local lastMenu = 0
    if Menu then
        if #Menu > 0 then
            for _,m in ipairs (Menu) do
                if m.AXFrame then
                    if m.AXFrame.x + m.AXFrame.w > lastMenu then
                        lastMenu = m.AXFrame.x + m.AXFrame.w
                    end
                end
            end
        end
    end
    return lastMenu
end
-- 获取菜单栏图标最左端位置
getmenuIcon = function()
    local MenuIcon = getmenubarItemRight(app.find("Hammerspoon"))
    local firstIcon = screenFrame.w
    if MenuIcon then
        if #MenuIcon > 0 then
            for _,i in ipairs (MenuIcon) do
                if i.AXFrame.x < firstIcon then
                    firstIcon = i.AXFrame.x
                end
            end
        end
    end
    return firstIcon
end
-- 判断是否点击了Dock的文件夹菜单
isdockFolder = function()
    local dockElement = ax.applicationElement(app.find("Dock"))[1]
    local point = hs.mouse.absolutePosition()
    local dockFolder = false
    local dockFolders = {}
    if dockElement then
        for i,v in ipairs (dockElement) do
            if v.AXSubrole == "AXFolderDockItem" then
                table.insert(dockFolders, v.AXFrame)
            end
        end
        for i,v in ipairs (dockFolders) do
            if point.x >= v.x and point.x <= v.x + v.w and point.y >= v.y and point.y <= v.y + v.h then
                dockFolder = true
                break
            end
        end
        return dockFolder
    end
end
-- 桌面是否有图标被选中
isiconSelected = function()
	local deskElement = ax.applicationElement(app.find("Finder"))
	local iconSelected = false
	for i,v in ipairs (deskElement) do
		if v.AXRole == "AXScrollArea" then
			iconElement = v[1]
			break
		end
	end
    for d,e in ipairs (iconElement) do
		if e.AXSelected == true then
			iconSelected = true
			break
		end
	end
    return iconSelected
end
-- 点击显示桌面
local isShowing = false
local ismenuClicked = false
local spaceID = hs.spaces.activeSpaces()[hs.screen.mainScreen():getUUID()]
showDesktop = hs.eventtap.new(
    {hs.eventtap.event.types.leftMouseUp, hs.eventtap.event.types.rightMouseUp}, function(e)
		-- 判断点击的是左键还是右键
		if e:getType() == hs.eventtap.event.types.leftMouseUp then
			mouseEvent = "left"
		elseif e:getType() == hs.eventtap.event.types.rightMouseUp then
			mouseEvent = "right"
		end
		local point = hs.mouse.absolutePosition()
		local gap = 5
		local menuPosition = getMenu()
		local iconPosition = getmenuIcon()
		-- 若菜单已触发，则退出函数
		if ismenuClicked == true or app.frontmostApplication():name() == "ミュージック" then
			ismenuClicked = false
		-- 若菜单未触发
		else
			-- 若点击了左键且菜单未触发
			if mouseEvent == "left" and not ((point.y <= desktopFrame.y and (point.x >= iconPosition or point.x <= menuPosition)) or isdockFolder() == true) then
				-- 判断是否切换了Space
				if hs.spaces.activeSpaces()[hs.screen.mainScreen():getUUID()] ~= spaceID then
					isShowing = false
					spaceID = hs.spaces.activeSpaces()[hs.screen.mainScreen():getUUID()]
				end
				local showing = false
				local allWindows = win.allWindows()
				local windowPosition = {}
				-- if getmenuFrame() then
				--     table.insert(windowPosition, menuFrame)
				-- end
				-- 获取非最小化的窗口
				for i, v in ipairs(allWindows) do
					if v:isMinimized() == false then
						table.insert(windowPosition, v:frame())
					end
				end
				isDesktop = true
				-- 菜单栏和Dock栏不触发
				if point.y <= desktopFrame.y or point.y >= desktopFrame.y + desktopFrame.h then
					isDesktop = false
				end
				-- 桌面图标选中时不触发
				if isiconSelected() == true then
					isDesktop = false
				end
				-- 点击到任意窗口不触发
				for i, v in ipairs(windowPosition) do
					if point.x >= v.x - gap and point.x <= v.x + v.w + gap and point.y >= v.y - gap and point.y <= v.y + v.h + gap then
						isDesktop = false
					end
				end
				-- 触发桌面显示开关
				if isShowing == true and isiconSelected() == false then
					hs.spaces.toggleShowDesktop()
					isShowing = false
					showing = true
				end
				if isDesktop == true and isShowing == false and showing == false then
					hs.spaces.toggleShowDesktop()
					isShowing = true
				end
			else
				ismenuClicked = true
			end
		end
    end
)
-- 若为全屏App则关闭显示桌面功能
fullscreenappWatcher = app.watcher.new(
	function(appName, eventType, appObject)
		if (eventType == app.watcher.activated) then
			if appObject then
				if appObject:focusedWindow() then
					if appObject:focusedWindow():isFullScreen() then
						showDesktop:stop()
					else
						showDesktop:start()
					end
				end
			end
		end
	end
)
fullscreenappWatcher:start()