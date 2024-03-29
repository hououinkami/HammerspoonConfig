require ('module.base') 
require ('module.apple-music') 
require ('module.Lyric') 
require ('config.music')
--
-- MenuBar函数集 --
--
-- 创建菜单栏标题
function settitle(quitMark)
	if not initialx then
		initialx = MusicBar:frame().x
		firstIcon = initialx - 36
	end
	-- 定义菜单栏文本
	local maxLen = 500
	if quitMark == "quit" then
		menubarIcon = playIcon
		menubarTitle = ClicktoRun
	elseif Music.state() == "playing" then
		menubarIcon = playIcon
		if Music.title() == connectingFile then
			menubarTitle = connectingFile
		else
			menubarTitle = Music.title() .. gaptext .. Music.artist()
		end
	elseif Music.state() == "paused" or Music.title() ~= " " then
		menubarIcon = pauseIcon
		menubarTitle = Music.title() .. gaptext .. Music.artist()
	elseif Music.state() == "stopped" then
		menubarIcon = stopIcon
		menubarTitle = Stopped
	end
	titleShown = menubarIcon .. '  ' .. menubarTitle
	-- Music退出时避免触发打开
	if quitMark == "quit" then
		MusicBar:setTitle(titleShown)
		return
	end
	-- 根据预设宽度确定显示的文本内容
	if countWords(titleShown) * 13 > maxLen then
		if countWords(menubarIcon .. ' ' .. Music.title()) < maxLen then
			titleShown = menubarIcon .. ' ' .. Music.title()
		else
			titleShown = menubarIcon
		end
	end
	MusicBar:setTitle(titleShown)
end

--
-- 悬浮菜单函数集
--
-- 设置悬浮主菜单
function setmainmenu()
	barframe = MusicBar:frame()
	barframe.x = initialx - 36 - barframe.w
	-- 框架尺寸
	if not c_mainmenu then
		c_mainmenu = c.new({x = barframe.x, y = barframe.h + 5, h = artworksize.h + border.y * 2, w = smallsize}):level(c.windowLevels.cursor)
	end
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
	-- 设置悬浮菜单自适应宽度
	infosize = c_mainmenu:minimumTextSize(3, c_mainmenu["info"].text)
	local defaultsize = infosize.w + artworksize.w + border.x * 2 + gap.x
	if defaultsize < smallsize then
		defaultsize = smallsize
	end
	menuframe = {x = barframe.x, y = barframe.h + gap.y / 2, h = artworksize.h + 2 * border.y, w = defaultsize}
	if defaultsize > screenFrame.w - barframe.x - gap.x / 2 and defaultsize < screenFrame.w - gap.x then
		menuframe.x = screenFrame.w - gap.x / 2 - defaultsize
	elseif defaultsize > screenFrame.w - gap.x then
		menuframe.x = screenFrame.x + gap.x / 2
		menuframe.w = screenFrame.w - gap.x
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
    			togglecanvas()
        	end
		end
    	-- 跳转至当前曲目
    	if id == "info" and y < infosize.h - gap.y then
    		if event == "mouseUp" then
    			Music.locate()
        		togglecanvas()
    		end
    	end
       	-- 进度条
    	if id == "background" and (x >= c_progress:frame().x - menuframe.x and x <= c_progress:frame().x - menuframe.x + c_progress:frame().w and y >= c_progress:frame().y - menuframe.y and y <= c_progress:frame().y - menuframe.y + c_progress:frame().h) then
    		if event == "mouseUp" then
    			local mousepoint = hs.mouse.absolutePosition()
    			local currentposition = (mousepoint.x - menuframe.x - border.x) / c_progress:frame().w * Music.duration()
    			c_progress:replaceElements(progressElement):show()
				Music.tell('set player position to "' .. currentposition .. '"')
    		end
		end
		-- 点击左上角退出
		if id == "background" and event == "mouseUp" and y < border.y and x < border.x then
			hideall()
			progressTimer:stop()
			--Switch:stop()
			Music.tell('quit')
			quit = true
			quitTimer = hs.timer.waitWhile(
				Music.checkrunning,
				function()
					quit = false
					-- Switch:start()
				end
			)
		end
	end)
end
-- 设置Apple Music悬浮菜单项目
function setapplemusicmenu()
	-- 喜爱
	if Music.loved() then
		lovedimage = img.imageFromPath(hs.configdir .. "/image/Loved.png"):setSize(imagesize, absolute == true)
	else
		lovedimage = img.imageFromPath(hs.configdir .. "/image/notLoved.png"):setSize(imagesize, absolute == true)
	end
	-- 生成菜单框架和菜单项目
	if Music.kind() == "applemusic" then
		c_applemusicmenu_frame = {x = menuframe.x + border.x + artworksize.w + gap.x, y = menuframe.y + border.y + infosize.h, h = imagesize.h + gap.y, w = imagesize.w * 3}
	elseif Music.kind() == "matched" then
		c_applemusicmenu_frame = {x = menuframe.x + border.x + artworksize.w + gap.x, y = menuframe.y + border.y + infosize.h, h = imagesize.h, w = imagesize.w}
	end
	delete(c_localmusicmenu)
	if not c_applemusicmenu then
		c_applemusicmenu = c.new(c_applemusicmenu_frame):level(c_mainmenu:level() + 2)
	else
		c_applemusicmenu:frame(c_applemusicmenu_frame)
	end
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
	-- 生成菜单框架和菜单项目
	if Music.kind() == "localmusic" then
		localmusicmenuframe = {x = menuframe.x + border.x + artworksize.w + gap.x, y = menuframe.y + border.y + infosize.h, h = imagesize.h + gap.y, w = imagesize.w * 5.7}
		rateframe = {x = 0, y = 0, h = imagesize.h, w = imagesize.w * 5.5}
	elseif Music.kind() == "matched" then
		localmusicmenuframe = {x = menuframe.x + border.x + artworksize.w + gap.x + imagesize.w, y = menuframe.y + border.y + infosize.h, h = imagesize.h + gap.y, w = imagesize.w * 6.7}
		rateframe = {x = imagesize.w * 0.2, y = 0, h = imagesize.h, w = imagesize.w * 5.5}
	end
	if Music.kind() ~= "matched" then
		delete(c_applemusicmenu)
	end
	if not c_localmusicmenu then
		c_localmusicmenu = c.new(localmusicmenuframe):level(c_mainmenu:level() + 1)
	else
		c_localmusicmenu:frame(localmusicmenuframe)
	end
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
			image = img.imageFromPath(hs.configdir .. "/image/" .. Music.rating() .. "star.png"):setSize(imagesize, absolute == true),
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
	-- 随机菜单项目
	if Music.shuffle() then
		shuffleimage = img.imageFromPath(hs.configdir .. "/image/shuffle_on.png"):setSize(imagesize, absolute == true)
	else
		shuffleimage = img.imageFromPath(hs.configdir .. "/image/shuffle_off.png"):setSize(imagesize, absolute == true)
	end
	-- 循环菜单项目
	if Music.loop() == "all" then
		loopimage = img.imageFromPath(hs.configdir .. "/image/loop_all.png"):setSize(imagesize, absolute == true)
	elseif Music.loop() == "one" then
		loopimage = img.imageFromPath(hs.configdir .. "/image/loop_one.png"):setSize(imagesize, absolute == true)
	elseif Music.loop() == "off" then
		loopimage = img.imageFromPath(hs.configdir .. "/image/loop_off.png"):setSize(imagesize, absolute == true)
	end
	-- 添加进曲库
	if Music.kind() == "applemusic" then
		if not Music.existinlibrary() then
			addedimage = img.imageFromPath(hs.configdir .. "/image/add.png"):setSize(imagesize, absolute == true)
		else
			addedimage = img.imageFromPath(hs.configdir .. "/image/added.png"):setSize(imagesize, absolute == true)
		end
	elseif Music.kind() == "localmusic" or Music.kind() == "matched" then
		addedimage = img.imageFromPath(hs.configdir .. "/image/add.png"):setSize(imagesize, absolute == true)
	end
	-- 生成菜单框架和菜单项目
	c_controlmenu_frame = {x = menuframe.x + border.x + artworksize.w + gap.x, y = menuframe.y + border.y + infosize.h + imagesize.h + gap.y, h = imagesize.h, w = imagesize.w * (1 + 1.5 * 2)}
	if not c_controlmenu then
		c_controlmenu = c.new(c_controlmenu_frame):level(c_mainmenu:level() + 1)
	else
		c_controlmenu:frame(c_controlmenu_frame)
	end
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
			if not Music.existinlibrary() then
				Music.addtolibrary()
			end
			if not c_playlist then
				setplaylistmenu()
				c_playlist:orderAbove(c_mainmenu)
				show(c_playlist)
			elseif c_playlist then
				if not c_playlist:isShowing() then
					setplaylistmenu()
					c_playlist:orderAbove(c_mainmenu)
					show(c_playlist)
				else
					hide(c_playlist)
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
	-- 获取播放列表个数
	local playlistcount = Music.tell('count of (name of every user playlist whose smart is false and special kind is none)')
	-- 获取播放列表名称
	local playlistname = Music.tell('name of every user playlist whose smart is false and special kind is none')
	-- 框架尺寸
	controlmenuframe = c_controlmenu:frame()
	playlistframe = {x = controlmenuframe.x + c_controlmenu["playlist"].frame.x + c_controlmenu["playlist"].frame.w / 2, y = controlmenuframe.y + c_controlmenu["playlist"].frame.y + c_controlmenu["playlist"].frame.h / 2, h = textsize * playlistcount, w = smallsize}
	if not c_playlist then
		c_playlist = c.new(playlistframe):level(c_mainmenu:level() + 1)
	else
		c_playlist:frame(playlistframe)
	end
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
	minTextSize = c_playlist:minimumTextSize(1, c_playlist["test"].text)
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
		if not Music.existinplaylist(playlistname[count]) then
			textcolor = {red = menuTextColor[1] / 255, green = menuTextColor[2] / 255, blue = menuTextColor[3] / 255}
		else
			textcolor = {red = menuTextColorS[1] / 255, green = menuTextColorS[2] / 255, blue = menuTextColorS[3] / 255}
		end
		c_playlist:appendElements(
			{-- 菜单项背景
				id = "playlistback" .. count,
				frame = {x = 0, y = playlistframe.h / playlistcount * (count - 1), h = playlistframe.h / playlistcount, w = playlistframe.w},
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
				frame = {x = border.x, y = border.y * (count - 0.5) + playlistmenusize.h / playlistcount * (count - 1), h = playlistmenusize.h / playlistcount, w = playlistmenusize.w},
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
				frame = {x = 0, y = playlistframe.h / playlistcount * (count - 1), h = playlistframe.h / playlistcount, w = playlistframe.w},
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
					-- 判断是否添加成功
					if Music.kind() == "applemusic" then
						if not Music.existinlibrary() then
							hs.alert.show("曲の追加が失敗しているようです")
						end
						setcontrolmenu()
					end
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
	-- 进度条更新函数
	updateprogress = function()
		if c_progress:frame().w and Music.currentposition() and Music.duration() then
			progressElement.frame.w = c_progress:frame().w * Music.currentposition() / musicDuration
			c_progress:replaceElements(progressElement)
		end
	end
	-- 生成悬浮进度条
	if not c_progress then
		per = 60 / 100
		if Music.duration() > 0 then
			musicDuration = Music.duration()
		else
			musicDuration = 300
		end
		c_progress = c.new({x = menuframe.x + border.x, y = menuframe.y + border.y + artworksize.h + border.y * (1 - per) / 2, h = border.y * per, w = menuframe.w - border.x * 2}):level(c_mainmenu:level() + 0)
		progressElement = {
			id = "progress",
			type = "rectangle",
			roundedRectRadii = {xRadius = 2, yRadius = 2},
			frame = {x = 0, y = 0, h = c_progress:frame().h, w = c_progress:frame().w * Music.currentposition() / musicDuration},
			fillColor = {alpha = progressAlpha, red = progressColor[1] / 255, green = progressColor[2] / 255, blue = progressColor[3] / 255},
			trackMouseUp = true
		}
		c_progress:appendElements(progressElement)
	else
		c_progress:frame({x = menuframe.x + border.x, y = menuframe.y + border.y + artworksize.h + border.y * (1 - per) / 2, h = border.y * per, w = menuframe.w - border.x * 2})
		updateprogress()
	end
	progressTimer = hs.timer.doWhile(function() return c_progress:isShowing() end, updateprogress, updatetime)
	progressTimer:stop()
end

--
-- 悬浮菜单功能函数集
--
-- 隐藏
function hideall()
	hide(c_applemusicmenu,fadetime)
	hide(c_localmusicmenu,fadetime)
	hide(c_controlmenu,fadetime)
	if progressTimer then
		progressTimer:stop()
	end
	hide(c_progress,fadetime)
	hide(c_playlist,fadetime)
	hide(c_mainmenu,fadetime)
end
-- 显示
function showall()
	if progressTimer then
		progressTimer:start()
	end
	show(c_mainmenu,fadetime)
	show(c_applemusicmenu,fadetime)
	show(c_localmusicmenu,fadetime)
	show(c_controlmenu,fadetime)
	updateprogress()
	show(c_progress,fadetime)
end
-- 判断鼠标指针是否处于悬浮菜单内
function mousePosition()
	local mousepoint = hs.mouse.absolutePosition()
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
-- 建立悬浮菜单元素
function setMenu()
	if not c_mainmenu then
		c_mainmenu = c.new({x = 1, y = 1, h = 1, w = 1})
	end
	if c_mainmenu then
		if c_mainmenu:isShowing() then
			hideall()
			if progressTimer then
				progressTimer:stop()
			end
		else
			setmainmenu()
			if Music.kind() == "applemusic" then
				setapplemusicmenu()
			elseif Music.kind() == "localmusic" then
				setlocalmusicmenu()
			elseif Music.kind() == "matched" then
				setapplemusicmenu()
				setlocalmusicmenu()
			end
			setcontrolmenu()
			setprogresscanvas()
			if progressTimer then
				progressTimer:start()
			end
		end
	end
end
-- 鼠标点击时的行为
function togglecanvas()
	local spaceID = hs.spaces.activeSpaces()[hs.screen.mainScreen():getUUID()]
	local toggleFunction = function ()
		if Music.state() == "playing" or Music.state() == "paused" then
			if c_mainmenu then
				if c_mainmenu:isShowing() then
					hideall()
				else
					showall()
					-- 自动隐藏悬浮菜单
					autoTimer = hs.timer.waitUntil(
						function()
							if not c_playlist or (c_playlist and not c_playlist:isShowing()) then
								if c_mainmenu:isShowing() and not mousePosition() then
									return true
								else
									return false
								end
							elseif c_playlist and c_playlist:isShowing() then
								return false
							end
						end,
						function()
							stayTimer = delay(staytime, function() hideall() end)
						end
					)
				end
			end
		else
			as.applescript('tell application "Music" to activate')
		end
	end
	-- 判断渐入渐出是否已经完成，未完成则忽略点击
	if isFading then
		return
	end
	deleteTimer(fadeTimer)
	deleteTimer(autoTimer)
	deleteTimer(stayTimer)
	isFading = true
	toggleFunction()
	fadeTimer = hs.timer.doAfter(fadetime, function() isFading = false end)
end
-- 实时更新函数
function MusicBarUpdate()
	-- 若退出App则不执行任何动作
	if quit or not Music.checkrunning() then
		settitle("quit")
		return
	end
	-- 若更换了播放状态则触发更新
	if Music.state() ~= musicstate then
		musicstate = Music.state()
		settitle()
		if Music.state() == "playing" or Music.state() == "paused" then
			setMenu()
		end
	end
	-- 若切换Space则隐藏
	if hs.spaces.activeSpaces()[hs.screen.mainScreen():getUUID()] ~= spaceID then
		spaceID = hs.spaces.activeSpaces()[hs.screen.mainScreen():getUUID()]
		hideall()
	end
	-- 正常情况下的更新
	if Music.state() == "playing" or Music.state() == "paused" then
		-- 若连接中
		if Music.kind() == "connecting" then
			settitle()
		-- 若更换了曲目
		elseif Music.title() ~= songtitle then
			Music.saveartwork()
			songtitle = Music.title()
			settitle()
			Lyric.main()
			setMenu()
			--若切换歌曲时悬浮菜单正在显示则刷新
			if c_mainmenu and c_mainmenu:isShowing() then
				hideall()
				setmainmenu()
				if Music.kind() == "applemusic" then
					setapplemusicmenu()
				elseif Music.kind() == "localmusic" then
					setlocalmusicmenu()
				elseif Music.kind() == "matched" then
					setapplemusicmenu()
					setlocalmusicmenu()
				end
				setcontrolmenu()
				setprogresscanvas()
				deleteTimer(changeTimer)
				changeTimer = delay(0.6, togglecanvas)
			end
		end
	else
		progressTimer = nil
	end
	-- 非播放状态立即隐藏歌词
	if Music.state() ~= "playing" then
		hide(c_lyric)
	end
end
-- 生成菜单栏
if not MusicBar then
	MusicBar = hs.menubar.new(true):autosaveName("Music")
	MusicBar:setClickCallback(togglecanvas)
end
-- 实时更新菜单栏
Switch = hs.timer.new(1, MusicBarUpdate)
Switch:start()
-- 快捷键
hotkey.bind(hyper_shift, 'return', Music.toggleplay)
hotkey.bind(hyper_opt, 'right', function()
	if hs.spotify.isPlaying() then
		hs.spotify.next()
	else
		Music.next()
	end
end)
hotkey.bind(hyper_opt, 'left', function()
	if hs.spotify.isPlaying() then
		hs.spotify.previous()
	else
		Music.previous()
	end
end)
hotkey.bind(hyper_opt, 'up', function() setVolume("up") end, nil, function() setVolume("up") end)
hotkey.bind(hyper_opt, 'down', function() setVolume("down") end, nil, function() setVolume("down") end)