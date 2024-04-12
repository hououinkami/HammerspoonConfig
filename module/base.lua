-- 延迟函数
function delay(gap, func)
	local delaytimer = hs.timer.delayed.new(gap, func):start()
	return delaytimer
end

-- 删除计时器
function deleteTimer(timer)
	if timer then
		timer:stop()
		timer = nil
	end
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

-- 文本按中英数分割数组
function stringSplit2(s)
    local s_list= {}
	local s_ = ""
	local _s = ""
	for i in string.gmatch(s, "[%z\1-\127\194-\244][\128-\191]*") do
		if i:find("%w") then
			if #_s >= 1 then
				table.insert(s_list, _s)
			end
			_s = ""
			s_ = s_ .. i
		else
			if #s_ >= 1 then
				table.insert(s_list, s_)
			end
			s_ = ""
			_s = _s .. i
		end
	end
	if #_s > 0 then
		table.insert(s_list, _s)
	end
	if #s_ > 0 then
		table.insert(s_list, s_)
	end
    return s_list
end

-- 获取文本字数
function countWords(str)
    local count = 0
    for word in str:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        count = count + 1
    end
    return count
end

-- 比较字符串相似度
function compareString(strA, strB)
	strA = stringSplit(string.lower(strA))
	strB = stringSplit(string.lower(strB))
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
        fadetime = 0
    end
    if canvas and canvas:isShowing()then
        canvas:hide(fadetime)
    end
end

-- 显示图层
function show(canvas,fadetime)
    if not fadetime then
        fadetime = 0
    end
	if canvas and not canvas:isShowing() then
		canvas:show(fadetime)
	end
end

-- 删除图层
function delete(canvas)
	if canvas then
		hide(canvas)
		canvas:clickActivating(false)
		canvas:mouseCallback(nil)
		canvas:canvasMouseEvents(nil, nil, nil, nil)
		canvas = nil
		collectgarbage()
	end
end

-- 热更新
function hotfix(_mname)
	print(string.format("%s を更新しました", _mname))
	if package.loaded[_mname] then
		print(string.format("%s をリロード", _mname))
		package.loaded[_mname] = nil
		require( _mname )
	else
		print(string.format("%s はロードされていません", _mname))
	end
end

-- 获取文件列表
function getAllFiles(dir)
	local files = {}
	local p = io.popen('ls -a "'..dir..'"')
	for file in p:lines() do
	  table.insert(files, dir..'/'..file)
	end
	p:close()
	return files
end

-- HTTP Method
function httpRequest(method, url, header, body, fn)
	if method == "GET" then
		hs.http.asyncGet(url, header, fn)
	elseif method == "POST" then
		hs.http.asyncPost(url, body, header, fn)
	end
end

-- 音量调整
function setVolume(method, step)
	if not step then
		step = 1
	end
	local setVolumeScript = "set volume output volume "
	local _,currentVolume,_ = as.applescript([[(get volume settings)'s output volume]])
	if method == "up" then
		as.applescript(setVolumeScript .. currentVolume + step)
	elseif method == "down" then
		as.applescript(setVolumeScript .. currentVolume - step)
	end
end