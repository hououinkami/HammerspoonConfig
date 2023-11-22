--
-- 定义变量 --
--
-- 系统变量
screenFrame = hs.screen.mainScreen():fullFrame()
menubarHeight = hs.screen.mainScreen():frame().y
-- 缓存变量初始化
local MusicBar = nil
local songtitle = nil
local songartist = nil
local songalbum = nil
local songloved = nil
local songdisliked = nil
local songrating = nil
local songalbum = nil
local songkind = nil
local songexistinlibrary = nil
local musicstate = nil
local maxlen = 0
-- 可更改的自定义变量
highVolume = 80
lowVolume = highVolume - 40
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
menuTextColorS = {232, 68, 79} -- 菜单字体选中颜色（RGB）
menuStrokeColor = {255, 255, 255} -- 菜单边框颜色（RGB）
menuStrokeAlpha = 0.8 -- 菜单边框透明度
progressColor = {185, 185, 185} -- 进度条颜色
AMRed = {232, 68, 79} -- Apple Music红
AMBlue = {0, 120, 255}
progressAlpha = 0.6 -- 进度条透明度
-- 本地化适配
local owner = hs.host.localizedName()
if string.find(owner,"Kami") or string.find(owner,"カミ") then
	MusicApp = "ミュージック"
	Stopped = "停止中"
	ClicktoRun = '起動していない'
	MusicLibrary = "ライブラリ"
	localFile = "AACオーディオファイル"
	connectingFile = "接続中…"
	streamingFile = "インターネットオーディオストリーム"
	genius = "Genius"
	unknowTitle = "未知"
else -- Edit here for other languages!
	MusicApp = "音乐"
	Stopped = "已停止"
	ClicktoRun = '未启动'
	MusicLibrary = "资料库"
	localFile = "AAC音频文件"
	connectingFile = "正在连接…"
	streamingFile = "互联网音频流"
	genius = "妙选"
	unknowTitle = "未知"
end

--
-- Music功能函数集 --
--
-- 调用AppleScript模块
function tell(cmd)
	local _cmd = 'tell application "Music" to ' .. cmd
	local ok, result = as.applescript(_cmd)
	if ok then
	  return result
	else
	  return nil
	end
end
local Music = {}
-- 曲目信息
Music.title = function ()
	local title = tell('name of current track') or " "
	return title
end
Music.artist = function ()
	local artist = tell('artist of current track') or " "
	return artist
end
Music.album = function ()
	local album = tell('album of current track') or " "
	return album
end
Music.duration = function()
	local duration = tell('finish of current track') or 1
	return duration
end
Music.currentposition = function()
	local currentposition = tell('player position') or 0
	return currentposition
end
Music.loved = function ()
	return tell('loved of current track')
end
Music.disliked = function ()
	return tell('disliked of current track')
end
Music.rating = function ()
	if tell('rating of current track') then
		return tell('rating of current track')//20
	end
end
Music.loop = function ()
	return tell('song repeat as string')
end
Music.shuffle = function ()
	return tell('shuffle enabled')
end
-- 星级评价
Music.setrating = function (rating)
	tell('set rating of current track to ' .. rating * 20)
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
	local kind = tell('kind of current track')
	local cloudstatus = tell('cloud status of current track as string')
	local class = tell('class of current track as string')
	if kind ~= nil then
		--若为本地曲目
		if (string.find(kind, localFile) and string.find(kind, "Apple Music") == nil) and cloudstatus ~= "matched" then
			musictype = "localmusic"
		-- 若Apple Μsic连接中
		elseif string.find(Music.title(),connectingFile) or string.find(Music.title(),unknowTitle) or string.find(Music.artist(),genius) or string.find(kind, streamingFile) then
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
-- 音量调整
Music.volume = function (volumeValue)
	tell('set sound volume to ' .. volumeValue)
end
-- 检测Music是否在运行
Music.checkrunning = function()
	local _,isrunning,_ = as.applescript([[tell application "System Events" to (name of processes) contains "Music"]])
	return isrunning
end
-- 检测播放状态
Music.state = function ()
	if Music.checkrunning() == true then
		return tell('player state as string')
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
Music.toggleshuffle = function ()
	if Music.shuffle() == false then
		tell("set shuffle enabled to true")
	else
		tell("set shuffle enabled to false")
	end
end
-- 切换重复模式
Music.toggleloop = function ()
	if Music.loop() == "all" then
		tell('set song repeat to one')
	elseif Music.loop() == "one" then
		tell('set song repeat to off')
	elseif Music.loop() == "off" then
		tell('set song repeat to all')
	end
end
-- 判断Apple Music曲目是否存在于本地曲库中
Music.existinlibrary = function ()
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
Music.addtolibrary = function()
	local addtolibraryScript = [[
		tell application "Music"
			try
				duplicate current track to library playlist "Library"
			on error
				duplicate current track to first source
			end try
		end tell
	]]
	if Music.kind() == "applemusic" then
		as.applescript(addtolibraryScript:gsub("Library",MusicLibrary))
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
	local _,existinplaylist,_ = as.applescript(existinscript:gsub("pname", playlistname))
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
	if tell('shuffle enabled') == false then
		tell('set shuffle enabled to true')
	end
	tell('play playlist named ' .. playlist)
end
-- 保存专辑封面
Music.saveartwork = function ()
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
Music.saveartworkbyapi = function (set_artwork_object)
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
Music.getartworkpath = function()
	if Music.kind() ~= "connecting" then
		-- 获取图片后缀名
		local format = tell('format of artwork 1 of current track as string')
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
-- 文本分割函数
function stringSplit(s, p)
    local rt= {}
    string.gsub(s, '[^'..p..']+', function(w) table.insert(rt, w) end)
    return rt
end
-- 获取App菜单栏文字项目
function getmenubarItemLeft(app)
	local appElement = ax.applicationElement(app)
	local MenuElements = {}
	if appElement then
		for i = #appElement, 1, -1 do
			local entity = appElement[i]
			if entity.AXRole == "AXMenuBar" then
				for j = 1, #entity, 1 do
					local menuBarEntity = entity[j]
					if menuBarEntity then
						if menuBarEntity.AXSubrole ~= "AXMenuExtra" then
							table.insert(MenuElements, menuBarEntity)
						end
					end
				end
				return MenuElements
			end
		end
	end
end
-- 获取App菜单栏图标
function getmenubarItemRight(app)
	local appElement = ax.applicationElement(app)
	local extraMenuElements = {}
	if appElement then
		for i = #appElement, 1, -1 do
			local entity = appElement[i]
			if entity.AXRole == "AXMenuBar" then
				for j = 1, #entity, 1 do
					local menuBarEntity = entity[j]
					if menuBarEntity then
						if menuBarEntity.AXSubrole == "AXMenuExtra" then
							table.insert(extraMenuElements, menuBarEntity)
						end
					end
				end
				return extraMenuElements
			end
		end
	end
end
-- 获取菜单栏文字菜单最右端位置
function getMenu()
	local Menu = getmenubarItemLeft(app.frontmostApplication())
	local lastMenu = 0
	if Menu then
		if #Menu > 0 then
			for _,m in ipairs (Menu) do
				if m.AXFrame ~= nil then
					local menuX = m.AXFrame.x
					local menuW = m.AXFrame.w
					if menuX + menuW > lastMenu then
						lastMenu = menuX + menuW
					end
				end
			end
		end
	end
	return lastMenu
end
-- 获取菜单栏图标最左端位置
function getmenuIcon()
	local MenuIcon = getmenubarItemRight(app.find("企业微信"))
	local firstIcon = screenFrame.w
	if MenuIcon then
		if #MenuIcon > 0 then
			for _,i in ipairs (MenuIcon) do
				if i.AXFrame.x < firstIcon then
					firstIcon = i.AXFrame.x
				end
			end
		end
	end
	return firstIcon
end
-- 创建菜单栏标题
function settitle()
	-- 菜单栏标题长度
	c_menubar = c.new({x = 0, y = 0, h = menubarHeight, w = 100})
	if Music.state() == "playing" or Music.state() == "paused" then
		c_menubar:appendElements(
		{
			id = "typeA",
			frame = {x = border.x + artworksize.w + gap.x, y = border.y, h = artworksize.h, w = 100},
			type = "text",
			text = '♫ ' .. Music.title() .. gaptext .. Music.artist(),
			textSize = 14
		},
		{
			id = "typeB",
			frame = {x = border.x + artworksize.w + gap.x, y = border.y, h = artworksize.h, w = 100},
			type = "text",
			text = '♫ ' .. Music.title(),
			textSize = 14
		}
		)
		titlesizeA = c_menubar:minimumTextSize(1, c_menubar["typeA"].text)
		titlesizeB = c_menubar:minimumTextSize(2, c_menubar["typeB"].text)
	elseif Music.state() == "stopped" then
		c_menubar:appendElements(
		{
			id = "typeC",
			frame = {x = border.x + artworksize.w + gap.x, y = border.y, h = artworksize.h, w = 100},
			type = "text",
			text = '◼ ' .. Stopped,
			textSize = 14
		}
		)
		titlesizeC = c_menubar:minimumTextSize(1, c_menubar["typeC"].text)
	elseif Music.state() == "norunning" then
		c_menubar:appendElements(
		{
			id = "typeD",
			frame = {x = border.x + artworksize.w + gap.x, y = border.y, h = artworksize.h, w = 100},
			type = "text",
			text = '♫ ' .. ClicktoRun,
			textSize = 14
		}
		)
		titlesizeD = c_menubar:minimumTextSize(1, c_menubar["typeD"].text)
	end
	destroyCanvasObj(c_menubar, true)
	c_menubar = nil
	maxlen = getmenuIcon() - getMenu()
	if Music.state() == "playing" then
		if Music.title() == connectingFile then
			MusicBar:setTitle('♫ ' .. connectingFile)
		else
			if titlesizeA.w < maxlen then
				MusicBar:setTitle('♫ ' .. Music.title() .. gaptext .. Music.artist())
			elseif titlesizeB.w < maxlen then
				MusicBar:setTitle('♫ ' .. Music.title())
			else
				MusicBar:setTitle('♫')
			end
		end
	elseif Music.state() == "paused" then
		if titlesizeA.w < maxlen then
			MusicBar:setTitle('❙ ❙ ' .. Music.title() .. gaptext .. Music.artist())
		elseif titlesizeB.w < maxlen then
			MusicBar:setTitle('❙ ❙ ' .. Music.title())
		else
			MusicBar:setTitle('❙ ❙ ')
		end
	elseif Music.state() == "stopped" then
		if titlesizeC.w < maxlen then
			MusicBar:setTitle('◼ ' .. Stopped)
		else
			MusicBar:setTitle('◼')
		end
	elseif Music.state() == "norunning" then
		if titlesizeD.w < maxlen then
			MusicBar:setTitle('♫ ' .. ClicktoRun)
		else
			MusicBar:setTitle('♫')
		end
	end
end

--
-- 悬浮菜单函数集
--
-- 设置悬浮主菜单
function setmainmenu()
	barframe = MusicBar:frame()
	destroyCanvasObj(c_mainmenu, true)
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
	-- 设置悬浮菜单自适应宽度
	infosize = c_mainmenu:minimumTextSize(3, c_mainmenu["info"].text)
	local defaultsize = infosize.w + artworksize.w + border.x * 2 + gap.x
	if defaultsize < smallsize then
		menuframe = {x = barframe.x, y = barframe.h + 5, h = artworksize.h + 2 * border.y, w = smallsize}
	elseif defaultsize < screenFrame.w - barframe.x - 5 then
		menuframe = {x = barframe.x, y = barframe.h + 5, h = artworksize.h + 2 * border.y, w = defaultsize}
	elseif defaultsize > screenFrame.w - barframe.x - 5 and defaultsize < screenFrame.w -10 then
		menuframe = {x = screenFrame.w - 5 - defaultsize, y = barframe.h + 5, h = artworksize.h + 2 * border.y, w = defaultsize}
	elseif defaultsize > screenFrame.w - 10 then
		menuframe = {x = screenFrame.x + 5, y = barframe.h + 5, h = artworksize.h + 2 * border.y, w = screenFrame.w - 10}
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
				tell('set player position to "' .. currentposition .. '"')
    		end
		end
		-- 点击左上角退出
		if id == "background" and event == "mouseUp" and y < border.y and x < border.x then
			hide("all")
			delay(2, function() progressTimer:stop() end)
			delay(2, function() Switch:stop() end)
			delay(2, function() tell('quit') end)
			delay(5, function() Switch:start() end)
		end
	end)
end
-- 设置Apple Music悬浮菜单项目
function setapplemusicmenu()
	destroyCanvasObj(c_applemusicmenu, true)
	-- 喜爱
	if Music.loved() == true then
		lovedimage = img.imageFromPath(hs.configdir .. "/image/Loved.png"):setSize(imagesize, absolute == true)
	else
		lovedimage = img.imageFromPath(hs.configdir .. "/image/notLoved.png"):setSize(imagesize, absolute == true)
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
	destroyCanvasObj(c_localmusicmenu, true)
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
	destroyCanvasObj(c_controlmenu, true)
	-- 随机菜单项目
	if Music.shuffle() == true then
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
		if Music.existinlibrary() == false then
			addedimage = img.imageFromPath(hs.configdir .. "/image/add.png"):setSize(imagesize, absolute == true)
		else
			addedimage = img.imageFromPath(hs.configdir .. "/image/added.png"):setSize(imagesize, absolute == true)
		end
	elseif Music.kind() == "localmusic" or Music.kind() == "matched" then
		addedimage = img.imageFromPath(hs.configdir .. "/image/add.png"):setSize(imagesize, absolute == true)
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
			end
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
   		setcontrolmenu()
    	c_controlmenu:orderAbove(c_mainmenu)
   		show(c_controlmenu)
   	end)
end
-- 播放列表悬浮菜单
function setplaylistmenu()
	destroyCanvasObj(c_playlist, true)
	-- 获取播放列表个数
	local playlistcount = tell('count of (name of every user playlist whose smart is false and special kind is none)')
	-- 获取播放列表名称
	local playlistname = tell('name of every user playlist whose smart is false and special kind is none')
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
		if Music.existinplaylist(playlistname[count]) == false then
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
						if Music.existinlibrary() == false then
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
	-- 生成悬浮进度条
	destroyCanvasObj(c_progress, true)
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
	progressTimer = hs.timer.doWhile(function()
		return c_progress:isShowing()
		end, 
		function()
			if c_progress:frame().w and Music.currentposition() and Music.duration() then
				progressElement.frame.w = c_progress:frame().w * Music.currentposition() / Music.duration()
				c_progress:replaceElements(progressElement):show()
			end
		end,
		updatetime)
	progressTimer:stop()
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
		if progressTimer then
			progressTimer:stop()
		end
		hide(c_progress)
		hide(c_playlist)
		hide(c_mainmenu)
	end
end
-- 显示
function show(canvas)
	if canvas ~= nil and canvas ~= "all" then
		canvas:show(fadetime)
	elseif canvas == "all" then
		if progressTimer then
			progressTimer:start()
		end
		show(c_mainmenu)
		show(c_applemusicmenu)
		show(c_localmusicmenu)
		show(c_controlmenu)
		show(c_progress)
	end
end
-- 删除图层
function destroyCanvasObj(cObj,gc)
	if not cObj then 
		return 
	end
	-- explicit :delete() is deprecated, use gc
	-- see https://github.com/Hammerspoon/hammerspoon/issues/3021
	-- cObj:delete(delay or 0)
	for i=#cObj,1,-1 do
	  cObj[i] = nil
	end
	cObj:clickActivating(false)
	cObj:mouseCallback(nil)
	cObj:canvasMouseEvents(nil, nil, nil, nil)
	cObj = nil
	if gc and gc == true then 
		collectgarbage() 
	end
end
-- 删除图层（已弃用）
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
	if c_mainmenu == nil then
		c_mainmenu = c.new({x = 1, y = 1, h = 1, w = 1})
	end
	if c_mainmenu ~= nil then
		if c_mainmenu:isShowing() == true then
			hide("all")
			if progressTimer then
				progressTimer:stop()
			end
		else
			setmainmenu()
			c_applemusicmenu = nil
			c_localmusicmenu = nil
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
local isFading = false
function togglecanvas()
	local spaceID = hs.spaces.activeSpaces()[hs.screen.mainScreen():getUUID()]
	local toggleFunction = function ()
		if Music.state() == "playing" or Music.state() == "paused" then
			if c_mainmenu ~= nil then
				if c_mainmenu:isShowing() == true then
					hide("all")
				else
					setMenu()
					show("all")
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
						end,function()
							delay(staytime, function() 
								isFading = true
								hide("all")
								hs.timer.doAfter(fadetime, function() isFading = false end)
							end)
						end
					)
				end
			end
		else
			tell('activate')
		end
	end
	-- 判断渐入渐出是否已经完成
	--[[
	-- 延迟触发
	if isFading == true then
		hs.timer.doAfter(fadetime, toggleFunction)
	else
		isFading = true
		toggleFunction()
	end
	hs.timer.doAfter(fadetime, function() isFading = false end)
	]]
	-- 忽略点击
	if isFading == true then
		return
	end
	isFading = true
	toggleFunction()
	hs.timer.doAfter(fadetime, function() isFading = false end)
end
-- 实时更新函数
function MusicBarUpdate()
	-- 若更换了播放状态则触发更新
	if Music.state() ~= musicstate then
		musicstate = Music.state()
		settitle()
	end
	-- 若菜单栏空白宽度有变更则触发更新
	if getmenuIcon() - getMenu() ~= maxlen then
		maxlen = getmenuIcon() - getMenu()
		settitle()
	end
	-- 若切换Space则隐藏
	if hs.spaces.activeSpaces()[hs.screen.mainScreen():getUUID()] ~= spaceID then
		spaceID = hs.spaces.activeSpaces()[hs.screen.mainScreen():getUUID()]
		hide("all")
	end
	-- 正常情况下的更新
	if Music.state() == "playing" or Music.state() == "paused" then
		--若更换了曲目
		---连接中
		if Music.kind() == "connecting" then
			settitle()
			songkind = Music.kind()
			c_mainmenu = nil
			c_applemusicmenu = nil
			c_localmusicmenu = nil
			c_controlmenu = nil
			c_progress = nil
		---连接完成
		elseif Music.kind() ~= "connecting" and Music.title() ~= songtitle then
			if songkind == nil then
				preKind = Music.kind()
				preTitle = Music.title()
				preArtist = Music.artist()
				preExistinlibrary = Music.existinlibrary()
			else
				preKind = songkind
				preTitle = songtitle
				preArtist = songartist
				preExistinlibrary = songexistinlibrary
			end
			--获取新歌曲信息
			if songkind == "connecting" then
				songkind = Music.kind()
				songtitle = Music.title()
				songartist = Music.artist()
				songloved = Music.loved()
				songrating = Music.rating()
				-- delay(5, function() Music.saveartwork() end)
				hs.timer.waitUntil(function()
					if Music.currentposition() ~= nil then
						if Music.currentposition() > 1 then
							return true
						else
							return false
						end
					else
						return false
					end
				end, function() Music.saveartwork() end)	
			else
				songkind = Music.kind()
				songexistinlibrary = Music.existinlibrary()
				songtitle = Music.title()
				songartist = Music.artist()
				songloved = Music.loved()
				songrating = Music.rating()
				Music.saveartwork()
			end
			-- Music.deleteLyric()
			settitle()
			setMenu()
			--若切换歌曲时悬浮菜单正在显示则刷新
			if c_mainmenu ~= nil and c_mainmenu:isShowing() == true then
				hide("all")
				setmainmenu()
				setMenu()
				delay(0.6, togglecanvas)
			end
		end
	else
		progressTimer = nil
		settitle()
	end	
end
-- 生成菜单栏
if MusicBar == nil then
	MusicBar = hs.menubar.new(true):autosaveName("Music")
	MusicBar:setClickCallback(togglecanvas)
end
-- 实时更新菜单栏
Switch = hs.timer.new(1, MusicBarUpdate)
Switch:start()