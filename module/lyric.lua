require ('module.base') 
require ('module.apple-music') 
local secret = io.open(os.getenv("HOME") .. "/.hammerspoon/module/secret.lua", "r")
if secret then
    require ('module.secret')
    io.close(secret)
else
    lyricAPI = "https://yourownlyricapi.com/"
end

-- 歌词设置项
if string.find(owner,"Kami") then
    lyricbgColor = {35, 37, 34} -- 背景颜色（RGB）
    lyricbgAlpha = 0 -- 背景透明度
    lyricTextColor = {0, 120, 255} -- 歌词颜色（RGB）
    lyricTextSize = 28 -- 歌词字体大小
    lyricTextFont = "HiraMaruProN-W4" -- 歌词字体
    lyricShadow = true -- 是否显示阴影效果
    lyricShadowColor = {255, 255, 255} -- 阴影颜色（RGB）
    lyricShadowAlpha = 1/3 -- 阴影透明度
    lyricShadowBlur = 3.0 -- 阴影模糊度
    lyricShadowOffset = {h = -1.0, w = 1.0} -- 阴影偏移量
else
    lyricbgColor = {35, 37, 34} -- 背景颜色（RGB）
    lyricbgAlpha = 0 -- 背景透明度
    lyricTextColor = {189, 138, 189} -- 歌词颜色（RGB）
    lyricTextSize = 28 -- 歌词字体大小
    lyricTextFont = "HiraMaruProN-W4" -- 歌词字体
    lyricShadow = true -- 是否显示阴影效果
    lyricShadowColor = {255, 255, 255} -- 阴影颜色（RGB）
    lyricShadowAlpha = 1/3 -- 阴影透明度
    lyricShadowBlur = 3.0 -- 阴影模糊度
    lyricShadowOffset = {h = -1.0, w = 1.0} -- 阴影偏移量
end

-- 变量初始化
local lyrictext = nil
local sub = false

Lyric = {}
-- 获取并显示歌词
Lyric.get = function()
	-- 初始化
    lyricurl = nil
	lyricTable = nil
	lineNO = 1
	if c_lyric then
		c_lyric["lyric"].text = ""
	end
	if lyricTimer then
		lyricTimer:stop()
	end
	if sub then
		keyword = Music.title():gsub("%(.*%)",""):gsub("（.*）","")
		print(keyword)
	else
		keyword = Music.title()
	end
	-- 获取歌曲ID
	local musicurl = lyricAPI .. "search?keywords=" .. hs.http.encodeForQuery(keyword) .. "&limit=10"
    hs.http.asyncGet(musicurl, nil, function(musicStatus,musicBody,musicHeader)
        if musicStatus == 200 then
            local musicinfo = hs.json.decode(musicBody)
			if musicinfo.result.songCount == 0 then
				sub = true
				Lyric.get()
			else
				sub = false
			end
            local similarity = 0
            if musicinfo.result.songCount > 0 then
                for i = 1, #musicinfo.result.songs, 1 do
                    if compareString(musicinfo.result.songs[i].artists[1].name, Music.artist()) == 100 then
                        song = i
                        break
                    end
                    if compareString(musicinfo.result.songs[i].artists[1].name, Music.artist()) > similarity then
                        similarity = compareString(musicinfo.result.songs[i].artists[1].name, Music.artist())
                        song = i
                    end
                end
				if song then
                	lyricurl = lyricAPI .. "lyric?id=" .. musicinfo.result.songs[song].id
				end
            end
        end
		if lyricurl then
			hs.http.asyncGet(lyricurl, nil, function(status,body,headers)
				if status == 200 then
					local lyricRaw = hs.json.decode(body)
					if lyricRaw.lrc ~= nil then
						lyric = lyricRaw.lrc.lyric
						lyricTable = Lyric.edit(lyric)
					end
				end
				if lyricTable then
					local a = 1
					lyricTimer = hs.timer.new(a, function() 
						a = lineNO or 1
						Lyric.show(a,lyricTable)
						b = stayTime
					end)
					lyricTimer:start()
				end
			end)
		end
    end)
end
-- 将歌词从json转变成table
Lyric.edit = function(lyric)
	local lyricData = stringSplit(lyric,"\n")
	local lyricTable = {}
	if #lyricData > 2 then
		for l = 1, #lyricData, 1 do
			if string.find(lyricData[l],'%[%d+:%d+%.%d+%]') and not string.find(lyricData[l],'-1%]') then
				local lyricLine = {}
				line = lyricData[l]:gsub("%[",""):gsub("%]","`")
				time = stringSplit(line, "`")[1]:gsub("%.",":")
				info = stringSplit(line, "`")[2] or ""
				min = stringSplit(time, ":")[1]
				sec = stringSplit(time, ":")[2]
				minisec = stringSplit(time, ":")[3] or 0
				time = hs.timer.seconds("00:" .. min .. ":" .. sec) + minisec / 1000
				lyricLine["index"] = l
				lyricLine["time"] = time
				lyricLine["lyric"] = info
				table.insert(lyricTable, lyricLine)
			end
		end
	else
		lyricTable = nil
	end
	return lyricTable
end
-- 显示歌词
Lyric.show = function(startline,lyric)
	-- 定位
	for l = startline, #lyric, 1 do
		if l < #lyric then
			if Music.currentposition() < lyric[l].time or Music.currentposition() > lyric[l+1].time then
				for j = 1, #lyric, 1 do
					if j < #lyric then
						if Music.currentposition() > lyric[j].time and Music.currentposition() < lyric[j+1].time then
							l = j
							break
						end
					else
						l = #lyric
					end
				end
			end
		end
		if l < #lyric then
			if Music.currentposition() > lyric[l].time and Music.currentposition() < lyric[l+1].time then
				currentLyric = lyric[l].lyric
				stayTime = lyric[l+1].time - Music.currentposition()
				lineNO = l
				break
			end
		else
			if Music.currentposition() >= lyric[l].time then
				currentLyric = lyric[#lyric].lyric
				lineNO = l
			end
		end
	end
	-- 显示
	if c_lyric == nil then
		c_lyric = c.new({x = 0, y = desktopFrame.h + menubarHeight - 50, h = 50, w = screenFrame.w}):level(c.windowLevels.cursor)
		c_lyric:appendElements(
			{
				id = "background",
				type = "rectangle",
				action = "fill",
				roundedRectRadii = {xRadius = 6, yRadius = 6},
				fillColor = {alpha = lyricbgAlpha, red = lyricbgColor[1] / 255, green = lyricbgColor[2] / 255, blue = lyricbgColor[3] / 255},
			},{
				id = "lyric",
				frame = {x = 0, y = 0, h = c_lyric:frame().h, w = c_lyric:frame().w},
				type = "text",
				text = "",
				textSize = lyricTextSize,
				textColor = {red = lyricTextColor[1] / 255, green = lyricTextColor[2] / 255, blue = lyricTextColor[3] / 255},
				textFont = lyricTextFont,
				textAlignment = "center",
                withShadow = lyricShadow,
                shadow = { blurRadius = lyricShadowBlur, color = {alpha = lyricShadowAlpha, red = lyricShadowColor[1] / 255, green = lyricShadowColor[2] / 255, blue = lyricShadowColor[3] / 255}, offset = lyricShadowOffset },
			}
		):behavior(c.windowBehaviors[1])
        -- 设置歌词图层自适应宽度
        lyricSize = c_lyric:minimumTextSize(2, c_lyric["lyric"].text)
		c_lyric["background"].frame.y = c_lyric:frame().h - lyricSize.h - gap.y
		c_lyric["background"].frame.h = lyricSize.h
		c_lyric["lyric"].frame.y = c_lyric:frame().h - lyricSize.h - gap.y
		c_lyric["lyric"].frame.h = lyricSize.h
    end
	if Music.state() == "playing" then
		if c_lyric:isShowing() == false then
			show(c_lyric)
		end
	else
		hide(c_lyric)
	end
	-- 歌词刷新
	if currentLyric ~= lyrictext then
		c_lyric["lyric"].text = currentLyric
		lyrictext = currentLyric
	end
end
-- 歌词显示与隐藏快捷键
hotkey.bind(hyper_cs, "l", function()
    if c_lyric then
        if c_lyric:isShowing() == false then
            lyricTimer:start()
        else
            hide(c_lyric)
            lyricTimer:stop()
        end
	end
end)
-- 歌词模块停用与启用快捷键
hotkey.bind(hyper_cos, "l", function()
    if lyricTimer and lyricTimer:running() then
		lyricTimer:stop()
        destroyCanvasObj(c_lyric,true)
        c_lyric = nil
    else
        Lyric.get()
	end
end)