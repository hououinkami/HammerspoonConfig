require ('module.utils') 
require ('module.apple-music') 
require ('config.lyric')

Lyric = {}

-- 异步获取并显示歌词
Lyric.main = function(callback)
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
	
	-- 异步处理歌词类型判断
	hs.timer.doAfter(0, function()
		Lyric.processLyricType(callback)
	end)
end

-- 异步处理歌词类型
Lyric.processLyricType = function(callback)
	-- 判断类型
	if Music.kind() == "matched" or Music.kind() == "localmusic" or Music.existInLibrary() then
		-- 异步加载本地歌词
		Lyric.loadAsync(fileName, function(lyricfileExist, lyricfileContent, lyricfileError)
			local lyricType
			if lyricfileError then
				lyricType = "error"
			elseif lyricOnline then
				lyricType = "online"
			elseif lyricfileExist then
				lyricType = "local"
			else
				lyricType = "search"
			end
			
			hs.timer.doAfter(0, function()
				Lyric.handleLyricType(lyricType, lyricfileContent, callback)
			end)
		end)
	else
		local lyricType
		if lyricOnline then
			lyricType = "online"
		else
			lyricType = "search"
		end
		hs.timer.doAfter(0, function()
			Lyric.handleLyricType(lyricType, nil, callback)
		end)
	end
end

-- 处理歌词类型结果
Lyric.handleLyricType = function(lyricType, lyricfileContent, callback)
	-- 歌词搜索黑名单
	if not Music.isSong() then
		lyricType = "ost"
	end
	
	-- 设置全局变量
	_G.lyricType = lyricType
	
	-- 异步执行操作
	hs.timer.doAfter(0, function()
		if lyricType == "error" then
			print("歌詞をエラーとしてマーク")
			Lyric.menubar()
			if callback then callback() end
		elseif lyricType == "online" then
			_G.lyricTable = lyricOnline
			lyricOnline = nil
			print("歌詞をロードしました")
			Lyric.finalizeLyricLoading(callback)
		elseif lyricType == "local" then
			-- 异步编辑歌词
			Lyric.editAsync(lyricfileContent, function(processedLyricTable)
				_G.lyricTable = processedLyricTable
				if not Music.existInLibrary() and not Music.loved() then
					Lyric.delete()
				end
				Lyric.finalizeLyricLoading(callback)
			end)
		elseif lyricType == "search" then
			keywordNO = 1
			Lyric.search()
			return
		else
			Lyric.menubar()
			if callback then callback() end
		end
	end)
end

-- 完成歌词加载
Lyric.finalizeLyricLoading = function(callback)
	-- 渲染菜单项
	Lyric.menubar()
	-- 特定条件不显示歌词
	if _G.lyricType == "ost" or _G.lyricType == "error" then
		if callback then callback() end
		return
	end
	-- 显示歌词
	Lyric.show(_G.lyricTable, callback)
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

-- 异步搜索歌词并保存
Lyric.search = function()
	-- 搜索初始化
	if keywordNO == 1 then
		Lyric.initializeSearch()
	end
	
	-- 异步执行遍历搜索
	hs.timer.doAfter(0, function()
		Lyric.performSearch()
	end)
end

-- 初始化搜索参数
Lyric.initializeSearch = function()
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

-- 执行搜索
Lyric.performSearch = function()
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
	
	if not isSelected then
		completed = 0
		print(keyword .. " の歌詞を検索中...")
		-- 异步发起所有请求
		for api = 1, #apiList do
			hs.timer.doAfter(api * 0.1, function() -- 稍微错开请求时间
				Lyric.performHttpGet(api, keyword)
			end)
		end
	else
		Lyric.fetchLyric(songlyricURL, songAPI)
		isSelected = false
	end
end

-- 异步执行HttpGet函数
Lyric.performHttpGet = function(api, keyword)
	-- 获取歌曲ID
	local musicurl, musicbodies
	if apiList[api].apiMethod == "GET" then
		musicurl = apiList[api].idAPI .. hs.http.encodeForQuery(keyword)
	else
		musicurl = apiList[api].idAPI
		musicbodies = apiList[api].musicbodies:gsub("\"query\":\".*\",\"search_type\"", "\"query\":\"" .. keyword .. "\",\"search_type\"")
	end
	
	-- 异步回调函数
	local function httpGetID(musicStatus, musicBody, musicHeader)
		hs.timer.doAfter(0, function() -- 确保在主线程中处理结果
			Lyric.handleSearchResult(musicStatus, musicBody, api)
		end)
	end
	
	-- 发起请求
	httpRequest(apiList[api].apiMethod, musicurl, apiList[api].musicheaders, musicbodies, httpGetID)
end

-- 处理搜索结果
Lyric.handleSearchResult = function(musicStatus, musicBody, api)
	completed = completed + 1
	if musicStatus == 200 then
		local musicinfo = hs.json.decode(musicBody)
		local trackList = apiList[api].gettrackList(musicinfo)
		if not trackList then
			Lyric.checkSearchCompletion()
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
	end
	
	-- 判断是否全部完成
	if completed == #apiList then
		hs.timer.doAfter(0, function()
			Lyric.processSearchResults()
		end)
	end
end

-- 处理搜索完成后的结果
Lyric.processSearchResults = function()
	-- 按默认优先的顺序重新排序
	reOrder(currentsongsResult, "api", lyricDefaultNO)
	-- 按默认优先的顺序遍历匹配
	local foundMatch = false
	for r = 1, #currentsongsResult do
		local matchedURL = Lyric.matchLyric(currentsongsResult[r].list, r)
		if matchedURL then
			lyricURL = matchedURL
			foundMatch = true
			Lyric.fetchLyric(lyricURL, r)
			break
		end
	end
	currentsongsResult = {}
	-- 若无匹配结果则更改搜索关键词
	if not foundMatch then
		Lyric.noLyric()
	end
	-- 异步渲染菜单
	hs.timer.doAfter(0, function()
		reOrder(songsResult, "api", lyricDefaultNO)
		Lyric.menubar(songsResult)
	end)
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

-- 异步获取歌词函数
Lyric.fetchLyric = function(lyricURL, api)
	if lyricURL then
		print(apiList[api].apiName .. "から歌詞を取得中...")
		
		-- 异步回调函数
		local function httpGetLyric(status, body, headers)
			hs.timer.doAfter(0, function() -- 确保在主线程中处理结果
				Lyric.handleLyricResult(status, body, api)
			end)
		end
		
		httpRequest("GET", lyricURL, apiList[api].lyricheaders, nil, httpGetLyric)
	end
end

-- 处理歌词获取结果
Lyric.handleLyricResult = function(status, body, api)
	if status == 200 then
		local lyricRaw = hs.json.decode(body)
		local lyric = apiList[api].getLyric(lyricRaw)
		if not lyric or string.find(lyric,'-1%]') or lyric == ""  or string.find(lyric,'^%[99.*') then
			Lyric.noLyric()
			return
		end
		-- 特殊字符处理
		local lyric = lyric:gsub("%&apos;","'")
		-- 异步编辑歌词
		Lyric.editAsync(lyric, function(processedLyricTable)
			lyricOnline = processedLyricTable
			-- 异步保存歌词文件
			if saveFile then
				Lyric.save(lyric, fileName)
			end
			-- 重新加载歌词
			hs.timer.doAfter(0.1, function()
				Lyric.main()
			end)
		end)
	else
		Lyric.noLyric()
	end
end

-- 将歌词从json转变成table（异步处理）
Lyric.editAsync = function(lyric, callback)
	hs.timer.doAfter(0, function()
		local lyricData = stringSplit(lyric,"\n")
		local allLine = #lyricData
		local lyricTable = {}
		
		if #lyricData > 2 then
			-- 分批异步处理歌词行
			Lyric.processLyricLinesAsync(lyricData, allLine, lyricTable, 1, callback)
		else
			-- 在最后插入空行方便处理
			table.insert(lyricTable, {index = #lyricTable + 1, time = Music.duration(), lyric = ""})
			callback(lyricTable)
		end
	end)
end

-- 异步处理歌词行
Lyric.processLyricLinesAsync = function(lyricData, allLine, lyricTable, startIndex, callback)
	local batchSize = 20 -- 每批处理20行
	local endIndex = math.min(startIndex + batchSize - 1, #lyricData)
	
	for l = startIndex, endIndex do
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
	
	-- 如果还有未处理的行，继续异步处理
	if endIndex < #lyricData then
		hs.timer.doAfter(0.01, function()
			Lyric.processLyricLinesAsync(lyricData, allLine, lyricTable, endIndex + 1, callback)
		end)
	else
		-- 处理完成，继续后续步骤
		hs.timer.doAfter(0, function()
			Lyric.finalizeLyricProcessingAsync(lyricTable, callback)
		end)
	end
end

-- 完成歌词处理
Lyric.finalizeLyricProcessingAsync = function(lyricTable, callback)
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
	
	-- 在最后插入空行方便处理
	table.insert(lyricTable, {index = #lyricTable + 1, time = Music.duration(), lyric = ""})
	
	callback(lyricTable)
end

-- 无歌词时执行的函数（异步处理）
Lyric.noLyric = function()
	hs.timer.doAfter(0, function()
		if not lyricURL then
			if keywordNO < #searchKeywords then
				keywordNO = keywordNO + 1
				Lyric.search()
			else
				-- 重置关键词索引
				keywordNO = 1
				print("該当する歌詞はありません、メニューから選択してください")
				-- 异步渲染菜单
				hs.timer.doAfter(0, function()
					Lyric.menubar(songsResult)
				end)
			end
		else
			lyricURL = nil
			print("歌詞データはありません、メニューから選択してください")
			-- 异步渲染菜单
			hs.timer.doAfter(0, function()
				Lyric.menubar(songsResult)
			end)
		end
	end)
end

-- 异步显示歌词
Lyric.show = function(lyricTable, callback)
	if lyricTable then
		-- 异步初始化歌词图层
		hs.timer.doAfter(0, function()
			Lyric.setCanvasAsync(function()
				-- 异步设定计时器
				hs.timer.doAfter(0.1, function()
					Lyric.setupLyricTimerAsync(lyricTable, callback)
				end)
			end)
		end)
	else
		if callback then callback() end
	end
end

-- 设置歌词计时器
Lyric.setupLyricTimerAsync = function(lyricTable, callback)
	lyricTimer = hs.timer.new(1, function()
		-- 异步显示歌词
		hs.timer.doAfter(0, function()
			Lyric.showLyricStepAsync(lineNO, lyricTable)
		end)
	end):start()
	if callback then callback() end
end

-- 异步歌词显示函数
Lyric.showLyricStepAsync = function(startline, lyricTable)
	if not lyricTable then
		return
	end
	
	-- 歌词定位
	local currentPosition = Music.currentPosition() - lyricTimeOffset
	local currentLyric = ""
	local stayTime = 0
	
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
	
	-- 异步歌词刷新
	if currentLyric ~= lyrictext then
		hs.timer.doAfter(0, function()
			Lyric.updateLyricDisplayAsync(currentLyric, stayTime)
		end)
	else
		-- 设置下次触发时间
		stayTime = stayTime or 0
		local nextTrigger = stayTime + lyricTimeOffset
		if lyricTimer and nextTrigger > 0 then
			lyricTimer:setNextTrigger(nextTrigger)
		end
	end
end

-- 异步更新歌词显示
Lyric.updateLyricDisplayAsync = function(currentLyric, stayTime)
	if lyricTimer and not lyricTimer:running() then
		lyricTimer:start()
	end
	
	-- 异步处理歌词样式
	Lyric.handleLyricAsync(currentLyric, function(styledLyric)
		hs.timer.doAfter(0, function()
			if c_lyric and c_lyric["lyric"] then
				c_lyric["lyric"].text = styledLyric
				lyrictext = currentLyric
				
				-- 设置歌词图层自适应宽度
				if styledLyric then
					lyricSize = c_lyric:minimumTextSize(1, styledLyric)
					c_lyric:frame({x = 0, y = desktopFrame.h + menubarHeight - lyricSize.h, h = lyricSize.h, w = screenFrame.w})
					c_lyric["lyric"].frame.x = (c_lyric:frame().w - lyricSize.w) / 2
					c_lyric["lyric"].frame.y = c_lyric:frame().h - lyricSize.h
					c_lyric["lyric"].frame.h = lyricSize.h
				end
				
				-- 设置下次触发时间
				stayTime = stayTime or 0
				local nextTrigger = stayTime + lyricTimeOffset
				if lyricTimer and nextTrigger > 0 then
					lyricTimer:setNextTrigger(nextTrigger)
				end
			end
		end)
	end)
end

-- 异步将歌词按照中英数分割方便设置不同字体
Lyric.handleLyricAsync = function(lyric, callback)
	if not lyric or #lyric == 0 then
		callback(nil)
		return
	end
	
	hs.timer.doAfter(0, function()
		local lyricObjTable = {}
		local s_list = stringSplit2(lyric)
		
		-- 分批处理样式
		Lyric.processStyleBatchAsync(s_list, lyricObjTable, 1, callback)
	end)
end

-- 异步分批处理样式
Lyric.processStyleBatchAsync = function(s_list, lyricObjTable, startIndex, callback)
	local batchSize = 10 -- 每批处理10个字符
	local endIndex = math.min(startIndex + batchSize - 1, #s_list)
	
	for i = startIndex, endIndex do
		local v = s_list[i]
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
	
	-- 如果还有未处理的字符，继续异步处理
	if endIndex < #s_list then
		hs.timer.doAfter(0.001, function()
			Lyric.processStyleBatchAsync(s_list, lyricObjTable, endIndex + 1, callback)
		end)
	else
		-- 处理完成，合并结果
		hs.timer.doAfter(0, function()
			local lyricObj = nil
			for i,v in ipairs(lyricObjTable) do
				if not lyricObj then
					lyricObj = v
				else
					lyricObj = lyricObj .. v
				end
			end
			callback(lyricObj)
		end)
	end
end

-- 合并歌词对象
Lyric.combineLyricObjects = function(lyricObjTable)
	local lyricObj = nil
	for i,v in ipairs(lyricObjTable) do
		if not lyricObj then
			lyricObj = v
		else
			lyricObj = lyricObj .. v
		end
	end
	
	-- 异步更新显示
	hs.timer.doAfter(0, function()
		if c_lyric and c_lyric["lyric"] then
			c_lyric["lyric"].text = lyricObj
		end
	end)
end

-- 异步建立歌词图层
Lyric.setCanvasAsync = function(callback) 
	hs.timer.doAfter(0, function()
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
		if callback then callback() end
	end)
end

-- 异步加载本地歌词文件
Lyric.loadAsync = function(fileName, callback)
	-- 文件名有'/'时替换成":"
	fileName = fileName:gsub("/",":")
	
	hs.timer.doAfter(0, function()
		local lyricfileContent = nil
		local lyricfileExist = false
		local lyricfileError = false
		local alllyricFile = getAllFiles(lyricPath)
		
		-- 格式化正则检索词
		local specialString = {"(", ")", ".", "+", "-", "*", "?", "[", "]", "^", "$"} 
		local _fileName = fileName
		for i,v in ipairs(specialString) do
			_fileName = _fileName:gsub("%" .. v,"%%" .. v)
		end
		_fileName = _fileName:gsub("/",":")
		
		-- 异步搜寻本地歌词文件夹
		hs.timer.doAfter(0, function()
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
					-- 异步读取文件
					hs.timer.doAfter(0, function()
						local _lrcfile = io.open(lyricFile, "r+")
						if _lrcfile then
							lyricfileContent = _lrcfile:read("*a")
							lyricfileExist = true
							_lrcfile:close()
							print("歌詞ファイルをロードしました")
						else
							print("歌詞ファイルをロードエラー")
						end
						callback(lyricfileExist, lyricfileContent, lyricfileError)
					end)
					return
				end
			end
			callback(lyricfileExist, lyricfileContent, lyricfileError)
		end)
	end)
end

-- 异步处理文件加载
Lyric.processFileLoad = function(fileName)
	local alllyricFile = getAllFiles(lyricPath)
	-- 格式化正则检索词
	local specialString = {"(", ")", ".", "+", "-", "*", "?", "[", "]", "^", "$"} 
	local _fileName = fileName
	for i,v in ipairs(specialString) do
		_fileName = _fileName:gsub("%" .. v,"%%" .. v)
	end
	_fileName = _fileName:gsub("/",":")
	
	-- 异步搜寻本地歌词文件夹
	hs.timer.doAfter(0, function()
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
				-- 异步读取文件
				hs.timer.doAfter(0, function()
					Lyric.readLyricFile(lyricFile)
				end)
				break
			end
		end
	end)
end

-- 异步读取歌词文件
Lyric.readLyricFile = function(lyricFile)
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
end

-- 异步保存歌词至本地文件
Lyric.save = function(lyric, fileName, callback)
	hs.timer.doAfter(0, function()
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
		if callback then callback() end
	end)
end

-- 异步删除当前曲目的本地歌词文件
Lyric.delete = function(callback)
	hs.timer.doAfter(0, function()
		local _deletename = string.gsub(Music.title() ..  " - " .. Music.artist(),"/",":")
		local filepath = lyricPath .. _deletename .. ".lrc"
		os.remove(filepath)
		local filepath_error = lyricPath .. _deletename .. "_ERROR.lrc"
		os.remove(filepath_error)
		print("歌詞ファイルを削除しました")
		if callback then callback() end
	end)
end

-- 异步歌词模块应用开关
Lyric.toggleEnable = function(callback)
	hs.timer.doAfter(0, function()
		if lyricTimer and lyricTimer:running() then
			delete(c_lyric)
			lyricTimer:stop()
		else
			Lyric.setCanvasAsync(function()
				hs.timer.doAfter(0.1, function()
					Lyric.main(callback)
				end)
			end)
		end
	end)
end

-- 异步歌词显示开关
Lyric.toggleshow = function(callback)
	hs.timer.doAfter(0, function()
		if c_lyric then
			if not c_lyric:isShowing() then
				lyricTimer:start()
			else
				hide(c_lyric)
				lyricTimer:stop()
			end
		end
		if callback then callback() end
	end)
end

-- 异步标记错误歌词预防加载或重新搜索
Lyric.error = function(callback)
	hs.timer.doAfter(0, function()
		local lyricFile = lyricPath .. Music.title() ..  " - " .. Music.artist() .. ".lrc"
		local lyricExt = io.open(lyricFile, "r")
		if lyricExt then
			lyricExt:close()
			os.rename(lyricFile, lyricPath .. Music.title() ..  " - " .. Music.artist() .. "_ERROR.lrc")
			print("歌詞をエラーとしてマーク")
			hs.timer.doAfter(0.1, function()
				Lyric.main(callback)
			end)
		else
			if callback then callback() end
		end
	end)
end

-- 异步歌词功能菜单
Lyric.menubar = function(songs, callback)
	hs.timer.doAfter(0, function()
		if _G.lyricType == "online" then
			if callback then callback() end
			return
		end
		if not lyricBar then
			lyricBar = hs.menubar.new(true):autosaveName("Lyric")
		end
		
		-- 异步构建菜单
		hs.timer.doAfter(0, function()
			Lyric.buildMenuAsync(songs, callback)
		end)
	end)
end

-- 构建菜单
Lyric.buildMenuAsync = function(songs, callback)
	local updateMenu = function(menuTitle, menuChecked)
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
	
	local menudata1 = {
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
				Lyric.toggleshow()
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
	
	local menudata2 = {
		{
			title = lyricString.error,
			fn = function()
				Lyric.error()
			end,
		},
		{
			title = lyricString.delete,
			fn = function()
				Lyric.delete(function()
					hs.timer.doAfter(0.5, function()
						Lyric.main()
					end)
				end)
			end
		},
		{
			title = lyricString.reload,
			fn = function()
				Lyric.main()
			end,
		}
	}
	
	local menudata = {}
	if _G.lyricType == "ost" then
		menudata = menudata1
	elseif not songs or saveFile then
		for i,v in ipairs(menudata1) do
			table.insert(menudata, v)
		end
		for i,v in ipairs(menudata2) do
			table.insert(menudata, v)
		end
	else
		for i,v in ipairs(menudata1) do
			table.insert(menudata, v)
		end
		menudata[#menudata + 1] = {
			title = lyricString.error,
			fn = function()
				Lyric.toggleshow()
			end,
		}
		menudata[#menudata + 1] = {
			title = lyricString.reload,
			fn = function()
				Lyric.main()
			end,
		}
	end
	
	if songs then
		local source = 0
		for s = 1, #songs, 1 do 
			local trackList = songs[s].list
			if songs[s].api ~= source then
				menudata[#menudata + 1] = { title = "-" }
				source = songs[s].api
				table.insert(menudata, { title = lyricString.search[source], disabled = true })
			end
			for i = 1, #trackList, 1 do
				local item = {
					title = trackList[i].trackName .. " - " .. trackList[i].trackArtist, 
					id = trackList[i].trackID,
					url = apiList[songs[s].api].lyricAPI .. trackList[i].trackID,
					api = apiList[songs[s].api].apiNO,
					fn = function(modifier,item)
						isSelected = true
						songID = item.id
						songlyricURL = item.url
						songAPI = item.api
						Lyric.search()
						update = true
					end
				}
				table.insert(menudata, item)
			end
		end
	end
	
	local icon = hs.image.imageFromPath(hs.configdir .. "/image/lyric.png"):setSize({ w = 20, h = 20 }, true)
	lyricBar:setIcon(icon)
	lyricBar:setMenu(menudata)
	
	if callback then callback() end
end

-- 异步初始化
hs.timer.doAfter(0, function()
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
end)

-- 歌词显示与隐藏快捷键
hotkey.bind(hyper_cs, "l", function()
	Lyric.toggleshow()
end)

-- 歌词模块停用与启用快捷键
hotkey.bind(hyper_cos, "l", function()
	Lyric.toggleEnable()
end)

-- 歌词错误时标记
hotkey.bind(hyper_coc, "l", function()
	Lyric.error()
end)