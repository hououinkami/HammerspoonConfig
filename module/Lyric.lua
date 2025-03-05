require ('module.utils') 
require ('module.apple-music') 
require ('config.lyric')

Lyric = {}
-- 获取并显示歌词
Lyric.main = function()
	-- 初始化
	hide(c_lyric,0)
	if c_lyric then
		c_lyric["lyric"].text = nil
	end
	deleteTimer(lyricTimer)
    lyricURL = nil
	lineNO = 1
	songsResult = {}
	currentsongsResult = {}
	fileName = Music.title() .. " - " .. Music.artist()
	-- 若没有联网则不搜寻歌词
	local v4,v6 = hs.network.primaryInterfaces()
	if v4 == false and v6 == false then
		print("歌詞の検索ができません、ネットワークの接続を確認してください。")
		return
	end
	-- 判断类型
	if Music.kind() == "matched" or Music.kind() == "localmusic" or Music.existInLibrary() then
		lyricfileExist, lyricfileContent, lyricfileError = Lyric.load(fileName)
		if lyricfileError then
			lyricType = "error"
		elseif lyricOnline then
			lyricType = "online"
		elseif lyricfileExist then
			lyricType = "local"
		else
			lyricType = "search"
		end
	else
		if lyricOnline then
			lyricType = "online"
		else
			lyricType = "search"
		end
	end
	-- 歌词搜索黑名单
	if not Music.isSong() then
		lyricType = "ost"
	end
	-- 执行操作
	if lyricType == "error" then
		print("歌詞をエラーとしてマーク")
	elseif lyricType == "online" then
		lyricTable = lyricOnline
		lyricOnline = nil
		print("歌詞をロードしました")
	elseif lyricType == "local" then
		lyricTable = Lyric.edit(lyricfileContent)
		if not Music.existInLibrary() and not Music.loved() then
			Lyric.delete()
		end
	elseif lyricType == "search" then
		keywordNO = 1
		Lyric.search()
		return
	end
	-- 渲染菜单项
	Lyric.menubar()
	-- 特定条件不显示歌词
	if lyricType == "ost" or lyricType == "error" then
		return
	end
	-- 显示歌词
	Lyric.show(lyricTable)
end

-- 歌词搜索API
Lyric.api = function(default)
	apiList = {
		{
			apiNO = 1,
			apiTag = "QQ",
			apiName = "QQ音乐",
			apiMethod = "POST",
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
			gettrackList = function(musicinfo)		
				if musicinfo["music.search.SearchCgiService"] then
					trackData = musicinfo["music.search.SearchCgiService"].data.body.song
				end
				if trackData then
					trackItem = trackData.list
				end
				local trackList = {}
				for t = 1, #trackItem do
					table.insert(trackList, {
						trackID = trackItem[t].mid,
						trackName = trackItem[t].name,
						trackArtist = trackItem[t].singer[1].name
					})
				end
				return trackList
			end,
			getLyric = function(lyricRaw)
				if lyricRaw then
					return lyricRaw.lyric
				end
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
			gettrackList = function(musicinfo)		
				if musicinfo.result then
					trackData = musicinfo.result
				end
				if trackData then
					trackItem = trackData.songs
				end
				local trackList = {}
				if trackItem then
					for t = 1, #trackItem do
						table.insert(trackList, {
							trackID = trackItem[t].id,
							trackName = trackItem[t].name,
							trackArtist = trackItem[t].artists[1].name
						})
					end
				end
				return trackList
			end,
			getLyric = function(lyricRaw)
				if lyricRaw and lyricRaw.lrc then
					return lyricRaw.lrc.lyric
				end
			end
		}
	}
	-- 根据指定index优先排序
	reOrder(apiList, "apiNO", default)
end

-- 搜索歌词并保存
Lyric.search = function()
	-- 搜索初始化
	if keywordNO == 1 then
		-- 标志是否需要保存歌词文件到本地
		saveFile = Music.existInLibrary() or Music.loved()
		-- 搜索的关键词
		searchKeywords = {Music.title() .. " " .. Music.artist(), Music.title()}
		searchTitle = {Music.title(), Music.title()}
		searchArtist = {Music.artist(), Music.artist()}
		-- 处理特殊格式的歌曲名称
		titleFormated = Music.title()
		local specialStringinTitle = {"%(.*%)", "（.*）$", "「.*」$", "「.*」$", "OP$", "ED$", "feat%..*"}
		for i,v in ipairs(specialStringinTitle) do
			titleFormated = titleFormated:gsub(v,"")
		end
		titleFormated = titleFormated:gsub("(.-)[%s]*$", "%1")-- 去除歌曲名末尾空格
		if titleFormated ~= Music.title() then
			table.insert(searchKeywords, titleFormated .. " " .. Music.artist())
			table.insert(searchTitle, titleFormated)
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
	-- 执行HttpGet函数
	local function performHttpGet(api, musicurl, musicbodies)
		-- 回调函数
		local function httpGetID(musicStatus, musicBody, musicHeader)
			completed = completed + 1
			if musicStatus == 200 then
				local musicinfo = hs.json.decode(musicBody)
				local trackList = apiList[api].gettrackList(musicinfo)
				if not trackList then
					return
				end
				if trackList and #trackList > 0 then
					local trackData = {
						["list"] = trackList,
						["api"] = apiList[api].apiNO,
						["keyword"] = keywordNO
					}
					table.insert(currentsongsResult, trackData)
					table.insert(songsResult, trackData)
				end
				--[[ 
				-- 优先从默认搜索API匹配并获取歌词
				if apiList[api].apiNO == lyricDefaultNO then
					Lyric.fetchLyric(Lyric.matchLyric(trackList, api), api)
				end
				-- 若默认搜索API无结果，直接更改搜索关键词
				Lyric.noLyric()
				]]
				-- 判断是否全部完成
				if completed == #apiList then
					-- 按默认优先的顺序重新排序
					reOrder(currentsongsResult, "api", lyricDefaultNO)
					-- 按默认优先的顺序遍历匹配
					for r = 1, #currentsongsResult do
						Lyric.matchLyric(currentsongsResult[r].list, r)
						if lyricURL then
							Lyric.fetchLyric(lyricURL, r)
							break
						end
					end
					currentsongsResult = {}
					-- 若无匹配结果则更改搜索关键词
					if not lyricURL then
						Lyric.noLyric()
					end
					-- 渲染菜单
					reOrder(songsResult, "api", lyricDefaultNO)
					-- reOrder(songsResult, "keyword", 1)
					Lyric.menubar(songsResult)
				end
			end
		end
		-- 发起请求
		httpRequest(apiList[api].apiMethod, musicurl, apiList[api].musicheaders, musicbodies, httpGetID)
	end
	-- Search函数本体
	-- 搜索提示
	if not isSelected then
		completed = 0
		print(keyword .. " の歌詞を検索中...")
		-- 发起所有请求
		for api = 1, #apiList do
			-- 获取歌曲ID
			if apiList[api].apiMethod == "GET" then
				musicurl = apiList[api].idAPI .. hs.http.encodeForQuery(keyword)
			else
				musicurl = apiList[api].idAPI
				musicbodies = apiList[api].musicbodies:gsub("\"query\":\".*\",\"search_type\"", "\"query\":\"" .. keyword .. "\",\"search_type\"")
			end
			performHttpGet(api, musicurl, musicbodies)
		end
	else
		Lyric.fetchLyric(songlyricURL, songAPI)
		isSelected = false
	end
end

-- 自动匹配歌词函数
Lyric.matchLyric = function(trackList, api)
	if not songID then
		local similarity = 0
		if trackList and #trackList > 0 then
			for i = 1, #trackList, 1 do
				if compareString(trackList[i].trackName, searchTitle[keywordNO]) > titleSimilarity then
					for a = 1, #searchArtist, 1 do
						tempS = compareString(trackList[i].trackArtist, searchArtist[a])
						if tempS == 100 then
							similarity = tempS
							songID = trackList[i].trackID
							break
						else
							if tempS > similarity then
								similarity = tempS
								songID = trackList[i].trackID
							end
						end
					end
				end
				if similarity == 100 then
					break
				end
			end
		end
		-- 判断是否需要重新搜索
		if songID then
			lyricURL = apiList[api].lyricAPI .. songID
			songID = nil
			return lyricURL
		end
	end
end

-- 获取歌词函数
Lyric.fetchLyric = function(lyricURL, api)
	if lyricURL then
		print(apiList[api].apiName .. "から歌詞を取得中...")
		httpGetLyric = function(status,body,headers)
			if status == 200 then
				local lyricRaw = hs.json.decode(body)
				local lyric = apiList[api].getLyric(lyricRaw)
				if not lyric or string.find(lyric,'-1%]') or lyric == ""  or string.find(lyric,'^%[99.*') then
					Lyric.noLyric()
					return
				end
				-- 特殊字符处理
				local lyric = lyric:gsub("%&apos;","'")
				-- 获取在线歌词
				lyricOnline = Lyric.edit(lyric)
				-- 保存歌词文件
				if saveFile then
					Lyric.save(lyric,fileName)
				end
				-- 加载歌词
				Lyric.main()
			end
		end
		httpRequest("GET", lyricURL, apiList[api].lyricheaders, nil, httpGetLyric)
	end
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
Lyric.noLyric = function()
	if not lyricURL then
		if keywordNO < #searchKeywords then
			keywordNO = keywordNO + 1
			Lyric.search()
		else
			-- 重置关键词索引
			keywordNO = 1
			print("該当する歌詞はありません、メニューから選択してください")
		end
	else
		lyricURL = nil
		print("歌詞データはありません、メニューから選択してください")
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
		local currentPosition = Music.currentPosition() - lyricTimeOffset
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
			show(c_lyric,lyricFadetime,true)
			if not lyricTimer then
				Lyric.main()
			end
			lyricTimer:start()
		elseif Music.state() == "paused" then
			hide(c_lyric,lyricFadetime,true)
			lyricTimer:stop()
		else
			delete(c_lyric)
			deleteTimer(lyricTimer)
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
		Lyric.setCanvas()
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
Lyric.setCanvas = function() 
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
Lyric.load = function(fileName)
	-- 文件名有'/'时替换成":"
	fileName = fileName:gsub("/",":")
	lyricfileContent = nil
	lyricfileExist = false
	alllyricFile = getAllFiles(lyricPath)
	-- 格式化正则检索词
	local specialString = {"(", ")", ".", "+", "-", "*", "?", "[", "]", "^", "$"} 
	local _fileName = fileName
	for i,v in ipairs(specialString) do
		_fileName = _fileName:gsub("%" .. v,"%%" .. v)
	end
	_fileName = _fileName:gsub("/",":")
	-- 搜寻本地歌词文件夹
	for _,file in pairs(alllyricFile) do
		-- 不加载错误歌词
		if file:find(_fileName .. "_ERROR.lrc") then
			print("歌詞が曲と合っていません")
			lyricfileError = true
			break
		end
		lyricfileError = false
		-- 加载本地歌词文件
		local lyricFile = lyricPath .. fileName .. ".lrc"
		if file:find(_fileName) then
			-- 以可读写方式打开文件
			local _lrcfile = io.open(lyricFile, "r+")
			-- 读取文件所有内容
			if _lrcfile then
				lyricfileContent = _lrcfile:read("*a")
				lyricfileExist = true
				_lrcfile:close()
				print("歌詞ファイルをロードしました")
			else
				print("歌詞ファイルをロードエラー")
			end
			break
		end
    end
	return lyricfileExist,lyricfileContent,lyricfileError
end

-- 保存歌词至本地文件
Lyric.save = function(lyric,fileName)
	local _savename = string.gsub(fileName,"/",":")
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
		Lyric.setCanvas()
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
Lyric.menubar = function(songs)
	if lyricType == "online" then
		return
	end
	if not lyricBar then
		lyricBar = hs.menubar.new(true):autosaveName("Lyric")
	end
	updateMenu = function(menuTitle, menuChecked)
		for i,v in pairs(menudata) do
			if not v["menu"] then
				if v["title"] == menuTitle then
					v["checked"] = menuChecked
					break
				end
			else
				for i = 1, #v["menu"], 1 do
					local menuItem = v["menu"][i]
					if menuItem["title"] == menuTitle then
						menuItem["checked"] = menuChecked
					else
						menuItem["checked"] = not menuChecked
					end
				end
			end
		end
		lyricBar:setMenu(menudata)
	end
	menudata1 = {
		{
			title = lyricString.enable,
			checked = lyricEnable,
			fn = function()
				lyricEnable = not lyricEnable
				Lyric.toggleEnable()
				updateMenu(lyricString.enable, lyricEnable)
			end,
		},
		{
			title = lyricString.show,
			checked = lyricShow,
			fn = function()
				lyricShow = not lyricShow
				Lyric.toggleShow()
				updateMenu(lyricString.show, lyricShow)
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
							lyricDefaultNO = 1
							Lyric.api(lyricDefaultNO)
							updateMenu("QQ音乐", lyricAPIs.APIQQ)
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
							lyricDefaultNO = 2
							Lyric.api(lyricDefaultNO)
							updateMenu("网易云音乐", lyricAPIs.API163)
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
		},
		{
			title = lyricString.reload,
			fn = function()
				Lyric.main()
			end
		}
	}
	if lyricType == "ost" then
		menudata = menudata1
	elseif not songs or saveFile then
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
	if songs then
		source = 0
		for s = 1, #songs, 1 do 
			trackList = songs[s].list
			if songs[s].api ~= source then
				menudata[#menudata + 1] = { title = "-" }
				source = songs[s].api
				table.insert(menudata, { title = lyricString.search[source], disabled = true })
			end
			for i = 1, #trackList, 1 do
				item = {
					title = trackList[i].trackName .. " - " .. trackList[i].trackArtist, 
					id = trackList[i].trackID,
					url = apiList[songs[s].api].lyricAPI .. trackList[i].trackID,
					api = apiList[songs[s].api].apiNO,
					fn = function(modifier,item)
						isSelected = true
						songID = item.id
						songlyricURL = item.url
						songAPI = item.api
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
	lyricBar:setIcon(icon)
	lyricBar:setMenu(menudata)
end
-- 初始化
Lyric.api(lyricDefaultNO)
lyricShow = true
lyricEnable = true
lyricAPIs = {
	API163 = false,
	APIQQ = false,
}
for i,v in pairs(lyricAPIs) do
	if i:find(apiList[lyricDefaultNO].apiTag) then
		lyricAPIs[i] = true
		break
	end
end
Lyric.menubar()

-- 歌词显示与隐藏快捷键
hotkey.bind(hyper_cs, "l", Lyric.toggleShow)

-- 歌词模块停用与启用快捷键
hotkey.bind(hyper_cos, "l", Lyric.toggleEnable)

-- 歌词错误时标记
hotkey.bind(hyper_coc, "l", Lyric.error)