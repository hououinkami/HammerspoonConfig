require ('module.base') 
require ('module.apple-music') 
require ('config.lyric')

Lyric = {}
-- 获取并显示歌词
Lyric.main = function()
	if c_lyric then
		c_lyric["lyric"].text = Lyric.handleLyric("")
	end
	hide(c_lyric,0)
	songsResult = {}
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
	if lyricTimer then
		lyricTimer:stop()
	end
	-- 是否存储歌词文件
	filename = Music.title() ..  " - " .. Music.artist()
	-- 搜寻本地歌词文件
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
			Lyric.menubar()
			lyricTable = Lyric.edit(lyricfileContent)
			if not Music.existinlibrary() and not Music.loved() then
				Lyric.delete()
			end
		else
			keywordNO = 1
			Lyric.search()
			return
		end
	end
	-- 显示歌词
	Lyric.show(lyricTable)
end

-- 歌词搜索API选择
Lyric.api = function(api)
	idAPI = nil
	lyricAPI = nil
	apiList = {
		{
			apiNO = 1,
			apiTag = "QQ",
			apiName = "QQ音乐",
			apiMethod = "POST",
			-- idAPI = "https://c.y.qq.com/splcloud/fcgi-bin/smartbox_new.fcg?key=",
			idAPI = "https://u.y.qq.com/cgi-bin/musicu.fcg",
			lyricAPI = "https://c.y.qq.com/lyric/fcgi-bin/fcg_query_lyric_new.fcg?g_tk=5381&format=json&nobase64=1&songmid=",
			musicbodies = hs.json.encode(
				{
					["music.search.SearchCgiService"]={
						["method"]="DoSearchForQQMusicDesktop",
						["module"]="music.search.SearchCgiService",
						["param"]={
							["num_per_page"]=1,
							["page_num"]=1,
							["query"]="KEWORDDECODE",
							["search_type"]=0
						}
					}
				}
			),
			musicheaders = {
				["User-Agent"] = "Mozilla/5.0 (iPhone; CPU iPhone OS 13_1_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 - mmbWebBrowse - ios",
				["Referer"] = "https://c.y.qq.com"
			},
			lyricheaders = {
				["User-Agent"] = "Mozilla/5.0 (iPhone; CPU iPhone OS 13_1_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 - mmbWebBrowse - ios",
				["Referer"] = "https://lyric.music.qq.com"
			},
			gettrackResult = function(musicinfo)
				if apiMethod == "GET" then
					return musicinfo.data.song
				else
					if musicinfo["music.search.SearchCgiService"] then
						return musicinfo["music.search.SearchCgiService"].data.body.song
					end
				end
			end,
			gettrackList = function(trackResult)
				if apiMethod == "GET" then
					return trackResult.itemlist
				else
					return trackResult.list
				end
			end,
			trackID = function(index)
				return trackList[index].mid
			end,
			trackName = function(index)
				return trackList[index].name
			end,
			trackArtist = function(index)
				return trackList[index].singer[1].name
			end,
			getLyric = function(lyricRaw)
				return lyricRaw
			end,
			trackLyric = function(lyricRaw)
				return lyricRaw.lyric
			end
		},
		{
			apiNO = 2,
			apiTag = "163",
			apiName = "网易云音乐",
			apiMethod = "GET",
			idAPI = "https://music.163.com/api/search/pc?limit=10&offset=0&type=1&s=",
			lyricAPI = "https://music.163.com/api/song/lyric?os=pc&lv=-1&kv=-1&tv=-1&id=",
			musicheaders = {
				["User-Agent"] = "Mozilla/5.0 (iPhone; CPU iPhone OS 13_1_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 - mmbWebBrowse - ios",
				["cookie"] = "NMTID=00OImW8FZYRLmd7XU5cuO6K8blcSucAAAGMoACXwQ"
			},
			musicbodies = nil,
			lyricheaders = nil,
			gettrackResult = function(musicinfo)
				return musicinfo.result
			end,
			gettrackList = function(trackResult)
				return trackResult.songs
			end,
			trackID = function(index)
				return trackList[index].id
			end,
			trackName = function(index)
				return trackList[index].name
			end,
			trackArtist = function(index)
				return trackList[index].artists[1].name
			end,
			getLyric = function(lyricRaw)
				return lyricRaw.lrc
			end,
			trackLyric = function(lyricRaw)
				return lyricRaw.lrc.lyric
			end
		}
	}
	for a = 1, #apiList, 1 do
		if api == apiList[a].apiTag then
			apiNO = apiList[a].apiNO
			apiTag = apiList[a].apiTag
			apiName = apiList[a].apiName
			apiMethod = apiList[a].apiMethod
			idAPI = apiList[a].idAPI
			lyricAPI = apiList[a].lyricAPI
			musicheaders = apiList[a].musicheaders
			musicbodies = apiList[a].musicbodies
			lyricheaders = apiList[a].lyricheaders
			gettrackResult = apiList[a].gettrackResult
			gettrackList = apiList[a].gettrackList
			trackID = apiList[a].trackID
			trackName = apiList[a].trackName
			trackArtist = apiList[a].trackArtist
			getLyric = apiList[a].getLyric
			trackLyric = apiList[a].trackLyric
			break
		end
		if api == "Self" then
			Lyric.api("163")
			apiNO = 99
			apiTag = "Self"
			apiName = "自建API"
			apiMethod = "GET"
			if not secret then
				secret = io.open(HOME .. "/.hammerspoon/module/secret.lua", "r")
			end
			if secret then
				require ('module.secret')
				io.close(secret)
				idAPI = lyricAPI .. "search?limit=10&offset=0&type=1&keywords="
				lyricAPI = lyricAPI .. "lyric?id="
				musicheaders = nil
				lyricheaders = nil
			else
				Lyric.api(lyricDefault)
			end
			break
		end
	end
end
Lyric.api(lyricDefault)

-- 搜索歌词并保存
Lyric.search = function()
	if keywordNO == 1 then
		saveFile = Music.existinlibrary() or Music.loved()
		-- 搜索的关键词
		searchKeywords = {Music.title() .. " " .. Music.artist(), Music.title()}
		searchTitle = {Music.title(), Music.title()}
		searchArtist = {Music.artist(), Music.artist()}
		-- 处理特殊格式的歌曲名称
		titleFormated = Music.title()
		local specialStringinTitle = {"%(.*%)$", "（.*）$", "「.*」$", "「.*」$", "OP$", "ED$", "feat%..*"} 
		for i,v in ipairs(specialStringinTitle) do
			titleFormated = titleFormated:gsub(v,"")
		end
		titleFormated = titleFormated:gsub("(.-)[%s]*$", "%1")-- 去除歌曲名末尾空格
		if titleFormated ~= Music.title() then
			table.insert(searchKeywords, titleFormated .. " " .. Music.artist())
			table.insert(searchTitle, titleFormated)
			table.insert(searchKeywords, Music.title())
			table.insert(searchTitle, Music.title())
			table.insert(searchKeywords, titleFormated)
			table.insert(searchTitle, titleFormated)
		end
		-- 处理特殊格式的歌手名称
		local specialStringinArtist = {"%(.+%)$","（.+）$","feat%..*"}
		for i,v in ipairs(specialStringinArtist) do
			if Music.artist():find(v) then
				artistFormated = Music.artist():gsub(v,"")
				table.insert(searchArtist, artistFormated)
				if v:find("%.%+") then
					v2 = v:gsub("%.%+","(.+)")
					table.insert(searchArtist, Music.artist():match(v2))
				end
			end
		end
	end
	-- 执行遍历搜索
	keyword = searchKeywords[keywordNO]
	-- 若歌曲名为英文与数字，则提升匹配阈值
	for i in string.gmatch(searchTitle[keywordNO], "[%z\1-\127\194-\244][\128-\191]*") do
		if not i:find("%w") and not i:find("%p") and not i:find("%s") then
			titleSimilarity = 70
			break
		else
			titleSimilarity = 90
		end
	end
	-- 获取歌曲ID
	if not idAPI then
		Lyric.api(lyricDefault)
	end
	if apiMethod == "GET" then
		musicurl = idAPI .. hs.http.encodeForQuery(keyword)
	else
		musicurl = idAPI
		musicbodies = musicbodies:gsub("\"query\":\".*\",\"search_type\"", "\"query\":\"" .. keyword .. "\",\"search_type\"")
	end
	if not songID then
		print(apiName .. " で " .. keyword .. " の歌詞を検索中...")
	end
	httpGetID = function(musicStatus,musicBody,musicHeader)
		if musicStatus == 200 then
			-- 若无手动选择需要下载的歌词则自动匹配
			if not songID then
				musicinfo = hs.json.decode(musicBody)
				trackResult = gettrackResult(musicinfo)
				trackList = gettrackList(trackResult)
				similarity = 0
				if not trackResult then
					return
				end
				if trackList and #trackList > 0 then
					trackData = {
						["list"] = trackList,
						["api"] = apiNO
					}
					table.insert(songsResult, trackData)
					for i = 1, #trackList, 1 do
						if compareString(trackName(i), searchTitle[keywordNO]) > titleSimilarity then
							for a = 1, #searchArtist, 1 do
								tempS = compareString(trackArtist(i), searchArtist[a])
								if tempS == 100 then
									similarity = tempS
									songID = trackID(i)
									break
								else
									if tempS > similarity then
										similarity = tempS
										songID = trackID(i)
									end
								end
							end
						end
						if similarity == 100 then
							break
						end
					end
				end
			end
			-- 判断是否需要重新搜索
			if songID then
				if isSelected then
					lyricurl = songlyricURL
				else
					lyricurl = lyricAPI .. songID
				end
				songID = nil
			else
				if keywordNO < #searchKeywords then
					keywordNO = keywordNO + 1
					Lyric.search()
				else
					-- 更换搜索引擎之前重置关键词索引
					keywordNO = 1
					Lyric.menubar(songsResult)
					Lyric.nolyric()
				end
				return
			end
		end
		-- 在菜单栏显示每次搜索的候选结果
		if not isSelected then
			Lyric.menubar(songsResult)
		end
		if lyricurl then
			print("歌詞を取得中...")
			httpGetLyric = function(status,body,headers)
				if status == 200 then
					local lyricRaw = hs.json.decode(body)
					if getLyric(lyricRaw) then
						local lyric = trackLyric(lyricRaw)
						if not lyric or string.find(lyric,'-1%]') or lyric == ""  or string.find(lyric,'^%[99.*') then
							Lyric.nolyric()
							if lyricurl then
								return
							end
						else
							if currentAPI and apiNO ~= currentAPI then
								Lyric.api(apiList[currentAPI])
								currentAPI = nil
							end
						end
						-- 特殊字符处理
						local lyric = lyric:gsub("%&apos;","'")
						lyricOnline = Lyric.edit(lyric)
						if saveFile then
							Lyric.save(lyric,filename)
						end
						Lyric.main()
					end
				end
			end
			httpRequest("GET", lyricurl, lyricheaders, nil, httpGetLyric)
		end
	end
	httpRequest(apiMethod, musicurl, musicheaders, musicbodies, httpGetID)
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
				if string.find(lyricData[l],"%][%s]*" .. v) then
					lyricData[l] = lyricData[l]:gsub(v .. ".*", "")
					break
				end
			end
			-- 只处理包含正确时间戳的歌词行
			if string.find(lyricData[l],'%[%d+:%d+') then
				local lyricLine = {}
				line = lyricData[l]:gsub("%[(%d+:)","%1"):gsub("(%d+)%]","%1`")
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
			if tonumber(sec) > 59 then
				sec = 59
			end
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

-- 无歌词时执行的函数
Lyric.nolyric = function()
	print("該当する歌詞はません")
	if songlyricURL then
		songlyricURL = nil
		return
	end
	if not currentAPI then
		currentAPI = apiNO
	end
	if apiNO < #apiList then
		newAPI = apiNO + 1
	else
		newAPI = apiNO - #apiList + 1
	end
	if newAPI == currentAPI then
		Lyric.api(apiList[currentAPI].apiTag)
		currentAPI = nil
	else
		Lyric.api(apiList[newAPI].apiTag)
		Lyric.search()
		return
	end
end

-- 显示歌词
Lyric.show = function(lyricTable)
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
end

-- 将歌词按照中英数分割方便设置不同字体
Lyric.handleLyric = function(lyric)
	local lyricObjTable = {}
	if lyric and #lyric > 0 then
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
			print("歌詞が曲と合っていません")
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
			print("歌詞ファイルをロードしました")
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
	print("歌詞ファイルを削除しました")
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
lyricAPIs = {
	API163 = false,
	APIQQ = false,
	APISelf = false,
}
for i,v in pairs(lyricAPIs) do
	if i:find(lyricDefault) then
		lyricAPIs[i] = true
		break
	end
end
Lyric.menubar = function(songs)
	if not LyricBar then
		LyricBar = hs.menubar.new(true):autosaveName("Lyric")
	end
	menudata1 = {
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
					title = "QQ音乐",
					checked = lyricAPIs.APIQQ,
					fn = function()
						if not lyricAPIs.APIQQ then
							for i,v in pairs(lyricAPIs) do
								lyricAPIs[i] = false
							end
							lyricAPIs.APIQQ = true
							Lyric.api("QQ")
							Lyric.menubar()
							Lyric.search()
						end
					end,
				},
				{
					title = "网易云音乐",
					checked = lyricAPIs.API163,
					fn = function()
						if not lyricAPIs.API163 then
							for i,v in pairs(lyricAPIs) do
								lyricAPIs[i] = false
							end
							lyricAPIs.API163 = true
							Lyric.api("163")
							Lyric.menubar()
							Lyric.search()
						end
					end,
				},
				{
					title = "自部署",
					checked = lyricAPIs.APISelf,
					fn = function()
						if not lyricAPIs.APISelf then
							for i,v in pairs(lyricAPIs) do
								lyricAPIs[i] = false
							end
							lyricAPIs.APISelf = true
							Lyric.api("Self")
							Lyric.menubar()
							Lyric.search()
						end
					end,
				}
			},
		}
	}
	menudata2 = {
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
		}
	}
	if not songs or saveFile then
		for i,v in ipairs(menudata2) do
			menudata = menudata1
			table.insert(menudata, v)
		end
	else
		menudata = menudata1
		menudata[#menudata + 1] = {
			title = lyricString.error,
			fn = Lyric.toggleShow,
		}
	end
	menudata[#menudata + 1] = { title = "-" }
	if songs then
		source = 0
		for s = 1, #songs, 1 do 
			trackList = songs[s].list
			if songs[s].api ~= source then
				source = songs[s].api
				table.insert(menudata, { title = lyricString.search[source], disabled = true })
			end
			for i = 1, #trackList, 1 do
				item = {
					title = apiList[songs[s].api].trackName(i) .. " - " .. apiList[songs[s].api].trackArtist(i), 
					id = apiList[songs[s].api].trackID(i),
					url = apiList[songs[s].api].lyricAPI .. apiList[songs[s].api].trackID(i),
					fn = function(modifier,item)
						isSelected = true
						songID = item.id
						songlyricURL = item.url
						lyricTable = Lyric.search()
						update = true
						Lyric.show(lyricTable)
					end
				}
				table.insert(menudata, item)
			end
		end
	end
	local icon = hs.image.imageFromPath(hs.configdir .. "/image/lyric.png"):setSize({ w = 20, h = 20 }, true)
	LyricBar:setIcon(icon)
	LyricBar:setMenu(menudata)
end
Lyric.menubar()

-- 歌词显示与隐藏快捷键
hotkey.bind(hyper_cs, "l", Lyric.toggleShow)

-- 歌词模块停用与启用快捷键
hotkey.bind(hyper_cos, "l", Lyric.toggleEnable)

-- 歌词错误时标记
hotkey.bind(hyper_coc, "l", Lyric.error)