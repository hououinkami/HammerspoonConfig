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
	local formateString = {"%(.*%)", "（.*）", " %- 「.*」", "「.*」", "OP$", "ED$"} 
	local titleFormated = Music.title()
	for i,v in ipairs(formateString) do
		titleFormated = titleFormated:gsub(v,"")
	end
	if searchType == nil or searchType == "A" then
		keyword = Music.title() .. " " .. Music.artist()
		searchtitle = Music.title()
	elseif searchType == "B" then
		keyword = titleFormated .. " " .. Music.artist()
		searchtitle = titleFormated:gsub("(.-)[%s]*$", "%1")
	elseif searchType == "C" then
		keyword = titleFormated
		searchtitle = titleFormated:gsub("(.-)[%s]*$", "%1")
	end
	-- 搜寻本地歌词文件
	if searchType == nil or searchType == "A" then
		if lyricTemp then
			lyricTable = lyricTemp
			lyricTemp = nil
			print("オンライン歌詞をロード中")
		else
			local lyricfileName = Music.title() .. " - " .. Music.artist()
			lyricfileExist, lyricfileContent, lyricfileError = Lyric.load(lyricfileName)
			if lyricfileError then
				return
			end
			if lyricfileExist then
				lyricTable = Lyric.edit(lyricfileContent)
			else
				lyricTable = Lyric.search(keyword)
				return
			end
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
	local musicurl = lyricAPI .. "search?keywords=" .. hs.http.encodeForQuery(keyword):gsub("%%26","&") .. "&limit=10"
	-- 监控是否陷入死循环
	print(keyword .. " の歌詞を検索中...")
    hs.http.asyncGet(musicurl, nil, function(musicStatus,musicBody,musicHeader)
        if musicStatus == 200 then
            local musicinfo = hs.json.decode(musicBody)
            local similarity = 0
			if not musicinfo.result then
				return
			end
			if not musicinfo.result.songs then
				print("該当する歌詞はません")
				return
			end
            if #musicinfo.result.songs > 0 then
				-- 歌手名称里有括弧的情况
				if Music.artist():find("%(.*%)") or Music.artist():find("（.*）") then
					searchartist1 = Music.artist():gsub("%(.*%)",""):gsub("（.*）","")
					searchartist2 = Music.artist():match('%((.+)%)') or Music.artist():match('（(.+)）')
				end
				for i = 1, #musicinfo.result.songs, 1 do
					if compareString(musicinfo.result.songs[i].name, searchtitle) > 80 then
						if compareString(musicinfo.result.songs[i].artists[1].name, Music.artist()) == 100 then
							song = i
							break
						end
						if Music.artist():find("%(.*%)") or Music.artist():find("（.*）") then
							tempS = math.max(compareString(musicinfo.result.songs[i].artists[1].name, searchartist1), compareString(musicinfo.result.songs[i].artists[1].name, searchartist2))
						else
							tempS = 0
						end
						if math.max(compareString(musicinfo.result.songs[i].artists[1].name, Music.artist()),tempS) > similarity then
							similarity = math.max(compareString(musicinfo.result.songs[i].artists[1].name, Music.artist()),tempS)
							song = i
						end
					end
                end
				-- 判断是否需要重新搜索
				if song then
					lyricurl = lyricAPI .. "lyric?id=" .. musicinfo.result.songs[song].id
					song = nil
				else
					if searchType == nil or searchType == "A" then
						searchType = "B"
					elseif searchType == "B" then
						searchType = "C"
					elseif searchType == "C" then
						searchType = nil
						print("該当する歌詞はません")
						return
					end
					Lyric.main()
					return
				end
            end
        end
		searchType = nil
		if lyricurl then
			print(lyricurl .. " から歌詞を取得中...")
			hs.http.asyncGet(lyricurl, nil, function(status,body,headers)
				if status == 200 then
					local lyricRaw = hs.json.decode(body)
					if lyricRaw.lrc then
						lyric = lyricRaw.lrc.lyric
						if string.find(lyric,'-1%]') or lyric == "" then
							print("該当する歌詞はません")
							return
						end
						if Music.existinlibrary() or Music.loved() then
							Lyric.save(lyric)
						else
							lyricTemp = Lyric.edit(lyric)
						end
						Lyric.main()
					end
				end
			end)
		else
			print("該当する歌詞はません")
		end
		return lyricTable
    end)
end

-- 将歌词从json转变成table
Lyric.edit = function(lyric)
	local lyricData = stringSplit(lyric,"\n")
	local allLine = #lyricData
	local lyricTable = {}
	if #lyricData > 2 then
		for l = 1, #lyricData, 1 do
			for i,v in ipairs(blackList) do
				if string.find(lyricData[l],v) then
					lyricData[l] = lyricData[l]:gsub(v .. ".*", "")
					break
				end
			end
			if string.find(lyricData[l],'%[%d+:%d+') then
				local lyricLine = {}
				line = lyricData[l]:gsub("%[",""):gsub("%]","`")
				_line = stringSplit(line, "`")
				if #_line == 1 then
					table.insert(_line, "")
				end
				lyricLine.index = l
				lyricLine.time = _line[1]:gsub("%.",":")
				lyricLine.lyric = _line[#_line] or ""
				table.insert(lyricTable, lyricLine)
				-- 多个时间戳时的处理
				if #_line > 2 then
					for t = 2, #_line - 1, 1 do
						local lyricLine = {}
						allLine = allLine + 1
						lyricLine.index = allLine
						lyricLine.time = _line[t]:gsub("%.",":")
						lyricLine.lyric = _line[#_line] or ""
						table.insert(lyricTable, lyricLine)
					end
				end
			end
		end
	end
	if #lyricTable == 0 then
		lyricTable = nil
		print("該当する歌詞はません")
	else
		for i,v in ipairs(lyricTable) do
			hour = 0
			time = v.time
			min = tonumber(stringSplit(time, ":")[1])
			if min > 59 then
				if min == 99 then
					print("該当する歌詞はません")
					Lyric.delete(Music.title() ..  " - " .. Music.artist())
				end
				hour = min // 60
				min = min - 60 * hour
			end
			sec = stringSplit(time, ":")[2]
			minisec = stringSplit(time, ":")[3] or 0
			v.time = hs.timer.seconds(hour .. ":" .. min .. ":" .. sec) + minisec / 1000
		end
		-- 按时间排序
		table.sort(lyricTable,function(a,b) return a.time < b.time end)
		for i = 1, #lyricTable, 1 do
			lyricTable[i].index = i
		end
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
		if not c_lyric:isShowing() then
			show(c_lyric)
		end
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
		-- 不加载错误歌词
		if file:find(_filename .. "_ERROR.lrc") then
			print("歌詞が間違った")
			lyricfileError = true
			break
		end
		lyricfileError = false
		local lyricFile = lyricPath .. lyricfileName .. ".lrc"
		if file:find(_filename) then
			-- 以可读写方式打开文件
			local _lrcfile = io.open(lyricFile, "r+")
			-- 读取文件所有内容
			lyricfileContent = _lrcfile:read("*a")
			lyricfileExist = true
			_lrcfile:close()
			print("ローカル歌詞をロード中")
			break
		end
    end
	return lyricfileExist,lyricfileContent,lyricfileError
end

-- 保存歌词至本地文件
Lyric.save = function(lyric)
	local lyricFile = lyricPath .. Music.title() ..  " - " .. Music.artist() .. ".lrc"
	local lyricExt = io.open(lyricFile, "r")
	if not lyricExt then
		file = io.open(lyricFile, "w+")
		file:write(lyric)
		file:close()
		print("歌詞ファイルをダウンロードしました")
	end
end

Lyric.delete = function(file)
	local filepath = lyricPath .. file .. ".lrc"
	os.remove(filepath)
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

-- 歌词错误时标记
hotkey.bind(hyper_coc, "l", function()
    local lyricFile = lyricPath .. Music.title() ..  " - " .. Music.artist() .. ".lrc"
	local lyricExt = io.open(lyricFile, "r")
	if lyricExt then
		os.rename(lyricFile, lyricPath .. Music.title() ..  " - " .. Music.artist() .. "_ERROR.lrc")
		print("歌詞はエラーとしてマーク")
		Lyric.main()
	end
end)
