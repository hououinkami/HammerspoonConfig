require ('module.utils') 
Music = {}
-- 调用AppleScript模块
Music.tell = function (cmd)
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
-- 曲目信息
Music.title = function ()
	local title = Music.tell('name of current track') or " "
	return title
end
Music.artist = function ()
	local artist = Music.tell('artist of current track') or " "
	return artist
end
Music.album = function ()
	local album = Music.tell('album of current track') or " "
	return album
end
Music.duration = function()
	local duration = Music.tell('finish of current track') or 1
	return duration
end
Music.currentPosition = function()
	local currentPosition = Music.tell('player position') or 0
	return currentPosition
end
Music.loved = function ()
	return Music.tell('loved of current track')
end
Music.disliked = function ()
	return Music.tell('disliked of current track')
end
Music.rating = function ()
	if Music.tell('rating of current track') then
		return Music.tell('rating of current track')//20
	else return 0
	end
end
Music.group = function()
	return Music.tell("grouping of current track") or " "
end
Music.genre = function ()
	local genre = Music.tell('genre of current track') or " "
	return genre
end
Music.comment = function()
	return Music.tell("comment of current track")
end
Music.loop = function ()
	return Music.tell('song repeat as string')
end
Music.shuffle = function ()
	return Music.tell('shuffle enabled')
end
Music.isSong = function()
	isSong = true
	local group = Music.group()
	local genre = Music.genre()
	if group == "オリジナルサウンドトラック" or group == "アレンジ" or group == "ピアノ" or genre == "サウンドトラック" or genre == "クラシック" then
		if Music.comment() ~= "Theme" then
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
Music.setRating = function (rating)
	Music.tell('set rating of current track to ' .. rating * 20)
end
-- 标记为喜爱
Music.toggleLoved = function ()
	as.applescript([[
		tell application "Music"
			if loved of current track is false then
				set loved of current track to true
			else
				set loved of current track to false
			end if
		end tell
	]])
end
-- 标记为不喜欢
Music.toggleDisliked = function ()
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
Music.togglePlay = function ()
	Music.tell('playpause')
end
-- 下一首
Music.next = function ()
	Music.tell('next track')
end
-- 上一首
Music.previous = function ()
	Music.tell('previous track')
end
-- 歌曲种类
Music.kind = function()
	local kind = Music.tell('kind of current track')
	local cloudstatus = Music.tell('cloud status of current track as string')
	local class = Music.tell('class of current track as string')
	if kind ~= nil then
		-- 若为匹配Apple Music的本地歌曲
		if cloudstatus == "matched" then
			musictype = "matched"
		-- 若Apple Μsic连接中
		elseif string.find(Music.title(),connectingFile) or string.find(Music.title(),unknowTitle) or string.find(Music.artist(),genius) or string.find(kind, streamingFile) or string.find(Music.title(),station) then
			musictype = "connecting"
		-- 若为Apple Music
		elseif class == "URL track" or string.len(kind) == 0 or string.find(kind, "Apple Music") then
			musictype = "applemusic"
		--若为本地曲目
		elseif string.find(kind, localFile) then
			musictype = "localmusic"
		end
	end
	return musictype
end
-- 音量调整
Music.volume = function (volumeValue)
	Music.tell('set sound volume to ' .. volumeValue)
end
-- 检测Music是否在运行
Music.checkRunning = function()
	local _,isrunning,_ = as.applescript([[tell application "System Events" to (name of processes) contains "Music"]])
	return isrunning
end
-- 检测播放状态
Music.state = function ()
	if Music.checkRunning() == true then
		return Music.tell('player state as string')
	else
		return "norunning"
	end
end
-- 跳转至当前播放的歌曲
Music.locate = function ()
	as.applescript([[
		tell application "Music"
			activate
			tell application "System Events" to keystroke "l" using command down
		end tell
	]])
end
-- 切换随机模式
Music.toggleShuffle = function ()
	if Music.shuffle() == false then
		Music.tell("set shuffle enabled to true")
	else
		Music.tell("set shuffle enabled to false")
	end
end
-- 切换重复模式
Music.toggleLoop = function ()
	if Music.loop() == "all" then
		Music.tell('set song repeat to one')
	elseif Music.loop() == "one" then
		Music.tell('set song repeat to off')
	elseif Music.loop() == "off" then
		Music.tell('set song repeat to all')
	end
end
-- 判断Apple Music曲目是否存在于本地曲库中
Music.existInLibrary = function ()
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
				duplicate current track to first source
			on error
				duplicate current track to library playlist "Library"
			end try
		end tell
	]]
	if Music.kind() == "applemusic" then
		as.applescript(addtolibraryScript:gsub("Library",MusicLibrary))
	end
end
-- 判断Apple Music曲目是否存在于播放列表中
Music.existInPlaylist = function (playlistname)
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
Music.shufflePlay = function (playlist)
	local _,shuffle,_ = as.applescript([[tell application "Music" to get shuffle enabled]])
	if Music.tell('shuffle enabled') == false then
		Music.tell('set shuffle enabled to true')
	end
	Music.tell('play playlist named ' .. playlist)
end
-- 保存专辑封面
Music.saveArtwork = function ()
	if Music.album() ~= songalbum or Music.album() == "" then
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
end
-- 保存专辑封面（利用iTunes的API）
Music.saveArtworkByAPI = function (set_artwork_object)
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
-- 获取专辑封面路径
Music.getArtworkPath = function()
	if Music.kind() ~= "connecting" then
		-- 获取图片后缀名
		local format = Music.tell('format of artwork 1 of current track as string')
		if format == nil then
			artwork = img.imageFromPath(hs.configdir .. "/image/NoArtwork.png")
		else
			if string.find(format, "PNG") then
				ext = "png"
			else
				ext = "jpg"
			end
			artwork = img.imageFromPath(hs.configdir .. "/currentartwork." .. ext):setSize({h = 300, w = 300}, absolute == true)
		end
	-- 若连接中
	elseif Music.kind() == "connecting"	then
		artwork = img.imageFromPath(hs.configdir .. "/image/AppleMusic.png")
	end
	return artwork
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