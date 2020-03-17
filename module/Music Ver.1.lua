local MusicBar = nil
local songtitle = nil
local songalbum = nil
local songloved = nil
local songdisliked = nil
local songrating = nil
local songalbum = nil
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
	if string.find(kind, "AAC") and string.find(kind, "Apple Music") == nil and cloudstatus ~= "matched" then --若为本地曲目
		musictype = "localmusic"
	elseif kind == "インターネットオーディオストリーム" or string.find(kind, "流") then -- 若Apple Μsic连接中
		musictype = "connecting"
	elseif string.len(kind) == 0 or string.find(kind, "Apple Music") then -- 若为Apple Music
		musictype = "applemusic"
	elseif cloudstatus == "matched" then
		musictype = "matched"
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
	-- 判断是否为Apple Music
	local _,kind,_ = hs.osascript.applescript([[tell application "Music" to get kind of current track]])
	if Music.kind() == "localmusic" or Music.kind() == "matched" then --若为本地曲目
		if Music.album() ~= songalbum then
			songalbum = Music.album()
			hs.osascript.applescript([[
				try
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
				end try
			]])
		end
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
	elseif Music.kind() == "applemusic"	 then	-- 若为Apple Music
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
-- 设置桌面悬浮菜单
function setmaincanvas()
	barframe = MusicBar:frame()
	-- 生成桌面悬浮菜单
	delete(c_menu)
	c_menu = c.new({x = barframe.x, y = barframe.h + 5, h = artworksize.h + border.y * 2, w = smallsize}):level(c.windowLevels.cursor)
	c_menu:replaceElements(
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
		image = Music.saveartwork(),
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
	infosize = c_menu:minimumTextSize(3, c_menu["info"].text)
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
	c_menu:frame(menuframe)
	if infosize.w < 100 then
		c_menu["info"].frame.w = textsize * 5
	else
		c_menu["info"].frame.w = infosize.w
	end
	-- 鼠标行为
	c_menu:mouseCallback(function(canvas, event, id, x, y)
		-- x,y为距离整个悬浮菜单边界的坐标
    	if event == "mouseExit" then
    		-- 隐藏悬浮菜单
			if id == "background" and (x < border.x or x > menuframe.w - border.x or y > menuframe.h - border.y ) then
					hide(c_progress)
        			hide(c_menu)
			end
			-- 隐藏喜好菜单
			if id == "artwork" then
        		hide(c_lovedmenu)
    		end
    		-- 隐藏评价菜单
    		if id == "info" then
        		hide(c_ratemenu)
        		hide(c_logomenu)
    		end
    	end
    	if event == "mouseEnter" then
    		-- 显示喜好菜单
    		if id == "artwork" then
    			setlovedcanvas()
    			show(c_lovedmenu)
    		end
    		if id == "info" then
    			setratecanvas()
    			show(c_ratemenu)
    			show(c_logomenu)
    		end
    	end
    	if event == "mouseUp" then
    		-- 点击歌曲信息跳转至Music
    		if id == "info" and y < infosize.h then
       			Music.locate()
        		hide(c_lovedmenu)
        		hide(c_ratemenu)
        		hide(c_progress)
        		hide(c_menu)
    		end
    		-- 喜欢
    		if id == "artwork" and (x < c_lovedmenu["loved"].frame.w + border.x and y > c_menu["artwork"].frame.h - c_lovedmenu["loved"].frame.h + border.y) then
    			Music.toggleloved()
    			setlovedcanvas()
    			c_lovedmenu:orderAbove(c_menu)
       			show(c_lovedmenu)
    		end
    		-- 不喜欢
    		if id == "artwork" and (x > c_lovedmenu["loved"].frame.w + border.x and y > c_menu["artwork"].frame.h - c_lovedmenu["loved"].frame.h + border.y) then
    			Music.toggledisliked()
    			setlovedcanvas()
    			c_lovedmenu:orderAbove(c_menu)
    			show(c_lovedmenu)
    		end
    		-- 评价
    		if id == "info" and (x > c_menu["info"].frame.x and x < c_menu["info"].frame.x + c_ratemenu:frame().w and y > infosize.h and y < infosize.h + c_ratemenu:frame().h + border.y) then
				if x > c_menu["info"].frame.x and x < c_menu["info"].frame.x + c_ratemenu:frame().w / 5 *1 then
    				Music.setrating(1)
    			elseif x > c_menu["info"].frame.x + c_ratemenu:frame().w / 5 *1 and x < c_menu["info"].frame.x + c_ratemenu:frame().w / 5 *2 then
    				Music.setrating(2)
    			elseif x > c_menu["info"].frame.x + c_ratemenu:frame().w / 5 *2 and x < c_menu["info"].frame.x + c_ratemenu:frame().w / 5 *3 then
    				Music.setrating(3)
    			elseif x > c_menu["info"].frame.x + c_ratemenu:frame().w / 5 *3 and x < c_menu["info"].frame.x + c_ratemenu:frame().w / 5 *4 then
    				Music.setrating(4)
    			elseif x > c_menu["info"].frame.x + c_ratemenu:frame().w / 5 *4 and x < c_menu["info"].frame.x + c_ratemenu:frame().w / 5 *5 then
    				Music.setrating(5)
    			end
    			setratecanvas()
    			c_ratemenu:orderAbove(c_menu)
    			show(c_ratemenu)
    			show(c_logomenu)
       		end
       		if id == "info" and (x > c_menu["info"].frame.x and x < c_menu["info"].frame.x + c_ratemenu:frame().w / 5 *1 and y > infosize.h + c_ratemenu:frame().h + border.y and y < infosize.h + c_ratemenu:frame().h + border.y + 10) then
				Music.setrating(0)
    			setratecanvas()
    			c_ratemenu:orderAbove(c_menu)
    			show(c_ratemenu)
    		end
    		-- 进度条
    		if id == "background" and (x >= c_progress:frame().x - menuframe.x and x <= c_progress:frame().x - menuframe.x + c_progress:frame().w and y >= c_progress:frame().y - menuframe.y and y <= c_progress:frame().y - menuframe.y + c_progress:frame().h) then
    			local mousepoint = hs.mouse.getAbsolutePosition()
    			local currentposition = (mousepoint.x - menuframe.x - border.x) / c_progress:frame().w * Music.duration()
    			c_progress:replaceElements(progressElement):show()
    			local setposition = [[tell application "Music" to set player position to "targetposition"]]
    			hs.osascript.applescript(setposition:gsub("targetposition", currentposition))
    		end
    	end
	end)
end
-- 设置悬浮菜单项目
function setlovedcanvas()
	delete(c_lovedmenu)
	-- 生成喜欢悬浮菜单
	local imagesize = {h = 25, w = 25}
	-- 菜单内容
	if Music.loved() == true then
		lovedbgcolor = {alpha = 0.8, red = 1, green = 0.176, blue = 0.33}
		lovedimage = hs.image.imageFromPath(hs.configdir .. "/image/loved.png"):setSize(imagesize, absolute == true)
	else
		lovedbgcolor = {alpha = 0.8, red = 1, green = 1, blue = 1}
		lovedimage = hs.image.imageFromPath(hs.configdir .. "/image/notloved.png"):setSize(imagesize, absolute == true)
	end
	if Music.disliked() == true then
		dislikedbgcolor = {alpha = 0.8, red = 1, green = 0.176, blue = 0.33}
		dislikedimage = hs.image.imageFromPath(hs.configdir .. "/image/disliked.png"):setSize(imagesize, absolute == true)
	else
		dislikedbgcolor = {alpha = 0.8, red = 1, green = 1, blue = 1}
		dislikedimage = hs.image.imageFromPath(hs.configdir .. "/image/notdisliked.png"):setSize(imagesize, absolute == true)
	end
	-- 生成菜单
	c_lovedmenu = c.new({x = menuframe.x + border.x, y = menuframe.y + border.y + artworksize.h * 4 / 5, h = artworksize.h / 5, w = artworksize.w}):level(c_menu:level() + 1)
	c_lovedmenu:replaceElements(
			{
				id = "loved",
    			type = "rectangle",
    			roundedRectRadii = {xRadius = 6, yRadius = 6},
    			frame = {x = 0, y = 0, h = artworksize.h / 5, w = artworksize.w / 2},
    			fillColor = lovedbgcolor,
    			trackMouseUp = true
			}, {
				id = "disliked",
    			type = "rectangle",
    			roundedRectRadii = {xRadius = 6, yRadius = 6},
    			frame = {x = artworksize.w / 2, y = 0, h = artworksize.h / 5, w = artworksize.w / 2},
    			fillColor = dislikedbgcolor,
    			trackMouseUp = true
			},	{
				id = "lovedimage",
				frame = {x = 0, y = 0, h = artworksize.h / 5, w = artworksize.w / 2},
				type = "image",
				image = lovedimage,
				imageScaling = "shrinkToFit",
				trackMouseUp = true
			},	{
				id = "dislikedimage",
				frame = {x = artworksize.w / 2, y = 0, h = artworksize.h / 5, w = artworksize.w / 2},
				type = "image",
				image = dislikedimage,
				imageScaling = "shrinkToFit",
				trackMouseUp = true
			}
			)
end
function setratecanvas()
	delete(c_ratemenu)
	delete(c_logomenu)
	-- 生成评价悬浮菜单
	local ratingcolor = {alpha = 1.0, red = 1, green = 0.176, blue = 0.33}
	if Music.rating() == 5 then
		rating = "⭑⭑⭑⭑⭑"
	elseif Music.rating() == 4 then
		rating = "⭑⭑⭑⭑⭐︎"
	elseif Music.rating() == 3 then
		rating = "⭑⭑⭑⭐︎⭐︎"
	elseif Music.rating() == 2 then
		rating = "⭑⭑⭐︎⭐︎⭐︎"
	elseif Music.rating() == 1 then
		rating = "⭑⭐︎⭐︎⭐︎⭐︎"
	else
		rating = "⭐︎⭐︎⭐︎⭐︎⭐︎"
	end
	rate = {
		id = "rate",
		frame = {x = 0, y = 0, h = artworksize.h / 5, w = c_menu["info"].frame.w},
		type = "text",
		text = rating,
		textSize = textsize + 5,
		textColor = ratingcolor,
		trackMouseUp = true
	}
	-- 生成菜单
	if Music.kind() == "localmusic" then -- 若为本地音乐
		c_ratemenu = c.new({x = menuframe.x + border.x + artworksize.w + gap.x, y = menuframe.y + border.y + infosize.h, h = artworksize.h / 5, w = c_menu["info"].frame.w}):level(c_menu:level() + 1)
		c_ratemenu:replaceElements(rate)
		local ratemenuframe = c_ratemenu:minimumTextSize(1, c_ratemenu["rate"].text)
		c_ratemenu:frame({x = menuframe.x + border.x + artworksize.w + gap.x, y = menuframe.y + border.y + infosize.h, h = ratemenuframe.h, w = ratemenuframe.w})
	elseif Music.kind() == "matched" then -- 若为已匹配歌曲
		-- 星级评价菜单
		c_ratemenu = c.new({x = menuframe.x + border.x + artworksize.w + gap.x, y = menuframe.y + border.y + infosize.h, h = artworksize.h / 5, w = c_menu["info"].frame.w}):level(c_menu:level() + 1)
		c_ratemenu:replaceElements(rate)
		local ratemenuframe = c_ratemenu:minimumTextSize(1, c_ratemenu["rate"].text)
		c_ratemenu:frame({x = menuframe.x + border.x + artworksize.w + gap.x, y = menuframe.y + border.y + infosize.h, h = ratemenuframe.h, w = ratemenuframe.w})
		-- Apple Music Logo
		c_logomenu = c.new({x = menuframe.x + border.x + artworksize.w + gap.x + ratemenuframe.w + gap.x, y = menuframe.y + border.y + infosize.h, h = artworksize.h / 5, w = c_menu["info"].frame.w}):level(c_menu:level() + 1)
		applemusicmark = {
			id = "applemusic",
			frame = {x = 0, y = 1, h = ratemenuframe.h, w = ratemenuframe.w},
			type = "image",
			image = hs.image.imageFromPath(hs.configdir .. "/image/AppleMusicLogo.png"):setSize({h = ratemenuframe.h / 2, w = ratemenuframe.w}, absolute == true),
			imageScaling = "shrinkToFit",
			imageAlignment = "left"
		}
		c_logomenu:appendElements(applemusicmark)
	elseif Music.kind() == "applemusic" then -- 若为Apple Music
		c_ratemenu = c.new({x = menuframe.x + border.x + artworksize.w + gap.x, y = menuframe.y + border.y + infosize.h, h = artworksize.h / 5, w = c_menu["info"].frame.w}):level(c_menu:level() + 1)
		c_ratemenu:replaceElements(rate)
		local ratemenuframe = c_ratemenu:minimumTextSize(1, c_ratemenu["rate"].text)
		applemusicmark = {
			id = "applemusic",
			frame = {x = 0, y = 0, h = ratemenuframe.h, w = ratemenuframe.w},
			type = "image",
			image = hs.image.imageFromPath(hs.configdir .. "/image/AppleMusicLogo.png"):setSize({h = ratemenuframe.h / 2, w = ratemenuframe.w}, absolute == true),
			imageScaling = "shrinkToFit",
			imageAlignment = "left"
		}
		c_ratemenu:replaceElements(applemusicmark)
	end
end
function setprogresscanvas()
	-- 生成悬浮进度条
	delete(c_progress)
	local per = 60 / 100
	c_progress = c.new({x = menuframe.x + border.x, y = menuframe.y + border.y + artworksize.h + border.y * (1 - per) / 2, h = border.y * per, w = menuframe.w - border.x * 2}):level(c_menu:level() + 1)
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
	if canvas ~= nil then
		canvas:hide(fadetime)
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
		if c_menu == nil then
			setmaincanvas()
		end
		if c_menu ~= nil then
			if c_menu:isShowing() == true then
				hide(c_progress)
				hide(c_menu)
			else
				setmaincanvas()
				setprogresscanvas()
				show(c_menu)
				show(c_progress)
				-- 自动隐藏悬浮菜单
				hs.timer.waitUntil(function()
						if c_menu:isShowing() == true and mousePosition() == false then
							return true
						else
							return false
						end
					end, function()
						delay(staytime, function()
        					hide(c_lovedmenu)
        					hide(c_ratemenu)
        					hide(c_progress)
        					hide(c_menu)
        				end)
        			end)
			end
		end
	end
end
-- 更新Menubar
function updatemenubar()
	if Music.state() ~= "stopped" and Music.checkrunning() == true then
		if Music.title() ~= songtitle or Music.loved() ~= songloved or Music.disliked() ~= songdisliked or Music.rating() ~= songrating then --若更换了曲目
			songtitle = Music.title()
			songloved = Music.loved()
			songdisliked = Music.disliked()
			songrating = Music.rating()
			Music.saveartwork()
		end
	end
	settitle()
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