require ('module.utils') 

Music = {}

-- 缓存机制
Music._cache = {
    data = nil,
    timestamp = 0,
    ttl = 0.5  -- 缓存500ms
}

-- 全局封面缓存
Music._artworkCache = {
    image = nil,
    album = "",
}

-- 清理缓存（在歌曲切换时调用）
Music.clearCache = function()
    Music._cache.data = nil
    Music._cache.timestamp = 0
end

-- 强制刷新缓存
Music.refreshCache = function()
    Music.clearCache()
    return Music.getCachedInfo()
end

-- 清除封面缓存（切歌时调用）
Music.clearArtworkCache = function()
    Music._artworkCache.image = nil
    Music._artworkCache.album = ""
end

-- 调用AppleScript模块
Music.tell = function(cmd)
	local AS = function(cmd)
		local _cmd = 'tell application "Music" to ' .. cmd
		local ok, result = as.applescript(_cmd)
		if ok then
			return result
		else
			return nil
		end
	end
	
	if quit then
		if cmd == "quit" then
			AS(cmd)
		else
			return nil
		end
	elseif not Music.checkRunning() then
		if cmd == "activate" then
			AS(cmd)
		else
			return nil
		end
	end
	return AS(cmd)
end

-- 批量获取音乐信息
Music.getBatchInfo = function()
    if not Music.checkRunning() then
        return nil
    end
    
    local script = [[
        tell application "Music"
            if it is running and (exists current track) then
                try
                    set trackInfo to {}
                    set end of trackInfo to (get name of current track)
                    set end of trackInfo to (get artist of current track)
                    set end of trackInfo to (get album of current track)
                    set end of trackInfo to (get finish of current track)
                    set end of trackInfo to (get player position)
                    set end of trackInfo to (get player state as string)
                    set end of trackInfo to (get favorited of current track)
                    set end of trackInfo to (get rating of current track)
                    set end of trackInfo to (get shuffle enabled)
                    set end of trackInfo to (get song repeat as string)
                    
                    set AppleScript's text item delimiters to "|"
                    set trackInfoString to trackInfo as string
                    set AppleScript's text item delimiters to ""
                    
                    return trackInfoString
                on error
                    return "error"
                end try
            else
                return "no_track"
            end if
        end tell
    ]]
    
    local ok, result = as.applescript(script)
    if ok and result and result ~= "error" and result ~= "no_track" then
        local parts = {}
        for part in result:gmatch("([^|]*)") do
            table.insert(parts, part)
        end
        
        return {
            title = parts[1] or "",
            artist = parts[2] or "",
            album = parts[3] or "",
            duration = tonumber(parts[4]) or 0,
            position = tonumber(parts[5]) or 0,
            state = parts[6] or "stopped",
            loved = parts[7] == "true",
            rating = math.floor((tonumber(parts[8]) or 0) / 20),
            shuffle = parts[9] == "true",
            loop = parts[10] or "off",
			kind = Music.kind(),
			existInLibrary = Music.existInLibrary()
        }
    end
    return nil
end

-- 获取音乐信息缓存
Music.getCachedInfo = function()
    local now = hs.timer.secondsSinceEpoch()
    if Music._cache.data and (now - Music._cache.timestamp) < Music._cache.ttl then
        return Music._cache.data
    end
    
    local info = Music.getBatchInfo()
    if info then
        Music._cache.data = info
        Music._cache.timestamp = now
    end
    return info
end

-- 单独获取某个信息
Music.title = function()
    local info = Music.getCachedInfo()
    return info and info.title or Music.tell('name of current track') or " "
end

Music.artist = function()
    local info = Music.getCachedInfo()
    return info and info.artist or Music.tell('artist of current track') or " "
end

Music.album = function()
    local info = Music.getCachedInfo()
    return info and info.album or Music.tell('album of current track') or " "
end

Music.duration = function()
    local info = Music.getCachedInfo()
    return info and info.duration or Music.tell('finish of current track') or 1
end

Music.currentPosition = function(forceRefresh)
    -- 如果强制刷新或者缓存过期，直接调用 AppleScript
    if forceRefresh then
        return Music.tell('player position') or 0
    end
    
    local info = Music.getCachedInfo()
    return info and info.position or Music.tell('player position') or 0
end

Music.state = function()
    if not Music.checkRunning() then
        return "norunning"
    end
    local info = Music.getCachedInfo()
    return info and info.state or Music.tell('player state as string')
end

Music.loved = function()
    local info = Music.getCachedInfo()
    return info and info.loved or Music.tell('favorited of current track')
end

Music.rating = function()
    local info = Music.getCachedInfo()
    return info and info.rating or (Music.tell('rating of current track') and Music.tell('rating of current track')//20 or 0)
end

Music.shuffle = function()
    local info = Music.getCachedInfo()
    return info and info.shuffle or Music.tell('shuffle enabled')
end

Music.loop = function()
    local info = Music.getCachedInfo()
    return info and info.loop or Music.tell('song repeat as string')
end

Music.disliked = function()
	return Music.tell('disliked of current track')
end

Music.group = function()
	return Music.tell("grouping of current track") or " "
end

Music.genre = function()
	local genre = Music.tell('genre of current track') or " "
	return genre
end

Music.comment = function()
	return Music.tell("comment of current track")
end

-- 判断是否为演唱歌曲
Music.isSong = function()
	isSong = true
	local group = Music.group()
	local genre = Music.genre()
	local kind = Music.kind()
	if group == "オリジナルサウンドトラック" or group == "アレンジ" or group == "ピアノ" or genre == "サウンドトラック" or genre == "クラシック" then
		if Music.comment() ~= "Theme" and not Music.loved() then
			isSong = false
		end
	else
		if Music.comment() == "Soundtrack" then
			isSong = false
		end
	end
	return isSong
end

-- 星级评价
Music.setRating = function(rating)
	Music.tell('set rating of current track to ' .. rating * 20)
end

-- 标记为喜爱
Music.toggleLoved = function()
	as.applescript([[
		tell application "Music"
			if favorited of current track is false then
				set favorited of current track to true
			else
				set favorited of current track to false
			end if
		end tell
	]])
end

-- 标记为不喜欢
Music.toggleDisliked = function()
	as.applescript([[
		tell application "Music"
			if disliked of current track is false then
				set disliked of current track to true
			else
				set disliked of current track to false
			end if
		end tell
	]])
end

-- 切换播放状态
Music.togglePlay = function()
	Music.tell('playpause')
end

Music.play = function()
	Music.tell('play')
end

Music.pause = function()
	Music.tell('pause')
end

Music.stop = function()
	Music.tell('stop')
end

Music.next = function()
	Music.tell('next track')
end

Music.previous = function()
	Music.tell('previous track')
end

-- 歌曲种类
Music.kind = function()
	local kind = Music.tell('kind of container of current track as string')
	local class = Music.tell('class of container of current track as string')
	local cloudstatus = Music.tell('cloud status of current track as string')
	
	if class == "source" then
		if kind == "iTunes Store" then
			musictype = "applemusic"
		elseif kind == "radio tuner" then
			musictype = "radio"
		end
	elseif class == "user playlist" then
		if cloudstatus == "subscription" then
			musictype = "applemusic"
		elseif cloudstatus == "matched" then
			musictype = "matched"
		elseif cloudstatus == "uploaded" then
			musictype = "localmusic"
		end
	else
		musictype = "applemusic"
	end

	return musictype
end

-- 音量调整
Music.volume = function(volumeValue)
	Music.tell('set sound volume to ' .. volumeValue)
end

-- 检测Music是否在运行
Music.checkRunning = function()
	local _,isrunning,_ = as.applescript([[tell application "System Events" to (name of processes) contains "Music"]])
	return isrunning
end

-- 跳转至当前播放的歌曲
Music.locate = function()
	as.applescript([[
		tell application "Music"
			activate
			tell application "System Events" to keystroke "l" using command down
		end tell
	]])
end

-- 切换随机模式
Music.toggleShuffle = function()
	if Music.kind() ~= "radio" then
		if Music.shuffle() == false then
			Music.tell("set shuffle enabled to true")
		else
			Music.tell("set shuffle enabled to false")
		end
	end
end

-- 切换重复模式
Music.toggleLoop = function()
	if Music.kind() ~= "radio" then
		if Music.loop() == "all" then
			Music.tell('set song repeat to one')
		elseif Music.loop() == "one" then
			Music.tell('set song repeat to off')
		elseif Music.loop() == "off" then
			Music.tell('set song repeat to all')
		end
	end
end

-- 判断Apple Music曲目是否存在于本地曲库中
Music.existInLibrary = function()
	local existinlibraryScript = [[
		tell application "Music"
			set a to current track's name
			set b to current track's artist
			exists (some track of playlist "MusicList" whose name is a and artist is b)
		end tell
	]]
	local _,existinlibrary,_ = as.applescript(existinlibraryScript:gsub("MusicList",MusicApp))
	return existinlibrary
end

-- 将Apple Music曲目添加到本地曲库
Music.addToLibrary = function()
	local addtolibraryScript = [[
		tell application "Music"
			try
				duplicate current track to library playlist "Library"
			on error
				duplicate current track to first source
			end try
		end tell
	]]
	if Music.kind() == "applemusic" and Music.kind() == "radio" then
		as.applescript(addtolibraryScript:gsub("Library",MusicLibrary))
	end
end

-- 判断Apple Music曲目是否存在于播放列表中
Music.existInPlaylist = function(playlistname)
	local existinscript = [[
		tell application "Music"
			set trackName to current track's name
			set artistName to current track's artist
			exists (some track of (first user playlist whose smart is false and name is "pname") whose name is trackName and artist is artistName)
		end tell
	]]
	local _,existinplaylist,_ = as.applescript(existinscript:gsub("pname", playlistname))
	return existinplaylist
end

-- 将当前曲目添加到指定播放列表
Music.addToPlaylist = function(playlistname)
	if Music.existinplaylist(playlistname) == false then
		local addscript = [[
			tell application "Music"
				set thePlaylist to first user playlist whose smart is false and name is "pname"
				set trackName to name of current track
				set artistName to artist of current track
				set albumName to album of current track
				set foundTracks to (every track of library playlist 1 whose artist is artistName and name is trackName and album is albumName)
				repeat with theTrack in foundTracks
					duplicate theTrack to thePlaylist
				end repeat
			end tell
		]]
		local addtoplaylistscript = addscript:gsub("pname", playlistname)
		as.applescript(addtoplaylistscript)
	end
end

-- 随机播放指定播放列表中曲目
Music.shufflePlay = function(playlist)
	local _,shuffle,_ = as.applescript([[tell application "Music" to get shuffle enabled]])
	if Music.tell('shuffle enabled') == false then
		Music.tell('set shuffle enabled to true')
	end
	Music.tell('play playlist named ' .. playlist)
end

-- 从 AS 直接获取封面
local function getArtworkFromAS(callback)
	local outPath = hs.configdir .. "/currentartwork.jpg"
	local script = [[
		tell application "Music"
			try
				set d to raw data of artwork 1 of current track
				set f to open for access POSIX file "]] .. outPath .. [[" with write permission
				set eof f to 0
				write d to f
				close access f
				return "ok"
			on error err
				return "fail:" & err
			end try
		end tell
	]]

	local ok, result = as.applescript(script)
	if not ok or result ~= "ok" then
		callback(nil); return
	end

	local image = hs.image.imageFromPath(outPath)
	-- 用完删掉，避免残留
	-- os.remove(outPath)
	callback(image)
end

-- iTunes Search API 封面获取
local function fetchArtworkFromiTunes(title, artist, album, callback)
    local function trySearch(url, matchFn, fallback)
        hs.http.asyncGet(url, nil, function(code, body)
            if code ~= 200 then
                if fallback then fallback() else callback(nil) end
                return
            end
            local ok, data = pcall(hs.json.decode, body)
            if not ok or not data or #(data.results or {}) == 0 then
                if fallback then fallback() else callback(nil) end
                return
            end

            local artUrl = nil
            -- 优先：精确匹配
            for _, r in ipairs(data.results) do
                if matchFn(r) then
                    artUrl = r.artworkUrl100; break
                end
            end
            -- 降级：用第一条
            artUrl = artUrl or data.results[1].artworkUrl100

            if artUrl then
                artUrl = artUrl:gsub("%d+x%d+bb", "1000x1000bb")
                callback(artUrl)
            else
                if fallback then fallback() else callback(nil) end
            end
        end)
    end

    -- 第一次：用 artist+album 搜专辑，精确匹配 artistName
    local q1 = hs.http.encodeForQuery((artist or "") .. " " .. (album or title or ""))
    local url1 = "https://itunes.apple.com/search?term=" .. q1
               .. "&media=music&entity=album&limit=10&country=jp"

    trySearch(url1,
        function(r)
            local artistMatch = artist and r.artistName and r.artistName == artist
            local albumMatch  = album  and r.collectionName and r.collectionName:find(album, 1, true)
            return artistMatch and albumMatch
        end,
        -- 降级：用 title 搜单曲
        function()
            local q2 = hs.http.encodeForQuery((artist or "") .. " " .. (title or ""))
            local url2 = "https://itunes.apple.com/search?term=" .. q2
                       .. "&media=music&entity=song&limit=10&country=jp"
            trySearch(url2,
                function(r)
                    return artist and r.artistName and r.artistName == artist
                end,
                nil  -- 二次降级：直接用 results[1]，已在 trySearch 内处理
            )
        end
    )
end

-- 从 iTunes API 获取封面（内存方式）
local function getArtworkFromAPI(title, artist, album, callback)
    fetchArtworkFromiTunes(title, artist, album, function(artUrl)
        if not artUrl then
            callback(nil)
            return
        end
        hs.http.asyncGet(artUrl, nil, function(code, body)
            if code ~= 200 or not body then
                callback(nil)
                return
            end
            local b64 = hs.base64.encode(body)
            local dataURL = "data:image/jpeg;base64," .. b64
            local image = hs.image.imageFromURL(dataURL)
            callback(image)
        end)
    end)
end

-- 异步获取封面（优先 AS，降级 API）
Music.fetchArtwork = function(callback)
    local cacheKey = (_G.cachedMusicInfo.album or "") .. "|" .. (_G.cachedMusicInfo.title or "")
    
    -- 命中缓存直接返回
    if Music._artworkCache.image and Music._artworkCache.album == cacheKey then
        callback(Music._artworkCache.image)
        return
    end

    -- 先尝试 AS 方式
    getArtworkFromAS(function(image)
        if image then
            Music._artworkCache.image = image
            Music._artworkCache.album = cacheKey
            callback(image)
            return
        end
        
        -- AS 失败，降级用 API
        getArtworkFromAPI(
            _G.cachedMusicInfo.title,
            _G.cachedMusicInfo.artist,
            _G.cachedMusicInfo.album,
            function(image)
                if image then
                    Music._artworkCache.image = image
                    Music._artworkCache.album = cacheKey
                end
                -- 没有封面时返回默认图
                callback(image or img.imageFromPath(hs.configdir .. "/image/NoArtwork.png"))
            end
        )
    end)
end

-- 删除临时歌词
Music.deleteLyric = function()
	if preKind == "applemusic" and preExistinlibrary == false then
		deleteLyrics = [[
			set deleteFile to (path to music folder as text) & "LyricsX:lyricsFile.lrcx"
			tell application "Finder"
				--delete file deleteFile
				try
					do shell script "rm \"" & POSIX path of deleteFile & "\""
				end try
			end tell
		]]
		delay(1, function() as.applescript(deleteLyrics:gsub("lyricsFile",preTitle .. " - " .. preArtist)) end)
	end
end

-- 保存专辑封面至本地（备用）
Music.saveArtworkFromURL = function(storeURL, callback)
    local trackID = storeURL:match("i=(%d+)")
    if not trackID then return end

    local artworkPath = os.getenv("HOME") .. "/.hammerspoon/currentartwork.jpg"
    local apiURL = "https://itunes.apple.com/lookup?id=" .. trackID .. "&entity=song"

    hs.http.asyncGet(apiURL, nil, function(status, body)
        if status ~= 200 then return end
        local json = hs.json.decode(body)
        if not json or not json.results or #json.results == 0 then return end

        local artURL = json.results[1].artworkUrl100
        if not artURL then return end
        artURL = artURL:gsub("100x100bb", "3000x3000bb")

        hs.http.asyncGet(artURL, nil, function(s, imgData)
            if s ~= 200 then return end
            local file = io.open(artworkPath, "wb")
            if file then
                file:write(imgData)
                file:close()
				-- 下载完成后执行
				if callback then callback() end
            end
        end)
    end)
end

-- 保存专辑封面（利用iTunes的API）
Music.saveArtworkByAPI = function(set_artwork_object)
	-- 判断是否为Apple Music
	if Music.kind() ~= "connecting" then --若为本地曲目
		if Music.album() ~= songalbum then
			songalbum = Music.album()
			as.applescript([[
				tell application "Music"
					set theartwork to raw data of current track's artwork 1
					set theformat to format of current track's artwork 1
					if theformat is «class PNG » then
						set ext to ".png"
					else
						set ext to ".jpg"
					end if
				end tell
				set homefolder to  path to home folder as string
				set fileName to (homefolder & ".hammerspoon:" & "currentartwork" & ext)
				set outFile to open for access file fileName with write permission
				set eof outFile to 0
				write theartwork to outFile
				close access outFile
			]])
		end
	elseif Music.kind() == "applemusic"	then -- 若为Apple Music
		if Music.album() ~= " " then
			if Music.album() ~= songalbum then
				songalbum = Music.album()
				keyWord = Music.album()
				needGet = true
			end
		else
			if Music.title() ~= songtitle then
				songtitle = Music.title()
				keyWord = Music.title()
				needGet = true
			end
		end
		if needGet == true then
			artworkurl = nil
			local amurl = "https://itunes.apple.com/search?term=" .. hs.http.encodeForQuery(Music.album()) .. "&country=jp&entity=album&limit=10&output=json"
			--local status,body,headers = hs.http.get(amurl, nil)
			hs.http.asyncGet(amurl, nil, function(status,body,headers)
				if status == 200 then
					local songdata = hs.json.decode(body)
					if songdata.resultCount ~= 0 then
						i = 1
						condition = false
						repeat
							if songdata.results[i].artistName == Music.artist() then
								artworkurl100 = songdata.results[i].artworkUrl100
								artworkurl = artworkurl100:gsub("100x100", "1000x1000")
								artworkfile = img.imageFromURL(artworkurl):setSize({h = 300, w = 300}, absolute == true)
								artworkfile:saveToFile(hs.configdir .. "/currentartwork.jpg")
								condition = true
							end
							i = i + 1
						until(i > songdata.resultCount or condition == true)
						--[[没有精确匹配结果时强行调用第一个结果
						if artworkurl == nil then
							artworkurl100 = songdata.results[1].artworkUrl100
							artworkurl = artworkurl100:gsub("100x100", "1000x1000")
							artworkfile = img.imageFromURL(artworkurl):setSize({h = 300, w = 300}, absolute == true)
							artworkfile:saveToFile(hs.configdir .. "/currentartwork.jpg")
						end
						--]]
					end
				end
				if artworkurl ~= nil then
					artwork = img.imageFromPath(hs.configdir .. "/currentartwork.jpg")
				else
					artwork = img.imageFromPath(hs.configdir .. "/image/AppleMusic.png")
				end
				set_artwork_object(artwork)
			end)
		end
	end
end

Music.getArtworkPath = function()
	if Music.kind() ~= "connecting" then
		-- 获取图片后缀名
		local format = Music.tell('format of artwork 1 of current track as string')
		if format == nil then
			artwork = img.imageFromPath(hs.configdir .. "/image/NoArtwork.png")
		else
			artwork = img.imageFromPath(hs.configdir .. "/currentartwork.jpg"):setSize({h = 300, w = 300}, absolute == true)
		end
	-- 若连接中
	elseif Music.kind() == "connecting"	then
		artwork = img.imageFromPath(hs.configdir .. "/image/AppleMusic.png")
	end
	return artwork
end