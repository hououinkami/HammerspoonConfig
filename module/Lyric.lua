require ('module.base') 
require ('module.apple-music') 
require ('config.lyric')
local secret = io.open(os.getenv("HOME") .. "/.hammerspoon/module/secret.lua", "r")
if secret then
    require ('module.secret')
    io.close(secret)
else
    lyricAPI = "https://yourownlyricapi.com/"
end

Lyric = {}
-- 获取并显示歌词
Lyric.main = function()
	-- 若没有联网则不搜寻歌词
	local v4,v6 = hs.network.primaryInterfaces()
	if v4 == false and v6 == false then
		return
	end
	-- 初始化
    lyricurl = nil
	lyricTable = nil
	lineNO = 1
	hide(c_lyric)
	if c_lyric then
		c_lyric["lyric"].text = ""
	end
	if lyricTimer then
		lyricTimer:stop()
	end
	-- 搜索的关键词
	if searchType == nil or searchType == "A" then
		keyword = Music.title() .. " " .. Music.artist()
	elseif searchType == "B" then
		keyword = Music.title():gsub("%(.*%)",""):gsub("（.*）","") .. " " .. Music.artist()
	elseif searchType == "C" then
		keyword = Music.title():gsub("%(.*%)",""):gsub("（.*）","")
	end
	-- 搜寻本地歌词文件
	if searchType == nil or searchType == "A" then
		local lyricfileName = Music.title() .. " - " .. Music.artist()
		lyricfileExist, lyricfileContent = Lyric.load(lyricfileName)
		if lyricfileExist then
			lyricTable = Lyric.edit(lyricfileContent)
		else
			lyricTable = Lyric.search(keyword)
			return
		end
	else
		lyricTable = Lyric.search(keyword)
		return
	end	
	if lyricTable then
		-- 歌词图层初始化
		Lyric.setcanvas()
		lyricTimer = hs.timer.new(1, function()
			a = lineNO
			Lyric.show(a,lyricTable)
			b = stayTime + lyricTimeOffset or 1 + lyricTimeOffset
			if lastLine == true then
				b = Music.duration() - Music.currentposition()
			end
			if lyricTimer and b > 0 then
				lyricTimer:setNextTrigger(b)
			end
		end):start()
	end
end

-- 搜索歌词并保存
Lyric.search = function(keyword)
	-- 获取歌曲ID
	local musicurl = lyricAPI .. "search?keywords=" .. hs.http.encodeForQuery(keyword) .. "&limit=10"
	-- 监控是否陷入死循环
	print("正在搜寻 " .. keyword .. " 的歌词...")
    hs.http.asyncGet(musicurl, nil, function(musicStatus,musicBody,musicHeader)
        if musicStatus == 200 then
            local musicinfo = hs.json.decode(musicBody)
            local similarity = 0
			if not musicinfo.result then
				return
			end
            if #musicinfo.result.songs > 0 then
				-- 判断是否需要重新搜索
				if compareString(musicinfo.result.songs[1].name, Music.title()) < 75 then
					if searchType == nil or searchType == "A" then
						searchType = "B"
					elseif searchType == "B" then
						searchType = "C"
					elseif searchType == "C" or searchType == nil then
						searchType = nil
						print("搜寻不到匹配的歌词")
						return
					end
					Lyric.main()
					return
				end
                for i = 1, #musicinfo.result.songs, 1 do
					if compareString(musicinfo.result.songs[i].name, Music.title()) > 90 then
						if compareString(musicinfo.result.songs[i].artists[1].name, Music.artist()) == 100 then
							song = i
							break
						end
						if compareString(musicinfo.result.songs[i].artists[1].name, Music.artist()) > similarity then
							similarity = compareString(musicinfo.result.songs[i].artists[1].name, Music.artist())
							song = i
						end
					end
                end
				if song then
                	lyricurl = lyricAPI .. "lyric?id=" .. musicinfo.result.songs[song].id
				end
            end
        end
		searchType = nil
		if lyricurl then
			hs.http.asyncGet(lyricurl, nil, function(status,body,headers)
				if status == 200 then
					local lyricRaw = hs.json.decode(body)
					if lyricRaw.lrc then
						lyric = lyricRaw.lrc.lyric
						Lyric.save(lyric)
						lyricTable = Lyric.edit(lyric)
						lyricDownloaded = true
						Lyric.main()
					end
				end
			end)
		end
		return lyricTable
    end)
end

-- 将歌词从json转变成table
Lyric.edit = function(lyric)
	local lyricData = stringSplit(lyric,"\n")
	local lyricTable = {}
	local blackList = {"作曲","作词","编曲","作詞","編曲","曲：","歌："}
	if #lyricData > 2 then
		for l = 1, #lyricData, 1 do
			if string.find(lyricData[l],'-1%]') then
				print("搜寻不到匹配的歌词")
				break
			end
			for i,v in ipairs(blackList) do
				if string.find(lyricData[l],v) then
					lyricData[l] = lyricData[l]:gsub(v .. ".*", "")
					break
				end
			end
			if string.find(lyricData[l],'%[%d+:%d+%.%d+%]') or string.find(lyricData[l],'%[%d+:%d+%:%d+%]') then
				local lyricLine = {}
				line = lyricData[l]:gsub("%[",""):gsub("%]","`")
				time = stringSplit(line, "`")[1]:gsub("%.",":")
				info = stringSplit(line, "`")[2] or ""
				hour = 0
				min = tonumber(stringSplit(time, ":")[1])
				if min > 59 then
					if min == 99 then
						print("搜寻不到匹配的歌词")
					end
					hour = min // 60
					min = min - 60 * hour
				end
				sec = stringSplit(time, ":")[2]
				minisec = stringSplit(time, ":")[3] or 0
				time = hs.timer.seconds(hour .. ":" .. min .. ":" .. sec) + minisec / 1000
				lyricLine["index"] = l
				lyricLine["time"] = time
				lyricLine["lyric"] = info
				table.insert(lyricTable, lyricLine)
			end
		end
	end
	if #lyricTable == 0 then
		lyricTable = nil
		print("搜寻不到匹配的歌词")
	end
	return lyricTable
end

-- 显示歌词
Lyric.show = function(startline,lyric)
	if not lyric then
		return
	end
	-- 定位
	local currentPosition = Music.currentposition() - lyricTimeOffset
	for l = startline, #lyric, 1 do
		if l < #lyric then
			if currentPosition < lyric[l].time or currentPosition > lyric[l+1].time then
				for j = 1, #lyric, 1 do
					if j < #lyric then
						if currentPosition > lyric[j].time and currentPosition < lyric[j+1].time then
							l = j
							break
						end
					else
						l = #lyric
					end
				end
			end
		end
		if l < #lyric then
			if currentPosition > lyric[l].time and currentPosition < lyric[l+1].time then
				currentLyric = lyric[l].lyric
				stayTime = lyric[l+1].time - currentPosition or 0
				lineNO = l
				lastLine = false
				break
			end
		else
			if currentPosition >= lyric[l].time then
				currentLyric = lyric[#lyric].lyric
				stayTime = 1
				lineNO = l
				lastLine = true
			end
		end
	end
	-- 仅播放状态下显示
	if Music.state() == "playing" then
		if not lyricTimer then
			Lyric.main()
		end
		if not c_lyric:isShowing() then
			show(c_lyric)
		end
		lyricTimer:start()
	elseif Music.state() == "paused" then
		hide(c_lyric)
		lyricTimer:stop()
	else
		delete(c_lyric)
		lyricTimer:stop()
		lyricTimer = nil
	end
	-- 歌词刷新
	if currentLyric ~= lyrictext then
		c_lyric["lyric"].text = Lyric.handleLyric(currentLyric)
		lyrictext = currentLyric
		-- 设置歌词图层自适应宽度
		lyricSize = c_lyric:minimumTextSize(1, c_lyric["lyric"].text)
		c_lyric:frame({x = 0, y = desktopFrame.h + menubarHeight - lyricSize.h, h = lyricSize.h, w = screenFrame.w})
		c_lyric["lyric"].frame.x = (c_lyric:frame().w - lyricSize.w) / 2
		c_lyric["lyric"].frame.y = c_lyric:frame().h - lyricSize.h
		c_lyric["lyric"].frame.h = lyricSize.h
	end
end

-- 将歌词按照中英数分割方便设置不同字体
Lyric.handleLyric = function(lyric)
	local lyricObjTable = {}
	if #lyric > 0 then
		local s_list = stringSplit2(lyric)
		for i,v in ipairs(s_list) do
			lyricStyled = hs.styledtext.new(v, {
				font = { 
					name = lyricTextFont, 
					size = lyricTextSize
				},
				color = { 
					red = lyricTextColor[1] / 255, 
					green = lyricTextColor[2] / 255, 
					blue = lyricTextColor[3] / 255
				},
				backgroundColor = {
					red = lyricbgColor[1] / 255, 
					green = lyricbgColor[2] / 255, 
					blue = lyricbgColor[3] / 255, 
					alpha = lyricbgAlpha 
				},
				strokeColor = { 
					red = lyricStrokeColor[1] / 255, 
					green = lyricStrokeColor[2] / 255, 
					blue = lyricStrokeColor[3] / 255, 
					alpha = lyricStrokeAlpha 
				},
				strokeWidth = lyricStrokeWidth,
				shadow = { 
					color = { 
						red = lyricShadowColor[1] / 255, 
						green = lyricShadowColor[2] / 255, 
						blue = lyricShadowColor[3] / 255, 
						alpha = lyricShadowAlpha 
					}, 
					blurRadius = lyricShadowBlur, 
					offset = lyricShadowOffset 
				},
			})
			if not v:find("%w") then
				table.insert(lyricObjTable, lyricStyled)
			else
				table.insert(lyricObjTable, lyricStyled:setStyle({
					font = { 
						name = lyricTextFont2, 
						size = lyricTextSize
					}
				}))
			end
		end
		lyricObj = nil
		for i,v in ipairs(lyricObjTable) do
			if not lyricObj then
				lyricObj = v
			else
				lyricObj = lyricObj .. v
			end
		end
		return lyricObj
	end
end

-- 建立歌词图层
Lyric.setcanvas = function() 
	if not c_lyric then
		c_lyric = c.new({x = 0, y = desktopFrame.h + menubarHeight - 50, h = 50, w = screenFrame.w}):level(c.windowLevels.cursor)
		c_lyric:appendElements(
			{ -- 歌词
				id = "lyric",
				frame = {x = 0, y = 0, h = c_lyric:frame().h, w = c_lyric:frame().w},
				type = "text",
				text = "",
			}
		):behavior(c.windowBehaviors[1])
	end
end

-- 加载本地歌词文件
Lyric.load = function(lyricfileName)
	lyricfileContent = nil
	lyricfileExist = false
	alllyricFile = getAllFiles(lyricPath)
	local specialString = {"(", ")", ".", "+", "-", "*", "?", "[", "]", "^", "$"} 
	local _filename = lyricfileName
	for i,v in ipairs(specialString) do
		_filename = _filename:gsub("%" .. v,"%%" .. v)
	end
	for _,file in pairs(alllyricFile) do
		local lyricFile = lyricPath .. lyricfileName .. ".lrc"
		if file:find(_filename) then
			-- 以可读写方式打开文件
			local _lrcfile = io.open(lyricFile, "r+")
			-- 读取文件所有内容
			lyricfileContent = _lrcfile:read("*a")
			lyricfileExist = true
			_lrcfile:close()
			print("加载本地歌词文件")
			break
		end
    end
	return lyricfileExist,lyricfileContent
end

-- 保存歌词至本地文件
Lyric.save = function(lyric)
	local lyricFile = lyricPath .. Music.title() ..  " - " .. Music.artist() .. ".lrc"
	local lyricExt = io.open(lyricFile, "r")
	if not lyricExt then
		file = io.open(lyricFile, "w+")
		file:write(lyric)
		file:close()
		print("歌词文件已下载")
	end
end

-- 歌词显示与隐藏快捷键
hotkey.bind(hyper_cs, "l", function()
    if c_lyric then
        if not c_lyric:isShowing() then
            lyricTimer:start()
        else
            hide(c_lyric)
            lyricTimer:stop()
        end
	end
end)

-- 歌词模块停用与启用快捷键
hotkey.bind(hyper_cos, "l", function()
    if lyricTimer and lyricTimer:running() then
        delete(c_lyric)
		lyricTimer:stop()
    else
		Lyric.setcanvas()
        Lyric.main()
	end
end)
