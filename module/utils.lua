-- 占位函数或默认回调函数
function noop() end

--- 用于 Canvas 过渡效果
-- @param options 参数配置
--   @field duration 过渡时长
--   @field easing 缓动函数，函数接受一个真实进度并返回缓动后的进度
--   @field onProgress 过渡时触发
--   @field onEnd 过渡结束后触发
-- @return 用于取消过渡的函数
function animate(options)
	local duration = options.duration
	local easing = options.easing
	local onProgress = options.onProgress
	local onEnd = options.onEnd or noop
  
	local st = hs.timer.absoluteTime()
	local timer = nil
  
	local function progress()
		local now = hs.timer.absoluteTime()
	  	local diffSec = (now - st) / 1000000000
  
	  	if diffSec <= duration then
			onProgress(easing(diffSec / duration))
			timer = hs.timer.doAfter(1 / 60, function() progress() end)
	  	else
			timer = nil
			onProgress(1)
			onEnd()
	  	end
	end
  
	-- 初始执行
	progress()
  
	return function()
	  	if timer then
			timer:stop()
			onEnd()
	  	end
	end
end

-- 缓动函数，让动画在开始时较慢，然后在结束时加速
function easeOutQuint(t)
	return 1 - math.pow(1 - t, 5);
end

-- 函数func在delay时间内只会执行一次, 当func被多次调用时,如果delay时间内还没有执行完func,则将最新的参数保存起来,等到下次delay时间到了再一次性执行。
function throttle(func, delay)
	local wait = false
	local storedArgs = nil
	local timer = nil
  
	local function checkStoredArgs()
		if storedArgs == nil then
			wait = false
		else
			func(table.unpack(storedArgs))
			storedArgs = nil
			timer = hs.timer.doAfter(delay, checkStoredArgs)
		end
	end
  
	return function(...)
	  	local args = { ... }
  
		if wait then
			storedArgs = args
			return
		end
	
		func(table.unpack(args))
		wait = true
		timer = hs.timer.doAfter(delay, checkStoredArgs)
	end
end

-- 限定竖直在指定的范围内
function clamp(value, min, max)
	return math.max(math.min(value, max), min)
end

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

-- 从数组某个指定index开始重新排序
function reOrder(list, indexField, startIndex)
	table.sort(list, function(a, b)
		local aRelative = (a[indexField] - startIndex + #list) % #list
		local bRelative = (b[indexField] - startIndex + #list) % #list
		return aRelative < bRelative
	end)
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
function hide(canvas, fadetime, isAnimate)
    if not fadetime then
        fadetime = 0
    end
	if canvas and canvas:isShowing() then
		if not animateOption then
			canvas:hide(fadetime)
		else
			animate({
				duration = fadeTime,
				easing = easeOutQuint,
				onProgress = function(progress)
					canvas:transformation(
						c.matrix.identity()
							:translate(100, 100)
							:scale((0.1 * progress) + 0.9)
							:translate(-100, -100)
					)
					canvas:alpha(1 * progress)
				end
			})
			canvas:hide()
		end
	end
end

-- 显示图层
function show(canvas, fadetime, isAnimate)
    if not fadetime then
        fadetime = 0
    end
	if canvas and not canvas:isShowing() then
		if not animateOption then
			canvas:show(fadetime)
		else
			animate({
				duration = fadeTime,
				easing = easeOutQuint,
				onProgress = function(progress)
					canvas:transformation(
						c.matrix.identity()
							:translate(100, 100)
							:scale((0.1 * progress) + 0.9)
							:translate(-100, -100)
					)
					canvas:alpha(1 * progress)
				end
			})
			canvas:show()
		end
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

-- hammerspoon配置更新
function updateHammerspoon()
	local task = hs.task.new("/usr/bin/git", function(exitCode, stdOut, stdErr)
        if exitCode == 0 and stdOut and not stdOut:match("Already up to date") then
            print("配置已更新, 正在重载...")
            hs.reload()
        end
    end, {"-C", HOME .. "/.hammerspoon", "pull"})
    
    task:start()
end