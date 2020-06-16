local MusicBar = nil
local songtitle = nil
local songalbum = nil
local songloved = nil
local songdisliked = nil
local songrating = nil
local songalbum = nil
local songkind = nil
local musicstate = nil
local owner = hs.host.localizedName()
if owner == "鳳凰院カミのMacBook Pro" then
	NoPlaying = "ミュージック"
else
	NoPlaying = "Music"
end
-- Music功能函数集 --
local Music = {}
-- 曲目信息
Music.title = function ()
	local _,title,_ = hs.osascript.applescript([[tell application "Music" to get name of current track]])
	return title
end
Music.artist = function ()
	local _,artist,_ = hs.osascript.applescript([[tell application "Music" to get artist of current track]])
	return artist
end
Music.album = function ()
	local _,album,_ = hs.osascript.applescript([[tell application "Music" to get album of current track]])
	return album
end
Music.duration = function()
	local _,duration,_ = hs.osascript.applescript([[tell application "Music" to get finish of current track]])
	return duration
end
Music.currentposition = function()
	local _,currentposition,_ = hs.osascript.applescript([[tell application "Music" to get player position]])
	return currentposition
end
Music.loved = function ()
	local _,loved,_ = hs.osascript.applescript([[tell application "Music" to get loved of current track]])
	return loved
end
Music.disliked = function ()
	local _,disliked,_ = hs.osascript.applescript([[tell application "Music" to get disliked of current track]])
	return disliked
end
Music.rating = function ()
	local _,rating100,_ = hs.osascript.applescript([[tell application "Music" to get rating of current track]])
	if rating100 ~= nil then
		rating = rating100/20
	end
	return rating
end
Music.loop = function ()
	local _,loop,_ = hs.osascript.applescript([[tell application "Music" to get song repeat as string]])
	return loop
end
Music.shuffle = function ()
	local _,shuffle,_ = hs.osascript.applescript([[tell application "Music" to get shuffle enabled]])
	return shuffle
end
-- 星级评价
Music.setrating = function (rating)
	if rating == 5 then
		hs.osascript.applescript([[tell application "Music" to set rating of current track to 100]])
	elseif rating == 4 then
		hs.osascript.applescript([[tell application "Music" to set rating of current track to 80]])
	elseif rating == 3 then
		hs.osascript.applescript([[tell application "Music" to set rating of current track to 60]])
	elseif rating == 2 then
		hs.osascript.applescript([[tell application "Music" to set rating of current track to 40]])
	elseif rating == 1 then
		hs.osascript.applescript([[tell application "Music" to set rating of current track to 20]])
	elseif rating == 0 then
		hs.osascript.applescript([[tell application "Music" to set rating of current track to 0]])
	end
end
-- 设置为喜欢
Music.toggleloved = function ()
	hs.osascript.applescript([[
		tell application "Music"
			if loved of current track is false then
				set loved of current track to true
			else
				set loved of current track to false
			end if
		end tell
	]])
end
-- 设置为不喜欢
Music.toggledisliked = function ()
	hs.osascript.applescript([[
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
	local _,kind,_ = hs.osascript.applescript([[tell application "Music" to get kind of current track]])
	local _,cloudstatus,_ = hs.osascript.applescript([[tell application "Music" to get cloud status of current track as string]])
	local _,class,_ = hs.osascript.applescript([[tell application "Music" to get class of current track as string]])
	if kind ~= nil then
		if (string.find(kind, "AAC") and string.find(kind, "Apple Music") == nil) and cloudstatus ~= "matched" then --若为本地曲目
			musictype = "localmusic"
		elseif Music.title() == "接続中…" or kind == "インターネットオーディオストリーム" or string.find(kind, "流") then -- 若Apple Μsic连接中
			musictype = "connecting"
		elseif class == "URL track" or string.len(kind) == 0 or string.find(kind, "Apple Music") then -- 若为Apple Music
			musictype = "applemusic"
		elseif cloudstatus == "matched" then -- 若为匹配Apple Music的本地歌曲
			musictype = "matched"
		end
	end
	return musictype
end
-- 检测播放状态
Music.state = function ()
	local _,state,_ = hs.osascript.applescript([[tell application "Music" to get player state as string]])
	return state
end
-- 检测Music是否在运行
Music.checkrunning = function()
	local _,isrunning,_ = hs.osascript.applescript([[tell application "System Events" to (name of processes) contains "Music"]])
	return isrunning
end
-- 跳转至当前播放的歌曲
Music.locate = function ()
	hs.osascript.applescript([[
		tell application "Music"
			activate
			tell application "System Events" to keystroke "l" using command down
		end tell
				]])
end
-- 切换随机模式
Music.toggleshuffle = function ()
	if Music.shuffle() == false then
		hs.osascript.applescript([[tell application "Music" to set shuffle enabled to true]])
	else
		hs.osascript.applescript([[tell application "Music" to set shuffle enabled to false]])
	end
end
-- 切换重复模式
Music.toggleloop = function ()
	if Music.loop() == "all" then
		hs.osascript.applescript([[tell application "Music" to set song repeat to one]])
	elseif Music.loop() == "one" then
		hs.osascript.applescript([[tell application "Music" to set song repeat to off]])
	elseif Music.loop() == "off" then
		hs.osascript.applescript([[tell application "Music" to set song repeat to all]])
	end
end
-- 随机播放指定播放列表中曲目
Music.shuffleplay = function (playlist)
	local _,shuffle,_ = hs.osascript.applescript([[tell application "Music" to get shuffle enabled]])
	if shuffle == false then
		hs.osascript.applescript([[tell application "Music" to set shuffle enabled to true]])
	end
	local playscript = [[tell application "Music" to play playlist named pname]]
	local playlistscript = playscript:gsub("pname", playlist)
	hs.osascript.applescript(playlistscript)
end
-- 保存专辑封面
Music.saveartwork = function ()
	if Music.album() ~= songalbum then
		songalbum = Music.album()
		hs.osascript.applescript([[
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
-- 保存专辑封面（BackUp）
Music.saveartworkold = function ()
	-- 判断是否为Apple Music
	if Music.kind() ~= "connecting" then --若为本地曲目
		if Music.album() ~= songalbum then
			songalbum = Music.album()
			hs.osascript.applescript([[
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
	if Music.kind() ~= "connecting" then --若为本地曲目或Apple Music
		-- 获取图片后缀名
		local _,format,_ = hs.osascript.applescript([[tell application "Music" to get format of artwork 1 of current track as string]])
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
	elseif Music.kind() == "connecting"	then	-- 若连接中
		artwork = hs.image.imageFromPath(hs.configdir .. "/image/AppleMusic.png")
	end
	return artwork
end
-- MenuBar函数集 --
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
	local gaptext = "｜"	-- 间隔字符
	--菜单栏标题长度
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
		if Music.title() == "接続中…" then
			MusicBar:setTitle('♫ 接続中…')
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
-- 创建桌面悬浮式菜单
c = require("hs.canvas")
fadetime = 0.6 -- 淡入淡出时间
staytime = 2 -- 显示时间
updatetime = 0.5 -- 刷新时间
screenframe = hs.screen.mainScreen():fullFrame()
artworksize = {h = 200, w = 200}
border = {x = 10, y = 10}
gap = {x = 10, y = 10}
smallsize = 600
textsize = 20 -- 悬浮菜单字体大小
imagesize = {h = 15, w = 15} -- 菜单图标大小
-- 设置桌面悬浮主菜单
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
			fillColor = {alpha = 0.8, red = 0, green = 0, blue = 0},
			trackMouseEnterExit = true,
			trackMouseUp = true
		}, {--专辑封面
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
	-- 设置悬浮菜单宽度
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
    			hs.osascript.applescript(setposition:gsub("targetposition", currentposition))
    		end
    	end
	end)
end
-- 设置Apple Music悬浮菜单项目
function setapplemusicmenu()
	delete(c_applemusicmenu)
	-- 喜欢
	if Music.loved() == true then
		lovedimage = hs.image.imageFromPath(hs.configdir .. "/image/Loved.png"):setSize(imagesize, absolute == true)
	else
		lovedimage = hs.image.imageFromPath(hs.configdir .. "/image/notLoved.png"):setSize(imagesize, absolute == true)
	end
	-- 是否添加进曲库
	
	-- 添加到播放列表
	
	-- 生成菜单框架和菜单项目
	if Music.kind() == "applemusic" then
		c_applemusicmenu = c.new({x = menuframe.x + border.x + artworksize.w + gap.x, y = menuframe.y + border.y + infosize.h, h = imagesize.h + gap.y, w = imagesize.w * 3}):level(c_mainmenu:level() + 2)
		c_applemusicmenu:replaceElements(
			 {--喜欢
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
			 {--喜欢
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
    	-- 喜欢
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
-- 设置控制悬浮菜单项目
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
	-- 生成菜单框架和菜单项目
	c_controlmenu = c.new({x = menuframe.x + border.x + artworksize.w + gap.x, y = menuframe.y + border.y + infosize.h + imagesize.h + gap.y, h = imagesize.h, w = imagesize.w * 2.7}):level(c_mainmenu:level() + 1)
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
		}
		)
	-- 鼠标行为
	c_controlmenu:mouseCallback(function(canvas, event, id, x, y)
		-- x,y为距离整个悬浮菜单边界的坐标
    	if id == "shuffle" and event == "mouseUp" then
    		Music.toggleshuffle()
   		elseif id == "loop" and event == "mouseUp" then
    		Music.toggleloop()
   		end
   		setcontrolmenu()
    	c_controlmenu:orderAbove(c_mainmenu)
   		show(c_controlmenu)
   	end)
end
-- 设置进度条悬浮菜单
function setprogresscanvas()
	-- 生成悬浮进度条
	delete(c_progress)
	local per = 60 / 100
	c_progress = c.new({x = menuframe.x + border.x, y = menuframe.y + border.y + artworksize.h + border.y * (1 - per) / 2, h = border.y * per, w = menuframe.w - border.x * 2}):level(c_mainmenu:level() + 1)
	progressElement = {
		id = "progress",
    	type = "rectangle",
    	roundedRectRadii = {xRadius = 2, yRadius = 2},
    	frame = {x = 0, y = 0, h = c_progress:frame().h, w = c_progress:frame().w * Music.currentposition() / Music.duration()},
    	fillColor = {alpha = 0.6, red = 1, green = 0.176, blue = 0.33},
    	trackMouseUp = true
	}
	c_progress:appendElements(progressElement)
	hs.timer.doWhile(function()
			return c_progress:isShowing()
		end, function()
			progressElement.frame.w = c_progress:frame().w * Music.currentposition() / Music.duration()
			c_progress:replaceElements(progressElement):show()
		end, updatetime)
end
-- 功能函数
function hide(canvas)
	if canvas ~= nil and canvas ~= "all" then
		canvas:hide(fadetime)
	elseif canvas == "all" then
		hide(c_applemusicmenu)
		hide(c_localmusicmenu)
		hide(c_controlmenu)
		hide(c_progress)
		hide(c_mainmenu)
	end
end
function show(canvas)
	if canvas ~= nil then
		canvas:show(fadetime)
	end
end
function delete(canvas)
	if canvas ~= nil then
		canvas:delete(fadetime)
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
-- 点击时的行为
function togglecanvas()
	if Music.state() ~= "stopped" then
		if c_mainmenu == nil then
			setmainmenu()
		end
		if c_mainmenu ~= nil then
			if c_mainmenu:isShowing() == true then
				hide("all")
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
				setcontrolmenu()
				show(c_mainmenu)
				show(c_progress)
				show(c_controlmenu)
				-- 自动隐藏悬浮菜单
				hs.timer.waitUntil(function()
						if c_mainmenu:isShowing() == true and mousePosition() == false then
							return true
						else
							return false
						end
					end, function()
						delay(staytime, function() hide("all") end)
        		end)
			end
		end
	end
end
-- 更新Menubar
function updatemenubar()
	if Music.state() ~= "stopped" and Music.checkrunning() == true then
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
				delay(3, function() Music.saveartwork() end)
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
	if Music.checkrunning() == true then -- 若Music正在运行
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
-- 点击菜单栏时的弹出悬浮菜单
if MusicBar ~= nil then
	MusicBar:setClickCallback(togglecanvas)
end
-- 更新菜单标题
function MusicBarUpdate()
	if Music.checkrunning() == true then
		if MusicBar == nil then
			MusicBar = hs.menubar.new()
			MusicBar:setTitle('🎵' .. NoPlaying)
		end
		updatemenubar()
	else
		deletemenubar()
		MusicBar = nil
	end
	if MusicBar ~= nil then
		MusicBar:setClickCallback(togglecanvas)
	end
end
hs.timer.doWhile(function()
			return true
		end, MusicBarUpdate)