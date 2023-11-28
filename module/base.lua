-- 延迟函数
function delay(gap, func)
	local delaytimer = hs.timer.delayed.new(gap, func)
	delaytimer:start()
end

-- 删除Menubar
function deletemenubar(menubar)
	if menubar then
		menubar:delete()
	end
end

-- 文本分割成数组
function stringSplit(s, p)
    local rt= {}
	if p then
    	string.gsub(s, '[^'..p..']+', function(w) table.insert(rt, w) end)
	else
		for i in string.gmatch(s, "[%z\1-\127\194-\244][\128-\191]*") do
			table.insert(rt, i)
		end
	end
    return rt
end

-- 比较字符串相似度
function compareString(strA, strB)
	strA = stringSplit(strA)
	strB = stringSplit(strB)
	local tempTb = {}
	for m = 1, (#strA + 1), 1 do
		tempTb[m] = {}
		tempTb[m][1] = m - 1
	end
	for n = 1, (#strB + 1), 1 do
		tempTb[1][n] = n - 1
	end
	for i = 2, (#strA + 1) , 1 do
		for j = 2, (#strB + 1), 1 do
			local x = tempTb[i - 1][j] + 1 --删除
			local y = tempTb[i][j - 1] + 1 --插入 
			local z = 0
			if strA[i - 1] == strB[j - 1] then --替换
				z = tempTb[i -1][j - 1]
			else
				z = tempTb[i -1][j - 1] + 1
			end
			tempTb[i][j] = math.min(x,y,z) 
		end
	end
	return (1- tempTb[#strA + 1][#strB + 1]/math.max(#strA, #strB))*100
end

-- 获取App菜单栏文字菜单项目
function getmenubarItemLeft(app)
	local appElement = ax.applicationElement(app)
	local MenuElements = {}
	if appElement then
		for i = #appElement, 1, -1 do
			local entity = appElement[i]
			if entity then
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
end

-- 获取App菜单栏图标
function getmenubarItemRight(app)
	local appElement = ax.applicationElement(app)
	local extraMenuElements = {}
	if appElement then
		for i = #appElement, 1, -1 do
			local entity = appElement[i]
			if entity and entity.AXRole == "AXMenuBar" then
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

-- 获取菜单栏文字菜单最右端位置
function getMenu()
	local Menu = getmenubarItemLeft(app.frontmostApplication())
	local lastMenu = 0
	if Menu then
		if #Menu > 0 then
			for _,m in ipairs (Menu) do
				local mf = m.AXFrame
				if mf then
					if mf.x + mf.w > lastMenu then
						lastMenu = mf.x + mf.w
					end
				end
			end
		end
	end
	return lastMenu
end

-- 获取菜单栏图标最左端位置
function getmenuIcon()
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

-- 隐藏图层
function hide(canvas,fadetime)
    if not fadetime then
        fadetime = 1
    end
    if canvas then
        canvas:hide(fadetime)
    end
end

-- 显示图层
function show(canvas,fadetime)
    if not fadetime then
        fadetime = 1
    end
	if canvas then
		canvas:show(fadetime)
	end
end

-- 删除图层
function delete(canvas)
	if canvas then
		canvas:clickActivating(false)
		canvas:mouseCallback(nil)
		canvas:canvasMouseEvents(nil, nil, nil, nil)
		canvas = nil
		collectgarbage()
	end
end