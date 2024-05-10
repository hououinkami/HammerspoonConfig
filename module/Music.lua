require ('module.base') 
require ('module.apple-music') 
require ('module.Lyric') 
require ('config.music')
--
-- MenuBar函数集 --
--
-- 创建菜单栏标题
function setTitle(quitMark)
	if not initialX then
		initialX = MusicBar:frame().x
		firstIcon = initialX - 36
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
			menubarTitle = Music.title() .. gapText .. Music.artist()
		end
	elseif Music.state() == "paused" or Music.title() ~= " " then
		menubarIcon = pauseIcon
		menubarTitle = Music.title() .. gapText .. Music.artist()
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
function setMainMenu()
	barFrame = MusicBar:frame()
	barFrame.x = initialX - 36 - barFrame.w
	-- 框架尺寸
	if not c_mainMenu then
		c_mainMenu = c.new({x = barFrame.x, y = barFrame.h + 5, h = artworkSize.h + borderSize.y * 2, w = smallSize}):level(c.windowLevels.cursor)
	end
	-- 菜单项目
	c_mainMenu:replaceElements(
		{-- 背景
			id = "background",
			type = "rectangle",
			action = "fill",
			roundedRectRadii = {xRadius = 6, yRadius = 6},
			fillColor = {alpha = bgAlpha, red = bgColor[1] / 255, green = bgColor[2] / 255, blue = bgColor[3] / 255},
			-- trackMouseEnterExit = true,
			trackMouseUp = true
		}, {-- 专辑封面
			id = "artwork",
			frame = {x = borderSize.x, y = borderSize.y, h = artworkSize.h, w = artworkSize.w},
			type = "image",
			image = Music.getArtworkPath(),
			trackMouseEnterExit = true,
			trackMouseUp = true
		}, 	{-- 专辑信息
			id = "info",
			frame = {x = borderSize.x + artworkSize.w + gapSize.x, y = borderSize.y, h = artworkSize.h, w = 100},
			type = "text",
			text = Music.title() .. "\n\n" .. Music.artist()  .. "\n\n" .. Music.album()  .. "\n",
			textSize = textSize,
			textLineBreak = "wordWrap",
			trackMouseEnterExit = true,
			trackMouseUp = true
		}
	)
	-- 设置悬浮菜单自适应宽度
	infoSize = c_mainMenu:minimumTextSize(3, c_mainMenu["info"].text)
	local defaultSize = infoSize.w + artworkSize.w + borderSize.x * 2 + gapSize.x
	if defaultSize < smallSize then
		defaultSize = smallSize
	end
	menuFrame = {x = barFrame.x, y = barFrame.h + gapSize.y / 2, h = artworkSize.h + 2 * borderSize.y, w = defaultSize}
	if defaultSize > screenFrame.w - barFrame.x - gapSize.x / 2 and defaultSize < screenFrame.w - gapSize.x then
		menuFrame.x = screenFrame.w - gapSize.x / 2 - defaultSize
	elseif defaultSize > screenFrame.w - gapSize.x then
		menuFrame.x = screenFrame.x + gapSize.x / 2
		menuFrame.w = screenFrame.w - gapSize.x
	end
	c_mainMenu:frame(menuFrame)
	if infoSize.w < 100 then
		c_mainMenu["info"].frame.w = textSize * 5
	else
		c_mainMenu["info"].frame.w = infoSize.w
	end
	-- 鼠标行为
	c_mainMenu:mouseCallback(function(canvas, event, id, x, y)
		-- x,y为距离整个悬浮菜单边界的坐标
		-- 隐藏悬浮菜单
    	if id == "background" and (x < borderSize.x or x > menuFrame.w - borderSize.x or y > menuFrame.h - borderSize.y ) then
    		if event == "mouseExit" then
    			toggleCanvas()
        	end
		end
    	-- 跳转至当前曲目
    	if id == "info" and y < infoSize.h - gapSize.y then
    		if event == "mouseUp" then
				toggleCanvas()
    			Music.locate()
    		end
    	end
		-- 点击左上角退出
		if id == "background" and event == "mouseUp" and y < borderSize.y and x < borderSize.x then
			quit = true
			hideall()
			progressTimer:stop()
			Music.tell('quit')
			quitTimer = hs.timer.waitWhile(
				Music.checkRunning,
				function()
					quit = false
				end
			)
		end
	end)
end
-- 设置桌面覆盖层
function setDesktopLayer()
	if not c_desktopLayer then
		c_desktopLayer = c.new(screenFrame):level(c.windowLevels.popUpMenu)
		c_desktopLayer:appendElements(
			{
				id = "desktop",
				type = "rectangle",
				action = "fill",
				roundedRectRadii = {xRadius = 6, yRadius = 6},
				fillColor = {alpha = 0, red = bgColor[1] / 255, green = bgColor[2] / 255, blue = bgColor[3] / 255},
				trackMouseUp = true
			}
		)
		c_desktopLayer:mouseCallback(function(canvas, event, id, x, y)
			if id == "desktop" and event == "mouseUp" then
				hideall()
				hide(c_desktopLayer)
				hs.eventtap.leftClick(hs.mouse.absolutePosition(), 1000)
			end
		end)
	end
	c_desktopLayer:show()
end
-- 设置评价悬浮菜单项目
function setRateMenu()
	-- 图片设置
	local loveImage = function()
		return img.imageFromPath(hs.configdir .. "/image/" .. "loved_" .. tostring(Music.loved()) .. ".png"):setSize(imageSize, absolute == true)
	end
	local rateImage = function()
		return img.imageFromPath(hs.configdir .. "/image/" .. Music.rating() .. "star.png"):setSize(imageSize, absolute == true)
	end
	-- 生成菜单框架和菜单项目
	if Music.kind() == "applemusic" then
		c_rateMenu_frame = {x = menuFrame.x + borderSize.x + artworkSize.w + gapSize.x, y = menuFrame.y + borderSize.y + infoSize.h, h = imageSize.h + gapSize.y, w = imageSize.w * 3}
		c_rateMenu_elements = {
			{-- 喜爱
				id = "loved",
				frame = {x = 0, y = 0, h = imageSize.h, w = imageSize.w},
				type = "image",
				image = loveImage(),
				imageScaling = "shrinkToFit",
				imageAlignment = "left",
				trackMouseUp = true
			}
		}
		c_rateMenu_fn = function(canvas, event, id, x, y)
			-- x,y为距离整个悬浮菜单边界的坐标
			-- 喜爱
			if id == "loved" and (y > c_rateMenu["loved"].frame.y and y < c_rateMenu["loved"].frame.y + c_rateMenu["loved"].frame.h) and event == "mouseUp" then
				if x > c_rateMenu["loved"].frame.x and x < c_rateMenu["loved"].frame.x + c_rateMenu["loved"].frame.w then
					Music.toggleLoved()
					c_rateMenu["loved"].image = loveImage()
				   end
			end
		end
	elseif Music.kind() == "localmusic" then
		c_rateMenu_frame = {x = menuFrame.x + borderSize.x + artworkSize.w + gapSize.x, y = menuFrame.y + borderSize.y + infoSize.h, h = imageSize.h + gapSize.y, w = imageSize.w * 5.7}
		rateFrame = {x = 0, y = 0, h = imageSize.h, w = imageSize.w * 5.5}
		c_rateMenu_elements = {
			{
				id = "background",
				type = "rectangle",
				action = "fill",
				fillColor = {alpha = 0, red = 0, green = 0, blue = 0},
				trackMouseUp = true
			}, {
				id = "rate",
				frame = rateFrame,
				type = "image",
				image = rateImage(),
				imageAlignment = "left",
				trackMouseUp = true
			}
		}
		c_rateMenu_fn = function(canvas, event, id, x, y)
			-- x,y为距离整个悬浮菜单边界的坐标
			if id == "background" and event == "mouseUp" and y > imageSize.h and x > imageSize.w * 0.2 and x <  c_rateMenu["rate"].frame.w / 5 * 1 then
				Music.setRating(0)
			end
			if id == "rate" and event == "mouseUp" then
				if  y < imageSize.h then
					if x > imageSize.w * 0.2 and x <  c_rateMenu["rate"].frame.w / 5 * 1 then
						Music.setRating(1)
					elseif  x > c_rateMenu["rate"].frame.w / 5 * 1 and x < c_rateMenu["rate"].frame.w / 5 * 2 then
						Music.setRating(2)
					elseif  x > c_rateMenu["rate"].frame.w / 5 * 2 and x < c_rateMenu["rate"].frame.w / 5 * 3 then
						Music.setRating(3)
					elseif  x > c_rateMenu["rate"].frame.w / 5 * 3 and x < c_rateMenu["rate"].frame.w / 5 * 4 then
						Music.setRating(4)
					elseif  x > c_rateMenu["rate"].frame.w / 5 * 4 and x < c_rateMenu["rate"].frame.w / 5 * 5 then
						Music.setRating(5)
					end
				end
			end
			c_rateMenu["rate"].image = rateImage()
		end
	elseif Music.kind() == "matched" then
		c_rateMenu_frame = {x = menuFrame.x + borderSize.x + artworkSize.w + gapSize.x, y = menuFrame.y + borderSize.y + infoSize.h, h = imageSize.h, w = imageSize.w * 7.7}
		rateFrame = {x = imageSize.w * 1.2, y = 0, h = imageSize.h, w = imageSize.w * 5.5}
		c_rateMenu_elements = {
			{
				id = "background",
				type = "rectangle",
				action = "fill",
				fillColor = {alpha = 0, red = 0, green = 0, blue = 0},
				trackMouseUp = true
			}, {
				id = "loved",
				frame = {x = 0, y = 0, h = imageSize.h, w = imageSize.w},
				type = "image",
				image = loveImage(),
				imageScaling = "shrinkToFit",
				imageAlignment = "left",
				trackMouseUp = true
			},{
				id = "rate",
				frame = rateFrame,
				type = "image",
				image = rateImage(),
				imageAlignment = "left",
				trackMouseUp = true
			}
		}
		c_rateMenu_fn = function(canvas, event, id, x, y)
			-- x,y为距离整个悬浮菜单边界的坐标
			if id == "loved" and (y > c_rateMenu["loved"].frame.y and y < c_rateMenu["loved"].frame.y + c_rateMenu["loved"].frame.h) and event == "mouseUp" then
				if x > c_rateMenu["loved"].frame.x and x < c_rateMenu["loved"].frame.x + c_rateMenu["loved"].frame.w then
					Music.toggleLoved()
					c_rateMenu["loved"].image = loveImage()
				   end
			end
			if id == "background" and event == "mouseUp" and y > imageSize.h and x > imageSize.w * 1.2 and x <  c_rateMenu["rate"].frame.w / 5 * 1  + imageSize.w then
				Music.setRating(0)
			end
			if id == "rate" and event == "mouseUp" then
				if  y < imageSize.h then
					if x > imageSize.w * 1.2 and x <  c_rateMenu["rate"].frame.w / 5 * 1 + imageSize.w then
						Music.setRating(1)
					elseif  x > c_rateMenu["rate"].frame.w / 5 * 1 + imageSize.w and x < c_rateMenu["rate"].frame.w / 5 * 2 + imageSize.w then
						Music.setRating(2)
					elseif  x > c_rateMenu["rate"].frame.w / 5 * 2 + imageSize.w and x < c_rateMenu["rate"].frame.w / 5 * 3 + imageSize.w then
						Music.setRating(3)
					elseif  x > c_rateMenu["rate"].frame.w / 5 * 3 + imageSize.w and x < c_rateMenu["rate"].frame.w / 5 * 4 + imageSize.w then
						Music.setRating(4)
					elseif  x > c_rateMenu["rate"].frame.w / 5 * 4 + imageSize.w and x < c_rateMenu["rate"].frame.w / 5 * 5 + imageSize.w then
						Music.setRating(5)
					end
				end
			end
			c_rateMenu["rate"].image = rateImage()
		end
	end
	if not c_rateMenu then
		c_rateMenu = c.new(c_rateMenu_frame):level(c_mainMenu:level() + 2)
	else
		c_rateMenu:frame(c_rateMenu_frame)
	end
	-- 更新元素
	c_rateMenu:replaceElements(c_rateMenu_elements)
	-- 鼠标行为
	c_rateMenu:mouseCallback(c_rateMenu_fn)
end
-- 设置播放控制悬浮菜单项目
function setControlMenu()
	-- 图片设置
	local shuffleImage = function()
		return img.imageFromPath(hs.configdir .. "/image/" .. "shuffle_" .. tostring(Music.shuffle()) .. ".png"):setSize(imageSize, absolute == true)
	end
	local loopImage = function()
		return img.imageFromPath(hs.configdir .. "/image/" .. "loop_" .. Music.loop() .. ".png"):setSize(imageSize, absolute == true)
	end
	local addedImage = function()
		if Music.kind() == "applemusic" then
			isExist = tostring(Music.existInLibrary())
		elseif Music.kind() == "localmusic" or Music.kind() == "matched" then
			isExist = "false"
		end
		return img.imageFromPath(hs.configdir .. "/image/" .. "added_" .. isExist .. ".png"):setSize(imageSize, absolute == true)
	end
	-- 生成菜单框架和菜单项目
	c_controlMenu_frame = {x = menuFrame.x + borderSize.x + artworkSize.w + gapSize.x, y = menuFrame.y + borderSize.y + infoSize.h + imageSize.h + gapSize.y, h = imageSize.h, w = imageSize.w * (1 + 1.5 * 2)}
	if not c_controlMenu then
		c_controlMenu = c.new(c_controlMenu_frame):level(c_mainMenu:level() + 2)
	else
		c_controlMenu:frame(c_controlMenu_frame)
	end
	c_controlMenu:replaceElements(
		 {
			id = "shuffle",
			frame = {x = 0, y = 0, h = imageSize.h, w = imageSize.w},
			type = "image",
			image = shuffleImage(),
			imageAlignment = "center",
			trackMouseUp = true
		}, {
			id = "loop",
			frame = {x = imageSize.w * 1.5 , y = 0, h = imageSize.h, w = imageSize.w},
			type = "image",
			image = loopImage(),
			imageAlignment = "center",
			trackMouseUp = true
		}, {
			id = "playlist",
			frame = {x = imageSize.w * 1.5 * 2 , y = 0, h = imageSize.h, w = imageSize.w},
			type = "image",
			image = addedImage(),
			imageAlignment = "center",
			trackMouseUp = true
		}
	)
	-- 鼠标行为
	c_controlMenu:mouseCallback(function(canvas, event, id, x, y)
		-- x,y为距离整个悬浮菜单边界的坐标
    	if id == "shuffle" and event == "mouseUp" then
    		Music.toggleShuffle()
   		elseif id == "loop" and event == "mouseUp" then
			Music.toggleLoop()
		elseif id == "playlist" and event == "mouseUp" then
			if not Music.existInLibrary() then
				Music.addToLibrary()
			end
			if not c_playlist then
				setPlaylistMenu()
			elseif c_playlist then
				if not c_playlist:isShowing() then
					setPlaylistMenu()
				else
					hide(c_playlist)
				end
			end
   		end
   		c_controlMenu["shuffle"].image = shuffleImage()
		c_controlMenu["loop"].image = loopImage()
		c_controlMenu["playlist"].image = addedImage()
   	end)
end
-- 播放列表悬浮菜单
function setPlaylistMenu()
	-- 获取播放列表个数
	local playlistCount = Music.tell('count of (name of every user playlist whose smart is false and special kind is none)')
	-- 获取播放列表名称
	local playlistName = Music.tell('name of every user playlist whose smart is false and special kind is none')
	-- 框架尺寸
	controlMenuFrame = c_controlMenu:frame()
	playlistFrame = {x = controlMenuFrame.x + c_controlMenu["playlist"].frame.x + c_controlMenu["playlist"].frame.w / 2, y = controlMenuFrame.y + c_controlMenu["playlist"].frame.y + c_controlMenu["playlist"].frame.h / 2, h = textSize * playlistCount, w = smallSize}
	if not c_playlist then
		c_playlist = c.new(playlistFrame):level(c_mainMenu:level() + 1)
	else
		c_playlist:frame(playlistFrame)
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
			frame = {x = 0, y = 0, h = textSize, w = 1},
			type = "text",
			text = test,
			textSize = textSize,
			textLineBreak = "wordWrap",
			trackMouseEnterExit = true,
			trackMouseUp = true
		}
	)
	minTextSize = c_playlist:minimumTextSize(1, c_playlist["test"].text)
	playlistMenuSize = c_playlist:minimumTextSize(1, c_playlist["test"].text)
	playlistFrame = {x = playlistFrame.x, y = playlistFrame.y, h = playlistMenuSize.h + borderSize.y * playlistCount, w = playlistMenuSize.w}
	c_playlist:frame(playlistFrame)
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
		if not Music.existInPlaylist(playlistName[count]) then
			textColor = {red = menuTextColor[1] / 255, green = menuTextColor[2] / 255, blue = menuTextColor[3] / 255}
		else
			textColor = {red = menuTextColorS[1] / 255, green = menuTextColorS[2] / 255, blue = menuTextColorS[3] / 255}
		end
		c_playlist:appendElements(
			{-- 菜单项背景
				id = "playlistback" .. count,
				frame = {x = 0, y = playlistFrame.h / playlistCount * (count - 1), h = playlistFrame.h / playlistCount, w = playlistFrame.w},
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
				frame = {x = borderSize.x, y = borderSize.y * (count - 0.5) + playlistMenuSize.h / playlistCount * (count - 1), h = playlistMenuSize.h / playlistCount, w = playlistMenuSize.w},
				type = "text",
				text = playlistName[count],
				textSize = textSize,
				textColor = textColor;
				textLineBreak = "wordWrap",
				trackMouseEnterExit = true,
				trackMouseUp = true
			}
		)
		c_playlist:appendElements(
			{-- 菜单项overlay
				id = "playlistoverlay" .. count,
				frame = {x = 0, y = playlistFrame.h / playlistCount * (count - 1), h = playlistFrame.h / playlistCount, w = playlistFrame.w},
				type = "rectangle",
				roundedRectRadii = {xRadius = 6, yRadius = 6},
				fillColor = {alpha = 0, red = 0, green = 0, blue = 0},
				strokeColor = {alpha = menuStrokeAlpha, red = menuStrokeColor[1] / 255, green = menuStrokeColor[2] / 255, blue = menuStrokeColor[3] / 255},
				trackMouseEnterExit = true,
				trackMouseUp = true
			}
		)
		count = count + 1
	until count > playlistCount
	-- 鼠标行为
	c_playlist:mouseCallback(function(canvas, event, id, x, y)
		-- x,y为距离整个悬浮菜单边界的坐标
		i = 1
		repeat
			if id == "playlistoverlay" .. i then
				if event == "mouseEnter" then
					c_playlist["playlistback" .. i].fillColor = {alpha = menubgAlphaS, red = menubgColorS[1] / 255, green = menubgColorS[2] / 255, blue = menubgColorS[3] / 255}
				elseif event == "mouseExit" then
					if x > borderSize.x and x < playlistFrame.w - borderSize.x and y > borderSize.y and y < playlistFrame.h - borderSize.y then
						c_playlist["playlistback" .. i].fillColor = {alpha = menubgAlpha, red = menubgColor[1] / 255, green = menubgColor[2] / 255, blue = menubgColor[3] / 255}
					else
						hide(c_playlist)
					end
				elseif event == "mouseUp" then
					Music.addToPlaylist(playlistName[i])
					hide(c_playlist)
					-- 判断是否添加成功
					if Music.kind() == "applemusic" then
						if not Music.existInLibrary() then
							hs.alert.show("曲の追加が失敗しているようです")
						end
						setControlMenu()
					end
				end
			end
			i = i + 1
		until i > playlistCount
		if id == "background" then
			if event == "mouseExit" then
				hide(c_playlist)
			end
		end
	end)
end
-- 设置进度条悬浮菜单
function setProgressCanvas()
	-- 进度条更新函数
	updateProgress = function()
		if c_progress:frame().w and Music.currentPosition() and Music.duration() then
			progressElement[1].frame.w = c_progress:frame().w * Music.currentPosition() / Music.duration()
			c_progress:replaceElements(progressElement)
		end
	end
	-- 生成悬浮进度条
	if not c_progress then
		per = 60 / 100
		if Music.duration() > 0 then
			musicDuration = Music.duration()
		else
			musicDuration = math.huge
		end
		c_progress = c.new({x = menuFrame.x + borderSize.x, y = menuFrame.y + borderSize.y + artworkSize.h + borderSize.y * (1 - per) / 2, h = borderSize.y * per, w = menuFrame.w - borderSize.x * 2}):level(c_mainMenu:level() + 2)
		progressElement = {
			{
				id = "progress",
				type = "rectangle",
				roundedRectRadii = {xRadius = 2, yRadius = 2},
				frame = {x = 0, y = 0, h = c_progress:frame().h, w = c_progress:frame().w * Music.currentPosition() / musicDuration},
				fillColor = {alpha = progressAlpha, red = progressColor[1] / 255, green = progressColor[2] / 255, blue = progressColor[3] / 255},
				trackMouseUp = true
			},{
				id = "background",
				type = "rectangle",
				action = "fill",
				roundedRectRadii = {xRadius = 6, yRadius = 6},
				fillColor = {alpha = 0, red = bgColor[1] / 255, green = bgColor[2] / 255, blue = bgColor[3] / 255},
				trackMouseUp = true
			},
		}
		c_progress:appendElements(progressElement)
	else
		c_progress:frame({x = menuFrame.x + borderSize.x, y = menuFrame.y + borderSize.y + artworkSize.h + borderSize.y * (1 - per) / 2, h = borderSize.y * per, w = menuFrame.w - borderSize.x * 2})
		updateProgress()
	end
	c_progress:mouseCallback(function(canvas, event, id, x, y)
		if id == "background" and (x >= 0 and x <= c_progress:frame().w and y >= 0 and y <= c_progress:frame().h) then
    		if event == "mouseUp" then
    			local mousePoint = hs.mouse.absolutePosition()
    			local currentPosition = (mousePoint.x - c_progress:frame().x) / c_progress:frame().w * Music.duration()
    			c_progress:replaceElements(progressElement):show()
				Music.tell('set player position to "' .. currentPosition .. '"')
    		end
		end
	end)
	progressTimer = hs.timer.doWhile(function() return c_progress:isShowing() end, updateProgress, updateTime)
	progressTimer:stop()
end

--
-- 悬浮菜单功能函数集
--
-- 隐藏
function hideall()
	hide(c_desktopLayer)
	hide(c_rateMenu,fadeTime)
	hide(c_controlMenu,fadeTime)
	if progressTimer then
		progressTimer:stop()
	end
	hide(c_progress,fadeTime)
	hide(c_playlist,fadeTime)
	hide(c_mainMenu,fadeTime)
end
-- 显示
function showall()
	if progressTimer then
		progressTimer:start()
	end
	show(c_mainMenu,fadeTime)
	show(c_rateMenu,fadeTime)
	show(c_controlMenu,fadeTime)
	updateProgress()
	show(c_progress,fadeTime)
end
-- 判断鼠标指针是否处于悬浮菜单内
function mousePosition()
	local mousePoint = hs.mouse.absolutePosition()
	if (
		(mousePoint.x > barFrame.x and mousePoint.x < barFrame.x + barFrame.w and mousePoint.y > barFrame.y and mousePoint.y < barFrame.y + barFrame.h + gapSize.y)
		or
		(mousePoint.x > menuFrame.x and mousePoint.x < menuFrame.x + menuFrame.w and mousePoint.y > menuFrame.y - gapSize.y and mousePoint.y < menuFrame.y + menuFrame.h)
			) then
		mp = true
	else
		mp = false
	end
	return mp
end
-- 建立悬浮菜单元素
function setMenu()
	setMainMenu()
	if c_mainMenu then
		if c_mainMenu:isShowing() then
			hideall()
			if progressTimer then
				progressTimer:stop()
			end
		else
			setRateMenu()
			setControlMenu()
			setProgressCanvas()
			if progressTimer then
				progressTimer:start()
			end
		end
	end
end
-- 鼠标点击时的行为
function toggleCanvas()
	local spaceID = hs.spaces.activeSpaces()[hs.screen.mainScreen():getUUID()]
	local toggleFunction = function ()
		if Music.state() == "playing" or Music.state() == "paused" then
			if c_mainMenu then
				if c_mainMenu:isShowing() then
					hideall()
				else
					showall()
					setDesktopLayer()
					-- watchClick = hs.eventtap.new({hs.eventtap.event.types.leftMouseUp}, function(e)
					-- 	local mp = hs.mouse.absolutePosition()
					-- 	if mp.x < c_mainMenu:frame().x or mp.x > c_mainMenu:frame().x + c_mainMenu:frame().w or mp.y < c_mainMenu:frame().y or mp.y > c_mainMenu:frame().y + c_mainMenu:frame().h then
					-- 		hideall()
					-- 		watchClick:stop()
					-- 	end
					-- end):start()
				end
			end
		else
			Music.tell('activate')
		end
	end
	-- 判断渐入渐出是否已经完成，未完成则忽略点击
	if fadeTime > 0 then
		if isFading then
			return
		end
		isFading = true
		toggleFunction()
		fadeTimer = hs.timer.doAfter(fadeTime, function() isFading = false end)
	else
		toggleFunction()
	end
end
-- 实时更新函数
function musicBarUpdate()
	-- 若退出App则不执行任何动作
	if quit or not Music.checkRunning() then
		setTitle("quit")
		return
	end
	-- 若更换了播放状态则触发更新
	if Music.state() ~= musicstate then
		if stateChange then
			stateChange = false
		else
			stateChange = true
		end
		musicstate = Music.state()
		setTitle()
	end
	-- 正常情况下的更新
	if Music.state() == "playing" or Music.state() == "paused" then
		-- 若更换了曲目
		if Music.title() ~= songtitle then
			--若切换歌曲时悬浮菜单正在显示则刷新
			if c_mainMenu and c_mainMenu:isShowing() then
				hideall()
			end
			Music.saveArtwork()
			songtitle = Music.title()
			if not stateChange then
				setTitle()
			else
				stateChange = false
			end
			Lyric.main()
			setMenu()
		end
	else
		progressTimer = nil
		hideall()
	end
	-- 非播放状态立即隐藏歌词
	if Music.state() ~= "playing" then
		hide(c_lyric)
	end
	-- 若切换Space则隐藏
	if hs.spaces.activeSpaces()[hs.screen.mainScreen():getUUID()] ~= spaceID then
		spaceID = hs.spaces.activeSpaces()[hs.screen.mainScreen():getUUID()]
		hideall()
	end
end
-- 生成菜单栏
if not MusicBar then
	MusicBar = hs.menubar.new(true):autosaveName("Music")
	MusicBar:setClickCallback(toggleCanvas)
end
-- 实时更新菜单栏
Switch = hs.timer.new(updateTime, musicBarUpdate)
Switch:start()
-- 快捷键
hotkey.bind(hyper_shift, 'return', Music.togglePlay)
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