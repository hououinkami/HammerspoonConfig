require ('module.base') 
require ('module.apple-music') 
require ('config.lyric')

Lyric = {}
-- 获取并显示歌词
Lyric.main = function()
	hide(c_lyric)
	-- 若没有联网则不搜寻歌词
	local v4,v6 = hs.network.primaryInterfaces()
	if v4 == false and v6 == false then
		print("歌詞の検索ができません、ネットワークの接続を確認してください。")
		return
	end
	-- 初始化
    lyricurl = nil
	lyricTable = nil
	lyrictext = ""
	lineNO = 1
	if c_lyric then
		c_lyric["lyric"].text = Lyric.handleLyric("")
	end
	if lyricTimer then
		lyricTimer:stop()
	end
	-- 搜索的关键词
	titleFormated = Music.title()
	if searchType == nil or searchType == "A" then
		keyword = titleFormated .. " " .. Music.artist()
	else
		local specialStringinTitle = {"%(.*%)", "（.*）", " %- 「.*」", "「.*」", "OP$", "ED$", "feat%..*"} 
		for i,v in ipairs(specialStringinTitle) do
			titleFormated = titleFormated:gsub(v,"")
		end
		titleFormated:gsub("(.-)[%s]*$", "%1")--去除歌曲名末尾空格
		if searchType == "B" then
			keyword = titleFormated .. " " .. Music.artist()
		elseif searchType == "C" then
			keyword = titleFormated
		end
	end
	-- 是否将存储歌词文件
	save = Music.existinlibrary() or Music.loved()
	filename = Music.title() ..  " - " .. Music.artist()
	-- 搜寻本地歌词文件
	if searchType == nil or searchType == "A" then
		if lyricOnline then
			lyricTable = lyricOnline
			lyricOnline = nil
			print("歌詞をロード中")
		else
			local lyricfileName = Music.title() .. " - " .. Music.artist()
			lyricfileExist, lyricfileContent, lyricfileError = Lyric.load(lyricfileName)
			-- 歌词文件标记为错误歌词则不执行操作
			if lyricfileError then
				return
			end
			-- 歌词文件存在则载入，否则执行搜索
			if lyricfileExist then
				-- 本地歌词不显示菜单栏图标
				-- if LyricBar and LyricBar:isInMenuBar() then
				-- 	LyricBar = nil
				-- end
				Lyric.menubar()
				lyricTable = Lyric.edit(lyricfileContent)
			else
				lyricTable = Lyric.search(keyword,save)
				return
			end
		end
	else
		lyricTable = Lyric.search(keyword,save)
		return
	end
	-- 显示歌词
	Lyric.show(lyricTable)
end

-- 歌词搜索API选择
Lyric.api = function(api)
	idAPI = nil
	lyricAPI = nil
	local secret = io.open(HOME .. "/.hammerspoon/module/secret.lua", "r")
	if not api and secret then
		require ('module.secret')
		io.close(secret)
		idAPI = lyricAPI .. "search?limit=10&offset=0&type=1&keywords="
		lyricAPI = lyricAPI .. "lyric?id="
		musicheaders = nil
	else
		idAPI = "https://music.163.com/api/search/pc?limit=10&offset=0&type=1&s="
		lyricAPI = "https://music.163.com/api/song/lyric?os=pc&lv=-1&kv=-1&tv=-1&id="
		musicheaders = {
			["User-Agent"] = "Mozilla/5.0 (iPhone; CPU iPhone OS 13_1_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 - mmbWebBrowse - ios",
			["cookie"] = "NMTID=00OImW8FZYRLmd7XU5cuO6K8blcSucAAAGMoACXwQ"
		}
	end
end
Lyric.api(true)

-- 搜索歌词并保存
Lyric.search = function(keyword,saveFile)
	-- 获取歌曲ID
	local musicurl = idAPI .. hs.http.encodeForQuery(keyword)
	print(keyword .. " の歌詞を検索中...")
    hs.http.asyncGet(musicurl, musicheaders, function(musicStatus,musicBody,musicHeader)
        if musicStatus == 200 then
			-- 若无手动选择需要下载的歌词则自动匹配
			if not song then
				musicinfo = hs.json.decode(musicBody)
				similarity = 0
				if not musicinfo.result then
					return
				end
				if musicinfo.result.songs and #musicinfo.result.songs > 0 then
					-- 在菜单栏显示首次搜索的候选结果
					if searchType == nil or searchType == "A" then
						Lyric.menubar(musicinfo.result.songs)
					end
					-- 处理特殊格式的歌手名称
					local specialStringinArtist = {"%(.+%)","（.+）","feat%..*"}
					for i,v in ipairs(specialStringinArtist) do
						if Music.artist():find(v) then
							searchartist1 = Music.artist():gsub(v,"")
							if v:find("%.%+") then
								v2 = v:gsub("%.%+","(.+)")
								searchartist2 = Music.artist():match(v2)
							end
						end
					end
					for i = 1, #musicinfo.result.songs, 1 do
						if compareString(musicinfo.result.songs[i].name, titleFormated) > 70 then
							if compareString(musicinfo.result.songs[i].artists[1].name, Music.artist()) == 100 then
								song = i
								break
							end
							if searchartist1 then
								tempS = compareString(musicinfo.result.songs[i].artists[1].name, searchartist1)
								searchartist1 = nil
							end
							if searchartist2 then
								tempS = math.max(tempS, compareString(musicinfo.result.songs[i].artists[1].name, searchartist2))
								searchartist2 = nil
							end
							tempS = math.max(compareString(musicinfo.result.songs[i].artists[1].name, Music.artist()),tempS or 0)
							if tempS > similarity then
								similarity = tempS
								song = i
							end
						end
					end
				end
			end
			-- 判断是否需要重新搜索
			if song then
				songid = id or musicinfo.result.songs[song].id
				lyricurl = lyricAPI .. songid
				song = nil
				id = nil
			else
				if searchType == nil or searchType == "A" then
					if titleFormated ~= Music.title() then
						searchType = "B"
					else
						searchType = "C"
					end
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
		searchType = nil
		if lyricurl then
			print("歌詞を取得中...")
			hs.http.asyncGet(lyricurl, nil, function(status,body,headers)
				if status == 200 then
					local lyricRaw = hs.json.decode(body)
					if lyricRaw.lrc then
						local lyric = lyricRaw.lrc.lyric
						if string.find(lyric,'-1%]') or lyric == ""  or string.find(lyric,'^%[99.*') then
							print("該当する歌詞はません")
							return
						end
						lyricOnline = Lyric.edit(lyric)
						if saveFile then
							Lyric.save(lyric,filename)
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
			-- 歌词黑名单替换为空行
			for i,v in ipairs(blackList) do
				if string.find(lyricData[l],v) then
					lyricData[l] = lyricData[l]:gsub(v .. ".*", "")
					break
				end
			end
			-- 只处理包含正确时间戳的歌词行
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
					multiTime = true
					for t = 2, #_line - 1, 1 do
						local lyricLine = {}
						allLine = allLine + 1
						lyricLine.index = allLine
						lyricLine.time = _line[t]:gsub("%.",":")
						if _line[#_line]:find('^%d+:%d+') then
							lyricLine.lyric = ""
						else
							lyricLine.lyric = _line[#_line]
						end
						table.insert(lyricTable, lyricLine)
					end
				end
			end
		end
		-- 将时间戳转换成秒
		for i,v in ipairs(lyricTable) do
			hour = 0
			time = v.time
			min = tonumber(stringSplit(time, ":")[1]) or 0
			if min > 59 then
				hour = min // 60
				min = min - 60 * hour
			end
			sec = stringSplit(time, ":")[2] or 0
			minisec = stringSplit(time, ":")[3] or 0
			v.time = hs.timer.seconds(hour .. ":" .. min .. ":" .. sec) + minisec / 1000
		end
		-- 若有多个时间戳的情况则将歌词表按时间排序
		if multiTime then
			table.sort(lyricTable,function(a,b) return a.time < b.time end)
			for i = 1, #lyricTable, 1 do
				lyricTable[i].index = i
			end
			multiTime = false
		end
	end
	-- 在最后插入空行方便处理
	table.insert(lyricTable, {index = #lyricTable + 1, time = Music.duration(), lyric = ""})
	return lyricTable
end

-- 显示歌词
Lyric.show = function(lyricTable)
	if lyricTable then
		-- 歌词图层初始化
		Lyric.setcanvas()
		-- 设定计时器
		lyricTimer = hs.timer.new(1, function()
			a = lineNO
			showLyric(a,lyricTable)
			stayTime = stayTime or 0
			b = stayTime + lyricTimeOffset
			if lyricTimer and b > 0 then
				lyricTimer:setNextTrigger(b)
			end
		end):start()
	end
	-- 歌词显示函数
	showLyric = function(startline,lyricTable)
		if not lyricTable then
			return
		end
		-- 歌词定位
		local currentPosition = Music.currentposition() - lyricTimeOffset
		for l = startline, #lyricTable - 1 , 1 do
			-- 快进或快退时从第一行开始重新定位
			if currentPosition < lyricTable[l].time or currentPosition > lyricTable[l+1].time then
				for j = 1, #lyricTable - 1, 1 do
					if currentPosition > lyricTable[j].time and currentPosition < lyricTable[j+1].time then
						l = j
						break
					end
				end
			end
			-- 正常情况下的定位
			if currentPosition > lyricTable[l].time and currentPosition < lyricTable[l+1].time then
				currentLyric = lyricTable[l].lyric
				stayTime = lyricTable[l+1].time - currentPosition or 0
				lineNO = l
				break
			end
		end
		-- 仅播放状态下显示
		if Music.state() == "playing" then
			if not c_lyric:isShowing() then
				show(c_lyric)
			end
			if not lyricTimer then
				Lyric.main()
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
			if lyricTimer and not lyricTimer:running() then
				lyricTimer:start()
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
	-- 文件名有'/'时替换成":"
	lyricfileName = lyricfileName:gsub("/",":")
	lyricfileContent = nil
	lyricfileExist = false
	alllyricFile = getAllFiles(lyricPath)
	-- 格式化正则检索词
	local specialString = {"(", ")", ".", "+", "-", "*", "?", "[", "]", "^", "$"} 
	local _filename = lyricfileName
	for i,v in ipairs(specialString) do
		_filename = _filename:gsub("%" .. v,"%%" .. v)
	end
	_filename = _filename:gsub("/",":")
	-- 搜寻本地歌词文件夹
	for _,file in pairs(alllyricFile) do
		-- 不加载错误歌词
		if file:find(_filename .. "_ERROR.lrc") then
			print("歌詞が間違った")
			lyricfileError = true
			break
		end
		lyricfileError = false
		-- 加载本地歌词文件
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
Lyric.save = function(lyric,filename)
	local _savename = string.gsub(filename,"/",":")
	local lyricFile = lyricPath .. _savename .. ".lrc"
	local lyricExt = io.open(lyricFile, "r")
	-- 判断储存本地歌词的文件夹是否存在
	local lyricFolder = io.open(lyricPath,"rb")
	if not lyricFolder then
		os.execute("mkdir ".. lyricPath)
	end
	-- 若歌词文件不存在则保存
	if not lyricExt or update then
		file = io.open(lyricFile, "w+")
		file:write(lyric)
		file:close()
		update = false
		print("歌詞ファイルをダウンロードしました")
	end
end

-- 删除当前曲目的本地歌词文件
Lyric.delete = function()
	local _deletename = string.gsub(Music.title() ..  " - " .. Music.artist(),"/",":")
	local filepath = lyricPath .. _deletename .. ".lrc"
	os.remove(filepath)
	local filepath_error = lyricPath .. _deletename .. "_ERROR.lrc"
	os.remove(filepath_error)
end

-- 歌词模块应用开关
Lyric.toggleEnable = function()
    if lyricTimer and lyricTimer:running() then
        delete(c_lyric)
		lyricTimer:stop()
    else
		Lyric.setcanvas()
        Lyric.main()
	end
end

-- 歌词显示开关
Lyric.toggleShow = function()
    if c_lyric then
        if not c_lyric:isShowing() then
            lyricTimer:start()
        else
            hide(c_lyric)
            lyricTimer:stop()
        end
	end
end

-- 标记错误歌词预防加载或重新搜索
Lyric.error = function()
    local lyricFile = lyricPath .. Music.title() ..  " - " .. Music.artist() .. ".lrc"
	local lyricExt = io.open(lyricFile, "r")
	if lyricExt then
		os.rename(lyricFile, lyricPath .. Music.title() ..  " - " .. Music.artist() .. "_ERROR.lrc")
		print("歌詞をエラーとしてマーク")
		Lyric.main()
	end
end

-- 歌词功能菜单
lyricShow = true
lyricEnable = true
lyric163API = true
lyricselfAPI = not lyric163API
Lyric.menubar = function(songs)
	if not LyricBar then
		LyricBar = hs.menubar.new(true):autosaveName("Lyric")
	end
	menudata = {
		{
			title = lyricString.enable,
			checked = lyricEnable,
			fn = function()
				lyricEnable = not lyricEnable
				Lyric.toggleEnable()
				Lyric.menubar()
			end,
		},
		{
			title = lyricString.show,
			checked = lyricShow,
			fn = function()
				lyricShow = not lyricShow
				Lyric.toggleShow()
				Lyric.menubar()
			end,
		},
		{
			title = lyricString.api,
			menu = {
				{
					title = "网易云音乐",
					checked = lyric163API,
					fn = function()
						lyricselfAPI = lyric163API
						lyric163API = not lyric163API
						Lyric.api(lyric163API)
						Lyric.menubar()
					end,
				},
				{
					title = "自建",
					checked = lyricselfAPI,
					fn = function()
						lyric163API = lyricselfAPI
						lyricselfAPI = not lyricselfAPI
						Lyric.api(lyric163API)
						Lyric.menubar()
					end,
				},
			},
		},
		{
			title = lyricString.error,
			fn = Lyric.error,
		},
		{
			title = lyricString.delete,
			fn = function()
				Lyric.delete()
				Lyric.main()
			end
		},
		{ title = "-" }
	}
	if songs then
		table.insert(menudata, { title = lyricString.search, disabled = true })
		for i = 1, #songs, 1 do
			item = { 
				title = songs[i].name .. " - " .. songs[i].artists[1].name, 
				fn = function()
					song = i
					id = songs[i].id
					lyricTable = Lyric.search(keyword,save)
					update = true
					Lyric.show(lyricTable)
				end
			}
			table.insert(menudata, item)
		end
	end
	local icon = hs.image.imageFromPath(hs.configdir .. "/image/lyric.png"):setSize({ w = 20, h = 20 }, true)
	LyricBar:setIcon(icon)
	LyricBar:setMenu(menudata)
end

-- 歌词显示与隐藏快捷键
hotkey.bind(hyper_cs, "l", Lyric.toggleShow)

-- 歌词模块停用与启用快捷键
hotkey.bind(hyper_cos, "l", Lyric.toggleEnable)

-- 歌词错误时标记
hotkey.bind(hyper_coc, "l", Lyric.error)