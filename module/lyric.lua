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
	lyricTimeOffset = -0.5 -- 歌词刷新时间偏移量
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
	lyricTimeOffset = -0.5 -- 歌词刷新时间偏移量
end

Lyric = {}
-- 获取并显示歌词
Lyric.main = function()
	-- 初始化
    lyricurl = nil
	lyricTable = nil
	lineNO = 1
	hide(c_lyric)
	if c_lyric then
		c_lyric["lyric"].text = ""
	end
	if lyricTimer then
		lyricTimer:stop()
	end
	keyword = Music.title()
	if Music.title():find("feat%.") or Music.title():find("%(")  or Music.title():find("（") then
		keyword = Music.title():gsub("%(.*%)",""):gsub("（.*）","")
	end
	-- 获取歌曲ID
	local musicurl = lyricAPI .. "search?keywords=" .. hs.http.encodeForQuery(keyword) .. "&limit=10"
    hs.http.asyncGet(musicurl, nil, function(musicStatus,musicBody,musicHeader)
        if musicStatus == 200 then
            local musicinfo = hs.json.decode(musicBody)
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
					if lyricRaw.lrc then
						lyric = lyricRaw.lrc.lyric
						lyricTable = Lyric.edit(lyric)
					end
				end
				if lyricTable then
					lyricTimer = hs.timer.new(1, function() 
						a = lineNO
						Lyric.show(a,lyricTable)
						b = stayTime or 1
						lyricTimer:setNextTrigger(b + lyricTimeOffset)
					end):start()
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
				hour = 0
				min = tonumber(stringSplit(time, ":")[1])
				if min > 59 then
					hour = min // 60
					min = min - 60 * hour
				end
				sec = stringSplit(time, ":")[2]
				minisec = stringSplit(time, ":")[3] or 0
				time = hs.timer.seconds(hour .. ":" .. min .. ":" .. sec) + minisec / 1000
				lyricLine["index"] = l
				lyricLine["time"] = time
				lyricLine["lyric"] = info
				table.insert(lyricTable, lyricLine)
			end
		end
	end
	return lyricTable
end
-- 显示歌词
Lyric.show = function(startline,lyric)
	if not lyric then
		return
	end
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
				stayTime = 1
				lineNO = l
			end
		end
	end
	-- 仅播放状态下显示
	if Music.state() == "playing" then
		Lyric.setcanvas()
		if not lyricTimer then
			Lyric.main()
		end
		if not c_lyric:isShowing() then
			show(c_lyric)
		end
		lyricTimer:start()
	elseif Music.state() == "paused" then
		hide(c_lyric)
		lyricTimer:stop()
	else
		delete(c_lyric)
		lyricTimer:stop()
		lyricTimer = nil
	end
	-- 歌词刷新
	if currentLyric ~= lyrictext then
		c_lyric["lyric"].text = currentLyric
		lyrictext = currentLyric
		-- 设置歌词图层自适应宽度
		lyricSize = c_lyric:minimumTextSize(2, c_lyric["lyric"].text)
		c_lyric["background"].frame.y = c_lyric:frame().h - lyricSize.h - gap.y
		c_lyric["background"].frame.h = lyricSize.h
		c_lyric["lyric"].frame.y = c_lyric:frame().h - lyricSize.h - gap.y
		c_lyric["lyric"].frame.h = lyricSize.h
	end
end
-- 建立歌词图层
Lyric.setcanvas = function() 
	if not c_lyric then
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
	end
end

-- 歌词图层初始化
Lyric.setcanvas()
-- 歌词显示与隐藏快捷键
hotkey.bind(hyper_cs, "l", function()
    if c_lyric then
        if not c_lyric:isShowing() then
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
        delete(c_lyric)
		lyricTimer:stop()
    else
		Lyric.setcanvas()
        Lyric.main()
	end
end)