--
-- 定义变量 --
--
-- 定义Hammerspoon模块
as = require("hs.osascript")
c = require("hs.canvas")
-- 系统变量
screenframe = hs.screen.mainScreen():fullFrame()
-- 缓存变量初始化
local MusicBar = nil
local songtitle = nil
local songalbum = nil
local songloved = nil
local songdisliked = nil
local songrating = nil
local songalbum = nil
local songkind = nil
local musicstate = nil
-- 可更改的自定义变量
gaptext = "｜" -- 菜单栏标题的间隔字符
fadetime = 0.6 -- 淡入淡出时间
staytime = 2 -- 显示时间
updatetime = 0.5 -- 刷新时间
artworksize = {h = 200, w = 200} -- 专辑封面显示尺寸
border = {x = 10, y = 10} -- 边框尺寸
gap = {x = 10, y = 10} -- 项目之间的间隔
smallsize = 600 -- 默认最小尺寸
textsize = 20 -- 悬浮菜单字体大小
imagesize = {h = 15, w = 15} -- 菜单图标大小
bgColor = {35, 37, 34} -- 背景颜色（RGB）
bgAlpha = 0.96 -- 背景透明度
menubgColor = {35, 37, 34} -- 菜单背景默认颜色（RGB）
menubgAlpha = 0.96 -- 菜单背景透明度
menubgColorS = {127.5, 127.5, 127.5} -- 菜单背景选中颜色（RGB）
menubgAlphaS = 0.8 -- 菜单背景选中透明度
menuTextColor = {255, 255, 255} -- 菜单字体默认颜色（RGB）
menuTextColorS = {0, 120, 255} -- 菜单字体选中颜色（RGB）
menuStrokeColor = {255, 255, 255} -- 菜单边框颜色（RGB）
menuStrokeAlpha = 0.8 -- 菜单边框透明度
progressColor = {186, 187, 187} -- 进度条颜色
progressColorAM = {255, 45, 84} -- 进度条颜色(AM红)
progressAlpha = 0.6 -- 进度条透明度
--{alpha = bgAlpha, red = bgColor[1] / 255, green = bgColor[2] / 255, blue = bgColor[3] / 255}
-- 本地化适配
local owner = hs.host.localizedName()
if string.find(owner,"カミ") then
	NoPlaying = "ミュージック"
	localFile = "AACオーディオファイル"
	connectingFile = "接続中…"
	streamingFile = "インターネットオーディオストリーム"
else
	NoPlaying = "Music"
	localFile = "AAC音频文件"
	connectingFile = "正在连接…"
	streamingFile = "互联网音频流"
end
--
-- Music功能函数集 --
--
local Music = {}
-- 曲目信息
Music.title = function ()
	local _,title,_ = as.applescript([[tell application "Music" to get name of current track]])
	return title
end
Music.artist = function ()
	local _,artist,_ = as.applescript([[tell application "Music" to get artist of current track]])
	return artist
end
Music.album = function ()
	local _,album,_ = as.applescript([[tell application "Music" to get album of current track]])
	return album
end
Music.duration = function()
	local _,duration,_ = as.applescript([[tell application "Music" to get finish of current track]])
	return duration
end
Music.currentposition = function()
	local _,currentposition,_ = as.applescript([[tell application "Music" to get player position]])
	return currentposition
end
Music.loved = function ()
	local _,loved,_ = as.applescript([[tell application "Music" to get loved of current track]])
	return loved
end
Music.disliked = function ()
	local _,disliked,_ = as.applescript([[tell application "Music" to get disliked of current track]])
	return disliked
end
Music.rating = function ()
	local _,rating100,_ = as.applescript([[tell application "Music" to get rating of current track]])
	if rating100 ~= nil then
		rating = rating100/20
	end
	return rating
end
Music.loop = function ()
	local _,loop,_ = as.applescript([[tell application "Music" to get song repeat as string]])
	return loop
end
Music.shuffle = function ()
	local _,shuffle,_ = as.applescript([[tell application "Music" to get shuffle enabled]])
	return shuffle
end
-- 星级评价
Music.setrating = function (rating)
	if rating == 5 then
		as.applescript([[tell application "Music" to set rating of current track to 100]])
	elseif rating == 4 then
		as.applescript([[tell application "Music" to set rating of current track to 80]])
	elseif rating == 3 then
		as.applescript([[tell application "Music" to set rating of current track to 60]])
	elseif rating == 2 then
		as.applescript([[tell application "Music" to set rating of current track to 40]])
	elseif rating == 1 then
		as.applescript([[tell application "Music" to set rating of current track to 20]])
	elseif rating == 0 then
		as.applescript([[tell application "Music" to set rating of current track to 0]])
	end
end
-- 标记为喜爱
Music.toggleloved = function ()
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
Music.toggledisliked = function ()
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
-- 歌曲种类
Music.kind = function()
	local _,kind,_ = as.applescript([[tell application "Music" to get kind of current track]])
	local _,cloudstatus,_ = as.applescript([[tell application "Music" to get cloud status of current track as string]])
	local _,class,_ = as.applescript([[tell application "Music" to get class of current track as string]])
	if kind ~= nil then
		--若为本地曲目
		if (string.find(kind, localFile) and string.find(kind, "Apple Music") == nil) and cloudstatus ~= "matched" then
			musictype = "localmusic"
		-- 若Apple Μsic连接中
		elseif Music.title() == connectingFile or string.find(kind, streamingFile) then
			musictype = "connecting"
		-- 若为Apple Music
		elseif class == "URL track" or string.len(kind) == 0 or string.find(kind, "Apple Music") then
			musictype = "applemusic"
		-- 若为匹配Apple Music的本地歌曲
		elseif cloudstatus == "matched" then
			musictype = "matched"
		end
	end
	return musictype
end
-- 检测播放状态
Music.state = function ()
	local _,state,_ = as.applescript([[tell application "Music" to get player state as string]])
	return state
end
-- 检测Music是否在运行
Music.checkrunning = function()
	local _,isrunning,_ = as.applescript([[tell application "System Events" to (name of processes) contains "Music"]])
	return isrunning
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
Music.toggleshuffle = function ()
	if Music.shuffle() == false then
		as.applescript([[tell application "Music" to set shuffle enabled to true]])
	else
		as.applescript([[tell application "Music" to set shuffle enabled to false]])
	end
end
-- 切换重复模式
Music.toggleloop = function ()
	if Music.loop() == "all" then
		as.applescript([[tell application "Music" to set song repeat to one]])
	elseif Music.loop() == "one" then
		as.applescript([[tell application "Music" to set song repeat to off]])
	elseif Music.loop() == "off" then
		as.applescript([[tell application "Music" to set song repeat to all]])
	end
end
-- 判断Apple Music曲目是否存在于本地曲库中
Music.existinlibrary = function ()
	local _,existinlibrary,_ = as.applescript([[
		tell application "Music"
			set a to current track's name
			set b to current track's artist
			exists (some track of playlist "ミュージック" whose name is a and artist is b)
		end tell
	]])
	return existinlibrary
end
-- 将Apple Music曲目添加到本地曲库
Music.addtolibrary = function()
	if Music.kind() == "applemusic" then
		as.applescript([[
			tell application "Music"
				try
					duplicate current track to source "ライブラリ"
				end try
			end tell
		]])
	end
end
-- 判断Apple Music曲目是否存在于播放列表中
Music.existinplaylist = function (playlistname)
	local existinscript = [[
		tell application "Music"
			set trackName to current track's name
			set artistName to current track's artist
			exists (some track of (first user playlist whose smart is false and name is "pname") whose name is trackName and artist is artistName)
		end tell
	]]
	local existinplaylistscript = existinscript:gsub("pname", playlistname)
	local _,existinplaylist,_ = as.applescript(existinplaylistscript)
	return existinplaylist
end
-- 将当前曲目添加到指定播放列表
Music.addtoplaylist = function(playlistname)
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
Music.shuffleplay = function (playlist)
	local _,shuffle,_ = as.applescript([[tell application "Music" to get shuffle enabled]])
	if shuffle == false then
		as.applescript([[tell application "Music" to set shuffle enabled to true]])
	end
	local playscript = [[tell application "Music" to play playlist named pname]]
	local playlistscript = playscript:gsub("pname", playlist)
	as.applescript(playlistscript)
end
-- 保存专辑封面
Music.saveartwork = function ()
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
end
-- 保存专辑封面（利用iTunes的API）
Music.saveartworkold = function ()
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
		if Music.album() ~= songalbum then
			songalbum = Music.album()
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
								artworkfile = hs.image.imageFromURL(artworkurl):setSize({h = 300, w = 300}, absolute == true)
								artworkfile:saveToFile(hs.configdir .. "/currentartwork.jpg")
								condition = true
							end
							i = i + 1
						until(i > 10 or condition == true)
					end
				end
				if artworkurl ~= nil then
					artwork = hs.image.imageFromPath(hs.configdir .. "/currentartwork.jpg")
				else
					artwork = hs.image.imageFromPath(hs.configdir .. "/image/AppleMusic.png")
				end
				return artwork
				end)
			end
	end
end
-- 获取专辑封面路径
Music.getartworkpath = function()
	-- 若为本地曲目或Apple Music
	if Music.kind() ~= "connecting" then
		-- 获取图片后缀名
		local _,format,_ = as.applescript([[tell application "Music" to get format of artwork 1 of current track as string]])
		if format == nil then
			artwork = hs.image.imageFromPath(hs.configdir .. "/image/NoArtwork.jpg")
		else
			if string.find(format, "PNG") then
				ext = "png"
			else
				ext = "jpg"
			end
			artwork = hs.image.imageFromPath(hs.configdir .. "/currentartwork." .. ext):setSize({h = 300, w = 300}, absolute == true)
		end
	-- 若连接中
	elseif Music.kind() == "connecting"	then
		artwork = hs.image.imageFromPath(hs.configdir .. "/image/AppleMusic.png")
	end
	return artwork
end
--
-- MenuBar函数集 --
--
-- 延迟函数
function delay(gap, func)
	local delaytimer = hs.timer.delayed.new(gap, func)
	delaytimer:start()
end
-- 删除Menubar
function deletemenubar()
	if MusicBar ~= nil then
		MusicBar:delete()
	end
end
-- 创建菜单栏标题
function settitle()
	-- 菜单栏标题长度
	if Music.state() ~= "stopped" then
		c_menubar = c.new({x = 0, y = 0, h = 25, w = 100})
		c_menubar:appendElements(
		{
			id = "title",
			frame = {x = border.x + artworksize.w + gap.x, y = border.y, h = artworksize.h, w = 100},
			type = "text",
			text = Music.title() .. gaptext .. Music.artist(),
			textSize = 14
		}
		)
		titlesize = c_menubar:minimumTextSize(1, c_menubar["title"].text)
		delete(c_menubar)
		c_menubar = nil
	else
		titlesize = { w = 400, h = 25 }
	end
	local maxlen = 400
	if Music.state() == "playing" then
		if Music.title() == connectingFile then
			MusicBar:setTitle('♫ ' .. connectingFile)
		else
			local infolength = string.len(Music.title() .. gaptext .. Music.artist())
			if titlesize.w < maxlen then
				MusicBar:setTitle('♫ ' .. Music.title() .. gaptext .. Music.artist())
			else
				MusicBar:setTitle('♫ ' .. Music.title())
			end
		end
	elseif Music.state() == "paused" then
		local infolength = string.len(Music.title() .. gaptext .. Music.artist())
		if titlesize.w < maxlen then
			MusicBar:setTitle('❙ ❙ ' .. Music.title() .. gaptext .. Music.artist())
		else
			MusicBar:setTitle('❙ ❙ ' .. Music.title())
		end
	elseif Music.state() == "stopped" then
		MusicBar:setTitle('◼ 停止中')
	end
end
--
-- 悬浮菜单函数集
--
-- 设置悬浮主菜单
function setmainmenu()
	barframe = MusicBar:frame()
	delete(c_mainmenu)
	-- 框架尺寸
	c_mainmenu = c.new({x = barframe.x, y = barframe.h + 5, h = artworksize.h + border.y * 2, w = smallsize}):level(c.windowLevels.cursor)
	-- 菜单项目
	c_mainmenu:replaceElements(
		{-- 背景
			id = "background",
			type = "rectangle",
			action = "fill",
			roundedRectRadii = {xRadius = 6, yRadius = 6},
			fillColor = {alpha = bgAlpha, red = bgColor[1] / 255, green = bgColor[2] / 255, blue = bgColor[3] / 255},
			trackMouseEnterExit = true,
			trackMouseUp = true
		}, {-- 专辑封面
			id = "artwork",
			frame = {x = border.x, y = border.y, h = artworksize.h, w = artworksize.w},
			type = "image",
			image = Music.getartworkpath(),
			trackMouseEnterExit = true,
			trackMouseUp = true
		}, 	{-- 专辑信息
			id = "info",
			frame = {x = border.x + artworksize.w + gap.x, y = border.y, h = artworksize.h, w = 100},
			type = "text",
			text = Music.title() .. "\n\n" .. Music.artist()  .. "\n\n" .. Music.album()  .. "\n",
			textSize = textsize,
			textLineBreak = "wordWrap",
			trackMouseEnterExit = true,
			trackMouseUp = true
		}
	)
	-- 设置悬浮菜单宽度(自适应)
	infosize = c_mainmenu:minimumTextSize(3, c_mainmenu["info"].text)
	local defaultsize = infosize.w + artworksize.w + border.x * 2 + gap.x
	if defaultsize < smallsize then
		menuframe = {x = barframe.x, y = barframe.h + 5, h = artworksize.h + 2 * border.y, w = smallsize}
	elseif defaultsize < screenframe.w - barframe.x - 5 then
		menuframe = {x = barframe.x, y = barframe.h + 5, h = artworksize.h + 2 * border.y, w = defaultsize}
	elseif defaultsize > screenframe.w - barframe.x - 5 and defaultsize < screenframe.w -10 then
		menuframe = {x = screenframe.w - 5 - defaultsize, y = barframe.h + 5, h = artworksize.h + 2 * border.y, w = defaultsize}
	elseif defaultsize > screenframe.w - 10 then
		menuframe = {x = screenframe.x + 5, y = barframe.h + 5, h = artworksize.h + 2 * border.y, w = screenframe.w - 10}
	end
	c_mainmenu:frame(menuframe)
	if infosize.w < 100 then
		c_mainmenu["info"].frame.w = textsize * 5
	else
		c_mainmenu["info"].frame.w = infosize.w
	end
	-- 鼠标行为
	c_mainmenu:mouseCallback(function(canvas, event, id, x, y)
		-- x,y为距离整个悬浮菜单边界的坐标
		-- 隐藏悬浮菜单
    	if id == "background" and (x < border.x or x > menuframe.w - border.x or y > menuframe.h - border.y ) then
    		if event == "mouseExit" then
    			hide("all")
        	end
		end
    	-- 跳转至当前曲目
    	if id == "info" and y < infosize.h - gap.y then
    		if event == "mouseUp" then
    			Music.locate()
        		hide("all")
    		end
    	end
       	-- 进度条
    	if id == "background" and (x >= c_progress:frame().x - menuframe.x and x <= c_progress:frame().x - menuframe.x + c_progress:frame().w and y >= c_progress:frame().y - menuframe.y and y <= c_progress:frame().y - menuframe.y + c_progress:frame().h) then
    		if event == "mouseUp" then
    			local mousepoint = hs.mouse.getAbsolutePosition()
    			local currentposition = (mousepoint.x - menuframe.x - border.x) / c_progress:frame().w * Music.duration()
    			c_progress:replaceElements(progressElement):show()
    			local setposition = [[tell application "Music" to set player position to "targetposition"]]
    			as.applescript(setposition:gsub("targetposition", currentposition))
    		end
		end
		-- 点击左上角退出
		if id == "background" and event == "mouseUp" and y < border.y and x < border.x then
			hide("all")
			progressTimer:stop()
			Switch:stop()
			as.applescript([[tell application "Music" to quit]])
			as.applescript([[tell application "LyricsX" to quit]])
			Switch:start()
		end
	end)
end
-- 设置Apple Music悬浮菜单项目
function setapplemusicmenu()
	delete(c_applemusicmenu)
	-- 喜爱
	if Music.loved() == true then
		lovedimage = hs.image.imageFromPath(hs.configdir .. "/image/Loved.png"):setSize(imagesize, absolute == true)
	else
		lovedimage = hs.image.imageFromPath(hs.configdir .. "/image/notLoved.png"):setSize(imagesize, absolute == true)
	end
	-- 生成菜单框架和菜单项目
	if Music.kind() == "applemusic" then
		c_applemusicmenu = c.new({x = menuframe.x + border.x + artworksize.w + gap.x, y = menuframe.y + border.y + infosize.h, h = imagesize.h + gap.y, w = imagesize.w * 3}):level(c_mainmenu:level() + 2)
		c_applemusicmenu:replaceElements(
			 {-- 喜爱
				id = "loved",
				frame = {x = 0, y = 0, h = imagesize.h, w = imagesize.w},
				type = "image",
				image = lovedimage,
				imageScaling = "shrinkToFit",
				imageAlignment = "left",
				trackMouseUp = true
			}
			)
	elseif Music.kind() == "matched" then
		c_applemusicmenu = c.new({x = menuframe.x + border.x + artworksize.w + gap.x, y = menuframe.y + border.y + infosize.h, h = imagesize.h, w = imagesize.w}):level(c_mainmenu:level() + 2)
		c_applemusicmenu:replaceElements(
			 {-- 喜爱
				id = "loved",
				frame = {x = 0, y = 0, h = imagesize.h, w = imagesize.w},
				type = "image",
				image = lovedimage,
				imageScaling = "shrinkToFit",
				imageAlignment = "left",
				trackMouseUp = true
			}
			)
	end
	-- 鼠标行为
	c_applemusicmenu:mouseCallback(function(canvas, event, id, x, y)
		-- x,y为距离整个悬浮菜单边界的坐标
    	-- 喜爱
    	if id == "loved" and (y > c_applemusicmenu["loved"].frame.y and y < c_applemusicmenu["loved"].frame.y + c_applemusicmenu["loved"].frame.h) and event == "mouseUp" then
    		if x > c_applemusicmenu["loved"].frame.x and x < c_applemusicmenu["loved"].frame.x + c_applemusicmenu["loved"].frame.w then
    			Music.toggleloved()
    			setapplemusicmenu()
    			c_applemusicmenu:orderAbove(c_mainmenu)
       			show(c_applemusicmenu)
   			end
    	end
   	end)
end
-- 设置本地音乐悬浮菜单项目
function setlocalmusicmenu()
	delete(c_localmusicmenu)
	-- 星级评价悬浮菜单项目
	if Music.rating() == 5 then
		rateimage = hs.image.imageFromPath(hs.configdir .. "/image/5star.png"):setSize(imagesize, absolute == true)
	elseif Music.rating() == 4 then
		rateimage = hs.image.imageFromPath(hs.configdir .. "/image/4star.png"):setSize(imagesize, absolute == true)
	elseif Music.rating() == 3 then
		rateimage = hs.image.imageFromPath(hs.configdir .. "/image/3star.png"):setSize(imagesize, absolute == true)
	elseif Music.rating() == 2 then
		rateimage = hs.image.imageFromPath(hs.configdir .. "/image/2star.png"):setSize(imagesize, absolute == true)
	elseif Music.rating() == 1 then
		rateimage = hs.image.imageFromPath(hs.configdir .. "/image/1star.png"):setSize(imagesize, absolute == true)
	else
		rateimage = hs.image.imageFromPath(hs.configdir .. "/image/0star.png"):setSize(imagesize, absolute == true)
	end
	-- 生成菜单框架和菜单项目
	if Music.kind() == "localmusic" then
		localmusicmenuframe = {x = menuframe.x + border.x + artworksize.w + gap.x, y = menuframe.y + border.y + infosize.h, h = imagesize.h + gap.y, w = imagesize.w * 5.7}
		rateframe = {x = 0, y = 0, h = imagesize.h, w = imagesize.w * 5.5}
	elseif Music.kind() == "matched" then
		localmusicmenuframe = {x = menuframe.x + border.x + artworksize.w + gap.x + imagesize.w, y = menuframe.y + border.y + infosize.h, h = imagesize.h + gap.y, w = imagesize.w * 6.7}
		rateframe = {x = imagesize.w * 0.2, y = 0, h = imagesize.h, w = imagesize.w * 5.5}
	end
		c_localmusicmenu = c.new(localmusicmenuframe):level(c_mainmenu:level() + 1)
		c_localmusicmenu:replaceElements(
			{
				id = "background",
				type = "rectangle",
				action = "fill",
				fillColor = {alpha = 0, red = 0, green = 0, blue = 0},
				trackMouseUp = true
			}, {
				id = "rate",
				frame = rateframe,
				type = "image",
				image = rateimage,
				imageAlignment = "left",
				trackMouseUp = true
			}
			)
		-- 鼠标行为
		c_localmusicmenu:mouseCallback(function(canvas, event, id, x, y)
			-- x,y为距离整个悬浮菜单边界的坐标
    		if id == "background" and event == "mouseUp" and y > imagesize.h and x > imagesize.w * 0.2 and x <  c_localmusicmenu["rate"].frame.w / 5 * 1 then
    				Music.setrating(0)
    				setlocalmusicmenu()
    				c_localmusicmenu:orderAbove(c_mainmenu)
       				show(c_localmusicmenu)
    		end
    		if id == "rate" and event == "mouseUp" then
    			if  y < imagesize.h then
    				if x > imagesize.w * 0.2 and x <  c_localmusicmenu["rate"].frame.w / 5 * 1 then
    					Music.setrating(1)
    				elseif  x > c_localmusicmenu["rate"].frame.w / 5 * 1 and x < c_localmusicmenu["rate"].frame.w / 5 * 2 then
    					Music.setrating(2)
    				elseif  x > c_localmusicmenu["rate"].frame.w / 5 * 2 and x < c_localmusicmenu["rate"].frame.w / 5 * 3 then
    					Music.setrating(3)
    				elseif  x > c_localmusicmenu["rate"].frame.w / 5 * 3 and x < c_localmusicmenu["rate"].frame.w / 5 * 4 then
    					Music.setrating(4)
    				elseif  x > c_localmusicmenu["rate"].frame.w / 5 * 4 and x < c_localmusicmenu["rate"].frame.w / 5 * 5 then
    					Music.setrating(5)
    				end
    			end
    			setlocalmusicmenu()
    			c_localmusicmenu:orderAbove(c_mainmenu)
       			show(c_localmusicmenu)
   			end
   		end)
end
-- 设置播放控制悬浮菜单项目
function setcontrolmenu()
	delete(c_controlmenu)
	-- 随机菜单项目
	if Music.shuffle() == true then
		shuffleimage = hs.image.imageFromPath(hs.configdir .. "/image/shuffle_on.png"):setSize(imagesize, absolute == true)
	else
		shuffleimage = hs.image.imageFromPath(hs.configdir .. "/image/shuffle_off.png"):setSize(imagesize, absolute == true)
	end
	-- 循环菜单项目
	if Music.loop() == "all" then
		loopimage = hs.image.imageFromPath(hs.configdir .. "/image/loop_all.png"):setSize(imagesize, absolute == true)
	elseif Music.loop() == "one" then
		loopimage = hs.image.imageFromPath(hs.configdir .. "/image/loop_one.png"):setSize(imagesize, absolute == true)
	elseif Music.loop() == "off" then
		loopimage = hs.image.imageFromPath(hs.configdir .. "/image/loop_off.png"):setSize(imagesize, absolute == true)
	end
	-- 添加进曲库
	if Music.kind() == "applemusic" then
		if Music.existinlibrary() == false then
			addedimage = hs.image.imageFromPath(hs.configdir .. "/image/add.png"):setSize(imagesize, absolute == true)
		else
			addedimage = hs.image.imageFromPath(hs.configdir .. "/image/added.png"):setSize(imagesize, absolute == true)
		end
	elseif Music.kind() == "localmusic" or Music.kind() == "matched" then
		addedimage = hs.image.imageFromPath(hs.configdir .. "/image/add.png"):setSize(imagesize, absolute == true)
	end
	-- 生成菜单框架和菜单项目
	c_controlmenu = c.new({x = menuframe.x + border.x + artworksize.w + gap.x, y = menuframe.y + border.y + infosize.h + imagesize.h + gap.y, h = imagesize.h, w = imagesize.w * (1 + 1.5 * 2)}):level(c_mainmenu:level() + 1)
	c_controlmenu:replaceElements(
		 {
			id = "shuffle",
			frame = {x = 0, y = 0, h = imagesize.h, w = imagesize.w},
			type = "image",
			image = shuffleimage,
			imageAlignment = "center",
			trackMouseUp = true
		}, {
			id = "loop",
			frame = {x = imagesize.w * 1.5 , y = 0, h = imagesize.h, w = imagesize.w},
			type = "image",
			image = loopimage,
			imageAlignment = "center",
			trackMouseUp = true
		}, {
			id = "playlist",
			frame = {x = imagesize.w * 1.5 * 2 , y = 0, h = imagesize.h, w = imagesize.w},
			type = "image",
			image = addedimage,
			imageAlignment = "center",
			trackMouseUp = true
		}
	)
	-- 鼠标行为
	c_controlmenu:mouseCallback(function(canvas, event, id, x, y)
		-- x,y为距离整个悬浮菜单边界的坐标
    	if id == "shuffle" and event == "mouseUp" then
    		Music.toggleshuffle()
   		elseif id == "loop" and event == "mouseUp" then
			Music.toggleloop()
		elseif id == "playlist" and event == "mouseUp" then
			if Music.existinlibrary() == false then
				Music.addtolibrary()
				repeat
					delay(1, function() return false end)
				until(Music.existinlibrary() == true)
				setcontrolmenu()
			else
				if c_playlist == nil then
					setplaylistmenu()
					c_playlist:orderAbove(c_mainmenu)
					show(c_playlist)
				elseif c_playlist ~= nil then
					if c_playlist:isShowing() == false then
						setplaylistmenu()
						c_playlist:orderAbove(c_mainmenu)
						show(c_playlist)
					else
						hide(c_playlist)
					end
				end
			end
   		end
   		setcontrolmenu()
    	c_controlmenu:orderAbove(c_mainmenu)
   		show(c_controlmenu)
   	end)
end
-- 播放列表悬浮菜单
function setplaylistmenu()
	delete(c_playlist)
	-- 获取播放列表个数
	_,playlistcount,_ = as.applescript([[
		tell application "Music"
			set allplaylist to (get name of every user playlist whose smart is false and special kind is none)
			get count of allplaylist
		end tell
	]])
	-- 获取播放列表名称
	_,playlistname,_ = as.applescript([[
		tell application "Music"
			get name of every user playlist whose smart is false and special kind is none
		end tell
	]])
	-- 框架尺寸
	controlmenuframe = c_controlmenu:frame()
	playlistframe = {x = controlmenuframe.x + c_controlmenu["playlist"].frame.x + c_controlmenu["playlist"].frame.w / 2, y = controlmenuframe.y + c_controlmenu["playlist"].frame.y + c_controlmenu["playlist"].frame.h / 2, h = textsize * playlistcount, w = smallsize}
	c_playlist = c.new(playlistframe):level(c_mainmenu:level() + 1)
	-- 设置菜单宽度
	local _,test,_ = as.applescript([[
		tell application "Music"
			set allplaylist to (get name of every user playlist whose smart is false and special kind is none)
			set theBackup to AppleScript's text item delimiters
			set AppleScript's text item delimiters to "
			"
			set theString to allplaylist as string
			set AppleScript's text item delimiters to theBackup
			return theString
		end tell
	]])
	c_playlist:appendElements(
		{
			id = "test",
			frame = {x = 0, y = 0, h = textsize, w = 1},
			type = "text",
			text = test,
			textSize = textsize,
			textLineBreak = "wordWrap",
			trackMouseEnterExit = true,
			trackMouseUp = true
		}
	)
	playlistmenusize = c_playlist:minimumTextSize(1, c_playlist["test"].text)
	playlistframe = {x = playlistframe.x, y = playlistframe.y, h = playlistmenusize.h + border.y * playlistcount, w = playlistmenusize.w}
	c_playlist:frame(playlistframe)
	-- 生成菜单框架
	c_playlist:replaceElements(
		{-- 菜单背景
			id = "background",
			action = "fill",
			type = "rectangle",
			roundedRectRadii = {xRadius = 6, yRadius = 6},
			fillColor = {alpha = 0, red = 0, green = 0, blue = 0},
			trackMouseEnterExit = true,
			trackMouseUp = true
		}
	)
	-- 菜单项目
	count = 1
	repeat
		if Music.existinplaylist(playlistname[count]) == false then
			textcolor = {red = menuTextColor[1] / 255, green = menuTextColor[2] / 255, blue = menuTextColor[3] / 255}
		else
			textcolor = {red = menuTextColorS[1] / 255, green = menuTextColorS[2] / 255, blue = menuTextColorS[3] / 255}
		end
		c_playlist:appendElements(
			{-- 菜单项背景
				id = "playlistback" .. count,
				frame = {x = 0, y = playlistframe.h / 3 * (count - 1), h = playlistframe.h / 3, w = playlistframe.w},
				type = "rectangle",
				roundedRectRadii = {xRadius = 6, yRadius = 6},
				fillColor = {alpha = menubgAlpha, red = menubgColor[1] / 255, green = menubgColor[2] / 255, blue = menubgColor[3] / 255},
				strokeColor = {alpha = menuStrokeAlpha, red = menuStrokeColor[1] / 255, green = menuStrokeColor[2] / 255, blue = menuStrokeColor[3] / 255},
				trackMouseEnterExit = true,
				trackMouseUp = true
			}
		)
		c_playlist:appendElements(
			{-- 菜单项
				id = "playlist" .. count,
				frame = {x = border.x, y = border.y * (count - 0.5) + playlistmenusize.h / 3 * (count - 1), h = playlistmenusize.h / 3, w = playlistmenusize.w},
				type = "text",
				text = playlistname[count],
				textSize = textsize,
				textColor = textcolor;
				textLineBreak = "wordWrap",
				trackMouseEnterExit = true,
				trackMouseUp = true
			}
		)
		c_playlist:appendElements(
			{-- 菜单项overlay
				id = "playlistoverlay" .. count,
				frame = {x = 0, y = playlistframe.h / 3 * (count - 1), h = playlistframe.h / 3, w = playlistframe.w},
				type = "rectangle",
				roundedRectRadii = {xRadius = 6, yRadius = 6},
				fillColor = {alpha = 0, red = 0, green = 0, blue = 0},
				strokeColor = {alpha = menuStrokeAlpha, red = menuStrokeColor[1] / 255, green = menuStrokeColor[2] / 255, blue = menuStrokeColor[3] / 255},
				trackMouseEnterExit = true,
				trackMouseUp = true
			}
		)
		count = count + 1
	until count > playlistcount
	-- 鼠标行为
	c_playlist:mouseCallback(function(canvas, event, id, x, y)
		-- x,y为距离整个悬浮菜单边界的坐标
		i = 1
		repeat
			if id == "playlistoverlay" .. i then
				if event == "mouseEnter" then
					c_playlist["playlistback" .. i].fillColor = {alpha = menubgAlphaS, red = menubgColorS[1] / 255, green = menubgColorS[2] / 255, blue = menubgColorS[3] / 255}
				elseif event == "mouseExit" then
					if x > border.x and x < playlistframe.w - border.x and y > border.y and y < playlistframe.h - border.y then
						c_playlist["playlistback" .. i].fillColor = {alpha = menubgAlpha, red = menubgColor[1] / 255, green = menubgColor[2] / 255, blue = menubgColor[3] / 255}
					else
						hide(c_playlist)
					end
				elseif event == "mouseUp" then
					Music.addtoplaylist(playlistname[i])
					hide(c_playlist)
				end
			end
			i = i + 1
		until i > playlistcount
		if id == "background" then
			if event == "mouseExit" then
				hide(c_playlist)
			end
		end
	end)
end
-- 设置进度条悬浮菜单
function setprogresscanvas()
	-- 生成悬浮进度条
	delete(c_progress)
	local per = 60 / 100
	c_progress = c.new({x = menuframe.x + border.x, y = menuframe.y + border.y + artworksize.h + border.y * (1 - per) / 2, h = border.y * per, w = menuframe.w - border.x * 2}):level(c_mainmenu:level() + 0)
	progressElement = {
		id = "progress",
    	type = "rectangle",
    	roundedRectRadii = {xRadius = 2, yRadius = 2},
    	frame = {x = 0, y = 0, h = c_progress:frame().h, w = c_progress:frame().w * Music.currentposition() / Music.duration()},
		fillColor = {alpha = progressAlpha, red = progressColor[1] / 255, green = progressColor[2] / 255, blue = progressColor[3] / 255},
    	trackMouseUp = true
	}
	c_progress:appendElements(progressElement)
	if Music.state() == "playing" then
		progressTimer = hs.timer.doWhile(function()
			return c_progress:isShowing()
			end, 
			function()
				progressElement.frame.w = c_progress:frame().w * Music.currentposition() / Music.duration()
				c_progress:replaceElements(progressElement):show()
		end, updatetime)
		progressTimer:stop()
	else
		c_progress:show()
	end
end
--
-- 悬浮菜单功能函数集
--
-- 隐藏
function hide(canvas)
	if canvas ~= nil and canvas ~= "all" then
		canvas:hide(fadetime)
	elseif canvas == "all" then
		hide(c_applemusicmenu)
		hide(c_localmusicmenu)
		hide(c_controlmenu)
		hide(c_progress)
		hide(c_playlist)
		hide(c_mainmenu)
	end
end
-- 显示
function show(canvas)
	if canvas ~= nil then
		canvas:show(fadetime)
	end
end
-- 删除
function delete(canvas)
	if canvas ~= nil and canvas ~= "all" then
		canvas:delete(fadetime)
	elseif canvas == "all" then
		delete(c_applemusicmenu)
		delete(c_localmusicmenu)
		delete(c_controlmenu)
		delete(c_progress)
		delete(c_playlist)
		delete(c_mainmenu)
	end
end
-- 判断鼠标指针是否处于悬浮菜单内
function mousePosition()
	local mousepoint = hs.mouse.getAbsolutePosition()
	if (
		(mousepoint.x > barframe.x and mousepoint.x < barframe.x + barframe.w and mousepoint.y > barframe.y and mousepoint.y < barframe.y + barframe.h + gap.y)
		or
		(mousepoint.x > menuframe.x and mousepoint.x < menuframe.x + menuframe.w and mousepoint.y > menuframe.y - gap.y and mousepoint.y < menuframe.y + menuframe.h)
			) then
		mp = true
	else
		mp = false
	end
	return mp
end
-- 鼠标点击时的行为
function togglecanvas()
	if Music.state() ~= "stopped" then
		if c_mainmenu == nil then
			setmainmenu()
		end
		if c_mainmenu ~= nil then
			if c_mainmenu:isShowing() == true then
				hide("all")
				if progressTimer then
					progressTimer:stop()
				end
			else
				setmainmenu()
				if Music.kind() == "applemusic" then
					setapplemusicmenu()
					show(c_applemusicmenu)
				elseif Music.kind() == "localmusic" then
					setlocalmusicmenu()
					show(c_localmusicmenu)
				elseif Music.kind() == "matched" then
					setapplemusicmenu()
					show(c_applemusicmenu)
					setlocalmusicmenu()
					show(c_localmusicmenu)
				end
				setprogresscanvas()
				if progressTimer then
					progressTimer:start()
				end
				setcontrolmenu()
				show(c_mainmenu)
				show(c_progress)
				show(c_controlmenu)
				-- 自动隐藏悬浮菜单
				hs.timer.waitUntil(function()
						if c_playlist == nil or (c_playlist ~= nil and c_playlist:isShowing() == false) then
							if c_mainmenu:isShowing() == true and mousePosition() == false then
								return true
							else
								return false
							end
						elseif c_playlist ~= nil and c_playlist:isShowing() == true then
							return false
						end
					end, function()
						delay(staytime, function()
							hide("all")
							if progressTimer then
								progressTimer:stop()
							end
						end)
        		end)
			end
		end
	end
end
-- 更新Menubar
function updatemenubar()
	if Music.state() ~= "stopped"  then
		--若更换了曲目
		if Music.kind() == "connecting" then
			settitle()
			songkind = Music.kind()
		elseif Music.kind() ~= "connecting" and Music.title() ~= songtitle then
			if songkind == "connecting" then
				songtitle = Music.title()
				songloved = Music.loved()
				songrating = Music.rating()
				songkind = Music.kind()
				-- delay(5, function() Music.saveartwork() end)
				hs.timer.waitUntil(function()
					if Music.currentposition() > 1 then
						return true
					else
						return false
					end
				end, Music.saveartwork())	
			else
				songtitle = Music.title()
				songloved = Music.loved()
				songrating = Music.rating()
				Music.saveartwork()
			end
			settitle()
			if c_mainmenu ~= nil and c_mainmenu:isShowing() == true then
				hide("all")
				delay(0.6, togglecanvas)
			end
		end
	end
	-- 若更换了播放状态
	if Music.state() ~= musicstate then
		musicstate = Music.state()
		settitle()
	end
end
-- 创建Menubar
function setmusicbar()
	-- 若Music正在运行
	if Music.checkrunning() == true then
		-- 若首次播放则新建menubar item
		if MusicBar == nil then
			MusicBar = hs.menubar.new()
			MusicBar:setTitle('🎵' .. NoPlaying)
		end
	else -- 若Music没有运行
		deletemenubar()
	end
end
-- 创建菜单栏项目
setmusicbar()
-- 更新菜单标题
function MusicBarUpdate()
	if Music.checkrunning() == true then
		if MusicBar == nil then
			MusicBar = hs.menubar.new()
			MusicBar:setTitle('🎵' .. NoPlaying)
		end
		updatemenubar()
		-- 点击菜单栏时的弹出悬浮菜单
		if MusicBar ~= nil then
			if Music.state() ~= "stopped" then
				MusicBar:setClickCallback(togglecanvas)
			else
				MusicBar:setClickCallback(function ()
					as.applescript([[tell application "Music" to activate]])
				end)
			end
		end
	else
		deletemenubar()
		progressTimer = nil
		MusicBar = nil
	end
end
-- hs.timer.doWhile(function()
-- 			return true
-- 		end, MusicBarUpdate)
Switch = hs.timer.new(1, MusicBarUpdate)
Switch:start()