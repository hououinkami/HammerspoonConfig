win = require("hs.window")
c = require("hs.canvas")
as = require("hs.osascript")
local wRe = 0.12
local hRe = 2 / 3
local gap = 10
-- 仿台前调度
function windowsControl()
	local allWindows = win.orderedWindows()
    local winCount = 0
    for i, v in ipairs(allWindows) do
        winCount = winCount + 1
    end
	local winSnap = {}
    screenframe = hs.screen.mainScreen():frame()
    background = c.new({x = screenframe.x, y = screenframe.h * hRe / 4, h = screenframe.h * hRe, w = screenframe.w * wRe}):level(c.windowLevels.cursor)
    background:replaceElements(
		{-- 背景
			id = "background",
			type = "rectangle",
			action = "fill",
			roundedRectRadii = {xRadius = 6, yRadius = 6},
			fillColor = {alpha = bgAlpha, red = bgColor[1] / 255, green = bgColor[2] / 255, blue = bgColor[3] / 255},
			trackMouseEnterExit = true,
			trackMouseUp = true
		}
    )
    snapHeight = (background:frame().h - (winCount + 1) * gap) / winCount
    count = 1
    for i, v in ipairs(allWindows) do
        background:appendElements(
            {
                id = v:id(),
                frame = {x = gap, y = gap * count + snapHeight * (count - 1), h = snapHeight, w = background:frame().w - 2 * gap},
                type = "image",
                image = win.snapshotForID(v:id()),
                trackMouseEnterExit = true,
                trackMouseUp = true
            }
        )
        count = count + 1
	end
    --background:show()
end
--windowsControl()



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
