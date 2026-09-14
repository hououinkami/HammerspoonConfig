require ('module.utils') 
require ('module.apple-music') 
require ('module.Lyric') 
require ('config.music')

_G.cachedMusicInfo = {
    -- 音乐信息
    title = "",
    artist = "",
    album = "",
	duration = 0,
    position = 0,
    state = "stopped",
    loved = false,
    rating = 0,
    shuffle = false,
    loop = "off",
	kind = "applemusic",
    existInLibrary = false,
    
    -- 应用状态管理
    isRunning = false,
    spaceID = nil,
    lastUpdate = 0,

	-- 旧值存储
	_prevTitle = "",
	_prevAlbum = "",
}

-- 全局进度条状态管理
local progressState = {
	isUpdating = false,
	lastPosition = 0,
	lastDuration = 0,
	lastUpdateTime = 0
}

-- 判断是否为Tahoe及以上系统
local IS_TAHOE_PLUS = hs.host.operatingSystemVersion().major >= 26

-- 是否接收过通知的标志
local hasReceivedNotification = false

-- 事件监听器集合
eventListeners = {}

-- 图片缓存表
local imageCache = {}

-- 图片加载函数（懒加载 + 缓存）
local function loadImage(name)
    if not imageCache[name] then
        local path = hs.configdir .. "/image/" .. name .. ".png"
        local image = img.imageFromPath(path)
        if image then
            imageCache[name] = image:setSize(imageSize, absolute == true)
        else
            -- 加载失败时打印警告，避免静默出错
            print("⚠️ 图片加载失败: " .. path)
            return nil
        end
    end
    return imageCache[name]
end

-- 预加载所有已知图片（在 imageSize 确定后调用）
local function preloadImages()
    local imageNames = {
        -- 喜爱状态
        "loved_true",
        "loved_false",
        -- 随机播放
        "shuffle_true",
        "shuffle_false",
        -- 循环模式
        "loop_off",
        "loop_one",
        "loop_all",
        -- 星级评分
        "0star", "1star", "2star", "3star", "4star", "5star",
        -- 添加到库
        "added_true",
        "added_false",
    }
    for _, name in ipairs(imageNames) do
        loadImage(name)  -- 触发加载并缓存
    end
    print("✅ 图片预加载完成，共 " .. #imageNames .. " 张")
end

-- 清空缓存（imageSize 变化时调用）
local function clearImageCache()
    imageCache = {}
    print("🗑️ 图片缓存已清空")
end

-- 重新加载缓存
local function reloadImageCache()
    clearImageCache()
    preloadImages()
end

--
-- Color Server 渐变背景模块 --
--
local COLOR_SERVER = nil
local ok = pcall(require, 'module.secret')
if ok and myDomain then
	COLOR_SERVER = "https://color." .. myDomain
end

-- 当前渐变颜色缓存（避免每次重建菜单都请求）
local gradientCache = {
    background = {alpha = 0.95, red = bgColor[1]/255, green = bgColor[2]/255, blue = bgColor[3]/255},
    midground  = {alpha = 0.7,  red = bgColor[1]/255, green = bgColor[2]/255, blue = bgColor[3]/255},
    highlight  = {alpha = 0.4,  red = bgColor[1]/255, green = bgColor[2]/255, blue = bgColor[3]/255},
	bgImage    = nil,
    lastAlbum  = "",   -- 记录上次请求的专辑，避免重复请求
    isReady    = false -- 标记颜色是否已从服务获取
}

-- 异步获取渐变颜色
local function fetchGradientColors(imageObj, callback)
	if not COLOR_SERVER then
		return
	end
	
    -- imageObj 可能是路径字符串，也可能是 hs.image 对象
    local b64

    local imgObj
	if type(imageObj) == "string" then
        -- 是文件路径
        imgObj = hs.image.imageFromPath(imageObj)
	else
		imgObj = imageObj
	end
	
	if not imgObj then
		print("⚠️ 封面图片加载失败: " .. tostring(imageObj))
		callback(nil)
		return
	end

    if type(imgObj) == "userdata" then
		-- 先缩小避免超限
		local imgObj = imgObj:setSize({w=150, h=150})
        -- 是 hs.image 对象，直接编码为 JPEG base64
		local dataURL = imgObj:encodeAsURLString(true)
		-- 返回的前缀是 "data:image/png;base64,..."
		b64 = dataURL:match("base64,(.+)$")
    else
        print("⚠️ 未知的图片类型: " .. type(imgObj))
        callback(nil)
        return
    end

	if not b64 then
		print("⚠️ base64 提取失败")
		callback(nil)
		return
	end

    local payload = hs.json.encode({
        type  = "base64",
        image = b64,
    })

    httpRequest(
		"POST",
		COLOR_SERVER .. "/gradient",
		{ ["Content-Type"] = "application/json" },
		payload,
        function(code, body, headers)
            if code == 200 then
                local ok, data = pcall(hs.json.decode, body)
                if ok and data then
                    callback(data)
                else
                    print("⚠️ 颜色解析失败: " .. tostring(body))
                    callback(nil)
                end
            else
                print("⚠️ Color Server 请求失败, code=" .. tostring(code))
                callback(nil)
            end
        end,
		5
    )
end

-- 异步获取模糊背景图片
local function fetchBlurBackground(imageObj, width, height, callback)
    if not myDomain then callback(nil) return end

    local imgObj
    if type(imageObj) == "string" then
        imgObj = hs.image.imageFromPath(imageObj)
    else
        imgObj = imageObj
    end

    if not imgObj then
        callback(nil)
        return
    end

    local imgObj = imgObj:setSize({w = 150, h = 150})
    local dataURL = imgObj:encodeAsURLString(true)
    local b64 = dataURL:match("base64,(.+)$")

    if not b64 then
        callback(nil)
        return
    end

    local payload = hs.json.encode({
        type   = "base64",
        image  = b64,
        width  = math.floor(width),
        height = math.floor(height),
        blur   = blurRadius or 20,
        darken = blurDarken or 0.5,
    })

	httpRequest(
		"POST",
		COLOR_SERVER .. "/blur_bg",
		{ ["Content-Type"] = "application/json" },
		payload,
        function(code, body)
            if code == 200 then
                local ok, data = pcall(hs.json.decode, body)
                if ok and data and data.image then
					-- 解码 base64
                    local imgData = hs.base64.decode(data.image)
                    local bgImage = hs.image.imageFromURL(
                        "data:image/png;base64," .. hs.base64.encode(imgData)
                    )
                    callback(bgImage)
                else
                    callback(nil)
                end
            else
                print("⚠️ blur_bg 请求失败, code=" .. tostring(code))
                callback(nil)
            end
        end,
		5
    )
end

-- 将渐变颜色应用到已存在的 c_mainMenu
local function applyGradientToMenu()
    if not c_mainMenu then return end
    if not c_mainMenu["background"] then return end

	-- 先同步 clip 尺寸
    if c_mainMenu["bg_clip"] then
        c_mainMenu["bg_clip"].frame = {x = 0, y = 0, w = menuFrame.w, h = menuFrame.h}
    end

	-- 如果有模糊背景图片，优先用图片
    if gradientCache.bgImage and useBlurBackground then
		-- 同步更新 clip 区域的尺寸
        c_mainMenu["background"].type  = "image"
        c_mainMenu["background"].image = gradientCache.bgImage
        c_mainMenu["background"].imageScaling = "scaleToFit"
        -- 图片模式下隐藏渐变层（可选，避免叠加）
        if c_mainMenu["gradient_mid"] then
            c_mainMenu["gradient_mid"].fillGradientColors = {
                {alpha=0, red=0, green=0, blue=0},
                {alpha=0, red=0, green=0, blue=0}
            }
        end
        if c_mainMenu["gradient_hi"] then
            c_mainMenu["gradient_hi"].fillGradientColors = {
                {alpha=0, red=0, green=0, blue=0},
                {alpha=0, red=0, green=0, blue=0}
            }
        end
        return
    end

    -- 降级：用渐变色
	local bg  = gradientCache.background
    local mid = gradientCache.midground
    local hi  = gradientCache.highlight

    -- 只更新颜色，不追加元素
	c_mainMenu["background"].type      = "rectangle"
    c_mainMenu["background"].action    = "fill"
    c_mainMenu["background"].image     = nil   -- ← 清除残留图片
    c_mainMenu["background"].frame     = {     -- ← 补上 frame
        x = 0, y = 0,
        w = menuFrame.w,
        h = menuFrame.h
    }
    c_mainMenu["background"].fillColor = bg

    if c_mainMenu["gradient_mid"] then
        c_mainMenu["gradient_mid"].fillGradientColors = {
            mid,
            {alpha=0, red=mid.red, green=mid.green, blue=mid.blue}
        }
    end

    if c_mainMenu["gradient_hi"] then
        c_mainMenu["gradient_hi"].fillGradientColors = {
            {alpha=0.35, red=hi.red, green=hi.green, blue=hi.blue},
            {alpha=0,    red=hi.red, green=hi.green, blue=hi.blue}
        }
    end
end

-- 当专辑变化时调用
function updateGradientBackground(imageObj)
    -- 同一张专辑不重复请求
	local cacheKey = (cachedMusicInfo.title or "") .. "|" .. (cachedMusicInfo.album or "")
    if gradientCache.lastAlbum == cacheKey and gradientCache.isReady then
        applyGradientToMenu()
        return
    end

    -- 先用旧颜色渲染，避免白屏等待
    applyGradientToMenu()

    -- 异步请求新颜色（始终请求，作为降级备用）
    fetchGradientColors(imageObj, function(data)
        if not data then return end

        -- 更新缓存
        gradientCache.background = data.background or gradientCache.background
        gradientCache.midground  = data.midground  or gradientCache.midground
        gradientCache.highlight  = data.highlight  or gradientCache.highlight
        gradientCache.lastAlbum  = cacheKey
        gradientCache.isReady    = true

        -- 只有没有图片时才用渐变色渲染
        if not gradientCache.bgImage then
            applyGradientToMenu()
        end
    end)

	-- 异步请求模糊背景图片
    if menuFrame and useBlurBackground then
        fetchBlurBackground(imageObj, menuFrame.w, menuFrame.h, function(bgImage)
            if not bgImage then return end
            gradientCache.bgImage = bgImage
            gradientCache.lastAlbum = cacheKey
            gradientCache.isReady = true
            applyGradientToMenu()
        end)
    end
end

--
-- MenuBar函数集 --
--
-- 创建菜单栏标题
function setTitle(quitMark)
	-- 定义菜单栏文本
	local maxLen = 500
	if quitMark == "quit" then
		menubarIcon = playIcon
		menubarTitle = ClicktoRun
	elseif cachedMusicInfo.state == "playing" then
		menubarIcon = playIcon
		-- 使用缓存数据检查连接状态
		if cachedMusicInfo.title == connectingFile then
			menubarTitle = connectingFile
		else
			local title = cachedMusicInfo.title or ""
			local artist = cachedMusicInfo.artist or ""
			menubarTitle = title .. gapText .. artist
		end
	elseif cachedMusicInfo.state == "paused" then
		menubarIcon = pauseIcon
		local title = cachedMusicInfo.title or ""
		local artist = cachedMusicInfo.artist or ""
		menubarTitle = title .. gapText .. artist
	elseif cachedMusicInfo.state == "stopped" then
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
		if countWords(menubarIcon .. ' ' .. cachedMusicInfo.title) < maxLen then
			titleShown = menubarIcon .. ' ' .. cachedMusicInfo.title
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

    -- 初始化时给barFrame.x赋值
    if not barFrame.x or barFrame.x <= 0 then
        barFrame.x = 1000
    end

	-- 修复：正确计算菜单位置，确保不超出屏幕
	local menuWidth = smallSize

	-- 先尝试在菜单栏图标下方显示
	local menuX = barFrame.x

	-- 如果会超出屏幕右侧，则向左调整
	if menuX + menuWidth > Config.screenFrame.x + Config.screenFrame.w then
		menuX = Config.screenFrame.x + Config.screenFrame.w - menuWidth - 10
	end

	-- 如果会超出屏幕左侧，则向右调整
	if menuX < Config.screenFrame.x then
		menuX = Config.screenFrame.x + 10
	end

	-- 框架尺寸
	if not c_mainMenu then
		c_mainMenu = c.new({
			x = menuX, 
			y = barFrame.y + barFrame.h + 5, 
			h = artworkSize.h + borderSize.y * 2, 
			w = menuWidth
		}):level(c.windowLevels.cursor)
	end

	-- 直接使用缓存数据，避免重复调用
	local title = cachedMusicInfo.title or Music.title()
	local artist = cachedMusicInfo.artist or Music.artist()
	local album = cachedMusicInfo.album or Music.album()
	
	c_mainMenu:replaceElements(
		{-- 圆角裁剪区域
			id = "bg_clip",
			type = "rectangle",
			action = "clip",
			frame = {x = 0, y = 0, h = artworkSize.h + borderSize.y * 2, w = menuWidth},
			roundedRectRadii = {xRadius = 6, yRadius = 6},
		},{-- 背景
			id = "background",
			type = "rectangle",
			action = "fill",
			roundedRectRadii = {xRadius = 6, yRadius = 6},
			fillColor = {alpha = bgAlpha, red = bgColor[1] / 255, green = bgColor[2] / 255, blue = bgColor[3] / 255},
			-- trackMouseEnterExit = true,
			trackMouseUp = true
		}, {-- 重置裁剪（必须在所有背景元素之后、内容元素之前）
			id = "bg_clip_reset",
			type = "resetClip",
		},{-- 中层渐变
			id = "gradient_mid",
			type  = "rectangle",
			action = "fill",
			roundedRectRadii = {xRadius = 6, yRadius = 6},
			fillGradient = "linear",
			fillGradientColors = {
				{alpha=0.7, red=bgColor[1]/255, green=bgColor[2]/255, blue=bgColor[3]/255},
				{alpha=0,   red=bgColor[1]/255, green=bgColor[2]/255, blue=bgColor[3]/255}
			},
			fillGradientAngle = 60,
		},
		{-- 高光渐变
			id = "gradient_hi",
			type  = "rectangle",
			action = "fill",
			roundedRectRadii = {xRadius = 6, yRadius = 6},
			fillGradient = "radial",
			fillGradientColors = {
				{alpha=0.35, red=bgColor[1]/255, green=bgColor[2]/255, blue=bgColor[3]/255},
				{alpha=0,    red=bgColor[1]/255, green=bgColor[2]/255, blue=bgColor[3]/255}
			},
			fillGradientCenter = {x=0.85, y=0.15},
		},{-- 专辑封面
			id = "artwork",
			frame = {x = borderSize.x, y = borderSize.y, h = artworkSize.h, w = artworkSize.w},
			type = "image",
			image = Music._artworkCache.image or img.imageFromPath(hs.configdir .. "/image/NoArtwork.png"),
			trackMouseEnterExit = true,
			trackMouseUp = true
		}, {-- 专辑信息
			id = "info",
			frame = {x = borderSize.x + artworkSize.w + gapSize.x, y = borderSize.y, h = artworkSize.h, w = 100},
			type = "text",
			text = title .. "\n\n" .. artist .. "\n\n" .. album .. "\n",
			textSize = textSize,
			textColor = {
				alpha = menuTextAlpha,
				red   = menuTextColor[1] / 255,
				green = menuTextColor[2] / 255,
				blue  = menuTextColor[3] / 255
			},
			textLineBreak = "wordWrap",
			trackMouseEnterExit = true,
			trackMouseUp = true
		}
	)
	-- 设置悬浮菜单自适应宽度
	infoSize = c_mainMenu:minimumTextSize(7, c_mainMenu["info"].text)
	local defaultSize = infoSize.w + artworkSize.w + borderSize.x * 2 + gapSize.x
	if defaultSize < smallSize then
		defaultSize = smallSize
	end
	menuFrame = {x = barFrame.x, y = barFrame.h + gapSize.y / 2, h = artworkSize.h + 2 * borderSize.y, w = defaultSize}
	if defaultSize > Config.screenFrame.w - barFrame.x - gapSize.x / 2 and defaultSize < Config.screenFrame.w - gapSize.x then
		menuFrame.x = Config.screenFrame.w - gapSize.x / 2 - defaultSize
	elseif defaultSize > Config.screenFrame.w - gapSize.x then
		menuFrame.x = Config.screenFrame.x + gapSize.x / 2
		menuFrame.w = Config.screenFrame.w - gapSize.x
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
			if eventListeners.progressTimer then
				eventListeners.progressTimer:stop()
			end
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
		c_desktopLayer = c.new(Config.screenFrame):level(c.windowLevels.popUpMenu)
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
	local musicKind = cachedMusicInfo.kind or "applemusic"

	-- 图片设置函数 - 使用缓存数据
	local loveImage = function()
		local lovedState = cachedMusicInfo and cachedMusicInfo.loved or false
		return loadImage("loved_" .. tostring(lovedState))
	end

	local rateImage = function()
		local rating = math.tointeger(cachedMusicInfo and cachedMusicInfo.rating or 0) or 0
		return loadImage(rating .. "star")
	end
	
	-- 生成菜单框架和菜单项目
	if musicKind == "applemusic" or musicKind == "radio" then
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
			-- 喜爱按钮处理
			if id == "loved" and (y > c_rateMenu["loved"].frame.y and y < c_rateMenu["loved"].frame.y + c_rateMenu["loved"].frame.h) and event == "mouseUp" then
				if x > c_rateMenu["loved"].frame.x and x < c_rateMenu["loved"].frame.x + c_rateMenu["loved"].frame.w then
					Music.toggleLoved()
					refreshRatingDisplay()
				end
			end
		end
	elseif musicKind == "localmusic" then
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
			if id == "background" and event == "mouseUp" and y > imageSize.h and x > imageSize.w * 0.2 and x < c_rateMenu["rate"].frame.w / 5 * 1 then
				Music.setRating(0)
				refreshRatingDisplay()
			end
			if id == "rate" and event == "mouseUp" and y < imageSize.h then
				local newRating = nil
				if x > imageSize.w * 0.2 and x < c_rateMenu["rate"].frame.w / 5 * 1 then
					newRating = 1
				elseif x > c_rateMenu["rate"].frame.w / 5 * 1 and x < c_rateMenu["rate"].frame.w / 5 * 2 then
					newRating = 2
				elseif x > c_rateMenu["rate"].frame.w / 5 * 2 and x < c_rateMenu["rate"].frame.w / 5 * 3 then
					newRating = 3
				elseif x > c_rateMenu["rate"].frame.w / 5 * 3 and x < c_rateMenu["rate"].frame.w / 5 * 4 then
					newRating = 4
				elseif x > c_rateMenu["rate"].frame.w / 5 * 4 and x < c_rateMenu["rate"].frame.w / 5 * 5 then
					newRating = 5
				end
				
				if newRating then
					Music.setRating(newRating)
					refreshRatingDisplay()
				end
			end
		end
	elseif musicKind == "matched" then
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
					refreshRatingDisplay()
				end
			end
			if id == "background" and event == "mouseUp" and y > imageSize.h and x > imageSize.w * 1.2 and x < c_rateMenu["rate"].frame.w / 5 * 1 + imageSize.w then
				Music.setRating(0)
				refreshRatingDisplay()
			end
			if id == "rate" and event == "mouseUp" and y < imageSize.h then
				local newRating = nil
				if x > imageSize.w * 1.2 and x < c_rateMenu["rate"].frame.w / 5 * 1 + imageSize.w then
					newRating = 1
				elseif x > c_rateMenu["rate"].frame.w / 5 * 1 + imageSize.w and x < c_rateMenu["rate"].frame.w / 5 * 2 + imageSize.w then
					newRating = 2
				elseif x > c_rateMenu["rate"].frame.w / 5 * 2 + imageSize.w and x < c_rateMenu["rate"].frame.w / 5 * 3 + imageSize.w then
					newRating = 3
				elseif x > c_rateMenu["rate"].frame.w / 5 * 3 + imageSize.w and x < c_rateMenu["rate"].frame.w / 5 * 4 + imageSize.w then
					newRating = 4
				elseif x > c_rateMenu["rate"].frame.w / 5 * 4 + imageSize.w and x < c_rateMenu["rate"].frame.w / 5 * 5 + imageSize.w then
					newRating = 5
				end
				
				if newRating then
					Music.setRating(newRating)
					refreshRatingDisplay()
				end
			end
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

-- 刷新评价显示
function refreshRatingDisplay()
    if not c_rateMenu then
        return
    end
    
    -- 清除缓存并获取最新信息
    Music.clearCache()

	-- 保留应用状态字段
	mergeMusicInfo(Music.getCachedInfo())
    
    -- 更新喜爱状态图像
    if c_rateMenu["loved"] then
        local loveImage = loadImage("loved_" .. tostring(cachedMusicInfo.loved))
        c_rateMenu["loved"].image = loveImage
    end
    
    -- 更新星级评价图像
    if c_rateMenu["rate"] then
        c_rateMenu["rate"].image = loadImage(math.tointeger(cachedMusicInfo.rating) .. "star")
    end
end

-- 设置播放控制悬浮菜单项目
function setControlMenu()
    local musicKind = cachedMusicInfo.kind or "applemusic"

    -- 图片设置函数 - 使用缓存数据
    local shuffleImage = function()
        local shuffleState = cachedMusicInfo and cachedMusicInfo.shuffle or false
        return loadImage("shuffle_" .. tostring(shuffleState))
    end
    
    local loopImage = function()
        local loopState = cachedMusicInfo and cachedMusicInfo.loop or "off"
        return loadImage("loop_" .. loopState)
    end
    
    local addedImage = function()
        local isExist = "true"
        if musicKind == "applemusic" or musicKind == "radio" then
            isExist = tostring(cachedMusicInfo and cachedMusicInfo.existInLibrary or false)
        end
        return loadImage("added_" .. isExist)
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
    
    -- 鼠标行为 - 统一处理所有控制按钮
    c_controlMenu:mouseCallback(function(canvas, event, id, x, y)
        if event ~= "mouseUp" then
            return
        end
        
        local needsRefresh = false
        
        if id == "shuffle" then
            Music.toggleShuffle()
            needsRefresh = true
        elseif id == "loop" then
            Music.toggleLoop()
            needsRefresh = true
        elseif id == "playlist" then
            -- 确保歌曲在库中
            if not Music.existInLibrary() then
                Music.addToLibrary()
            end
            
            -- 处理播放列表菜单显示/隐藏
            if not c_playlist then
                setPlaylistMenu()
                show(c_playlist)
            elseif c_playlist then
                if not c_playlist:isShowing() then
                    show(c_playlist)
                else
                    hide(c_playlist)
                end
            end
            needsRefresh = true
        end
        
        -- 如果有状态变化，刷新控制按钮显示
        if needsRefresh then
            refreshDisplay(0.15)
        end
    end)
end
-- 刷新控制按钮显示
function refreshDisplay(delayTime)
	delayTime = delayTime or 0
    
	local function doUpdate()
		-- 清除缓存并获取最新信息
		Music.clearCache()
		
		-- 更新缓存信息并保留应用状态字段
		mergeMusicInfo(Music.getCachedInfo())

		if c_controlMenu then
			-- 更新随机播放按钮
			if c_controlMenu["shuffle"] then
				c_controlMenu["shuffle"].image = loadImage("shuffle_" .. tostring(cachedMusicInfo.shuffle))
			end
			
			-- 更新循环播放按钮
			if c_controlMenu["loop"] then
				c_controlMenu["loop"].image = loadImage("loop_" .. cachedMusicInfo.loop)
			end
			
			-- 更新播放列表按钮
			if c_controlMenu["playlist"] then
				local isExist = (cachedMusicInfo.kind == "applemusic" or cachedMusicInfo.kind == "radio")
					and tostring(cachedMusicInfo.existInLibrary or false)
					or "true"
				c_controlMenu["playlist"].image = loadImage("added_" .. isExist)
			end
		end

		if c_rateMenu then
			-- 更新喜爱状态图像
			if c_rateMenu["loved"] then
				local loveImage = loadImage("loved_" .. tostring(cachedMusicInfo.loved))
				c_rateMenu["loved"].image = loveImage
			end
			
			-- 更新星级评价图像
			if c_rateMenu["rate"] then
				c_rateMenu["rate"].image = loadImage(math.tointeger(cachedMusicInfo.rating) .. "star")
			end
		end
	end
    
	if delayTime > 0 then
        hs.timer.doAfter(delayTime, doUpdate)
    else
        doUpdate()
    end
end

-- 播放列表悬浮菜单
function setPlaylistMenu()
	-- 获取播放列表名称
	local playlistName = Music.tell('name of every user playlist whose smart is false and special kind is none')

	-- 获取播放列表个数
	local playlistCount = #playlistName
	if playlistCount == 0 then
        print("⚠️ 没有可用的播放列表")
        return
    end

	-- 一次性获取当前曲目所在的所有播放列表，用于本地比对
    local currentTrackPlaylists = Music.tell('name of playlists of current track') or {}
    -- 转换为 set（哈希表），O(1) 查询替代 N 次 AS 调用
    local inPlaylistSet = {}
    if type(currentTrackPlaylists) == "table" then
        for _, name in ipairs(currentTrackPlaylists) do
            inPlaylistSet[name] = true
        end
    end

    -- 用 table.concat 在 Lua 侧拼接测宽字符串，不再需要第3次 AS 调用
    local testText = table.concat(playlistName, "\n")

	-- 框架尺寸
	controlMenuFrame = c_controlMenu:frame()
	playlistFrame = {x = controlMenuFrame.x + c_controlMenu["playlist"].frame.x + c_controlMenu["playlist"].frame.w / 2, y = controlMenuFrame.y + c_controlMenu["playlist"].frame.y + c_controlMenu["playlist"].frame.h / 2, h = textSize * playlistCount, w = smallSize}
	if not c_playlist then
		c_playlist = c.new(playlistFrame):level(c_mainMenu:level() + 1)
	else
		c_playlist:frame(playlistFrame)
	end

	-- 设置菜单宽度
	local styledText = hs.styledtext.new(testText, {
		font = { size = textSize }
	})
	playlistMenuSize = c_playlist:minimumTextSize(styledText)
	playlistFrame = {
		x = playlistFrame.x,
		y = playlistFrame.y,
		h = playlistMenuSize.h + borderSize.y * playlistCount,
		w = playlistMenuSize.w + borderSize.x * 2
	}
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

	-- 菜单项目: 用 inPlaylistSet 本地查询，不再循环调用 AS
	local count = 1
	repeat
		local textColor
        if not inPlaylistSet[playlistName[count]] then
            textColor = {
                red   = menuTextColor[1] / 255,
                green = menuTextColor[2] / 255,
                blue  = menuTextColor[3] / 255
            }
        else
            textColor = {
                red   = menuTextColorS[1] / 255,
                green = menuTextColorS[2] / 255,
                blue  = menuTextColorS[3] / 255
            }
        end
		
		c_playlist:appendElements(
			{-- 菜单项背景
				id = "playlistback" .. count,
				frame = {
					x = 0,
					y = playlistFrame.h / playlistCount * (count - 1),
					h = playlistFrame.h / playlistCount,
					w = playlistFrame.w
				},
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
				frame = {
					x = borderSize.x,
					y = borderSize.y * (count - 0.5) + playlistMenuSize.h / playlistCount * (count - 1),
					h = playlistMenuSize.h / playlistCount,
					w = playlistMenuSize.w
				},
				type = "text",
				text = playlistName[count],
				textSize = textSize,
				textColor = textColor,
				textLineBreak = "wordWrap",
				trackMouseEnterExit = true,
				trackMouseUp = true
			}
		)
		c_playlist:appendElements(
			{-- 菜单项overlay
				id = "playlistoverlay" .. count,
				frame = {
					x = 0,
					y = playlistFrame.h / playlistCount * (count - 1),
					h = playlistFrame.h / playlistCount,
					w = playlistFrame.w
				},
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
		local i = 1
		repeat
			if id == "playlistoverlay" .. i then
                if event == "mouseEnter" then
                    c_playlist["playlistback" .. i].fillColor = {
                        alpha = menubgAlphaS,
                        red   = menubgColorS[1] / 255,
                        green = menubgColorS[2] / 255,
                        blue  = menubgColorS[3] / 255
                    }
                elseif event == "mouseExit" then
                    if x > borderSize.x and x < playlistFrame.w - borderSize.x
                        and y > borderSize.y and y < playlistFrame.h - borderSize.y then
                        c_playlist["playlistback" .. i].fillColor = {
                            alpha = menubgAlpha,
                            red   = menubgColor[1] / 255,
                            green = menubgColor[2] / 255,
                            blue  = menubgColor[3] / 255
                        }
                    else
                        hide(c_playlist)
                    end
                elseif event == "mouseUp" then
                    Music.addToPlaylist(playlistName[i])
                    hide(c_playlist)
                    
                    if cachedMusicInfo.kind == "applemusic" or cachedMusicInfo.kind == "radio" then
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

-- 进度条更新函数
function setProgressCanvas()
	local per = 60 / 100
	local musicDuration = cachedMusicInfo and cachedMusicInfo.duration or 0
	
	if musicDuration <= 0 then
		musicDuration = math.huge
	end
	
	-- 使用缓存的当前位置
	local currentPos = cachedMusicInfo and cachedMusicInfo.position or 0
	local progressWidth = 0
	if musicDuration > 0 and musicDuration ~= math.huge then
		progressWidth = currentPos / musicDuration
	end
	
	-- 创建或更新进度条画布
	if not c_progress then
		c_progress = c.new({
			x = menuFrame.x + borderSize.x, 
			y = menuFrame.y + borderSize.y + artworkSize.h + borderSize.y * (1 - per) / 2, 
			h = borderSize.y * per, 
			w = menuFrame.w - borderSize.x * 2
		}):level(c_mainMenu:level() + 2)
	else
		-- 更新画布位置和大小
		c_progress:frame({
			x = menuFrame.x + borderSize.x, 
			y = menuFrame.y + borderSize.y + artworkSize.h + borderSize.y * (1 - per) / 2, 
			h = borderSize.y * per, 
			w = menuFrame.w - borderSize.x * 2
		})
	end
	
	-- 重新定义进度条元素（确保每次都是新的引用）
	progressElement = {
		{
			id = "progress",
			type = "rectangle",
			roundedRectRadii = {xRadius = 2, yRadius = 2},
			frame = {
				x = 0, 
				y = 0, 
				h = c_progress:frame().h, 
				w = c_progress:frame().w * progressWidth
			},
			fillColor = {
				alpha = progressAlpha, 
				red = progressColor[1] / 255, 
				green = progressColor[2] / 255, 
				blue = progressColor[3] / 255
			},
			trackMouseUp = true
		},
		{
			id = "background",
			type = "rectangle",
			action = "fill",
			roundedRectRadii = {xRadius = 6, yRadius = 6},
			fillColor = {
				alpha = 0, 
				red = bgColor[1] / 255, 
				green = bgColor[2] / 255, 
				blue = bgColor[3] / 255
			},
			trackMouseUp = true
		}
	}
	
	-- 应用元素到画布
	c_progress:replaceElements(progressElement)
	
	-- 设置鼠标回调
	c_progress:mouseCallback(function(canvas, event, id, x, y)
		if event == "mouseUp" and id == "background" and 
			x >= 0 and x <= c_progress:frame().w and 
			y >= 0 and y <= c_progress:frame().h then
			
			-- 计算新的播放位置
			local duration = cachedMusicInfo and cachedMusicInfo.duration or 0
			if duration <= 0 then return end  -- 实时读取，永远是当前歌曲
			
			local newPosition = (x / c_progress:frame().w) * duration
			
			-- 设置新位置
			Music.tell('set player position to "' .. newPosition .. '"')
			
			-- 立即更新进度条显示
			progressElement[1].frame.w = x
			c_progress:replaceElements(progressElement)
			
			-- 更新状态
			progressState.lastPosition = newPosition
			progressState.lastUpdateTime = hs.timer.secondsSinceEpoch()

		end
	end)
end

--
-- 悬浮菜单功能函数集
--
-- 隐藏
function hideall()
    hide(c_desktopLayer)
    hide(c_rateMenu, fadeTime, true)
    hide(c_controlMenu, fadeTime, true)
    hide(c_progress, fadeTime, true)
    hide(c_playlist, fadeTime, true)
    hide(c_mainMenu, fadeTime, true)
    
    -- 隐藏时停止进度定时器以节省资源
    if eventListeners.progressTimer and eventListeners.progressTimer:running() then
        eventListeners.progressTimer:stop()
    end
end

-- 显示
function showall()
	show(c_mainMenu, fadeTime, true)
	show(c_rateMenu, fadeTime, true)
	show(c_controlMenu, fadeTime, true)
	
	-- 确保进度条是最新的
	if c_progress then
		-- 立即更新一次进度
		hs.timer.doAfter(0.1, function()
			updateProgressOnly()
		end)
		show(c_progress, fadeTime, true)
	end
	
	-- 确保进度条定时器在播放时运行 - 使用实际状态检查
	if cachedMusicInfo.state == "playing" and eventListeners.progressTimer then
		if not eventListeners.progressTimer:running() then
			eventListeners.progressTimer:start()
		end
	end
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

-- 修复的菜单构建函数
function buildMenus()
	-- 确保按正确顺序构建所有菜单组件
	setMainMenu()
	setRateMenu()
	setControlMenu()
	setProgressCanvas()
	applyGradientToMenu()
end

-- 修复的 toggleCanvas 函数
function toggleCanvas()
	local spaceID = hs.spaces.activeSpaces()[hs.screen.mainScreen():getUUID()]
	local toggleFunction = function ()
		local state = cachedMusicInfo.state
		if state == "playing" or state == "paused" then
			-- 确保菜单已构建
			if not c_mainMenu then
				buildMenus()
			end
			
			if c_mainMenu:isShowing() then
				hideall()
			else
				-- 重新构建菜单以确保数据是最新的
				-- buildMenus()
				showall()
				setDesktopLayer()
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

--
-- 事件驱动版本的音乐播放器模块
--
-- 初始化事件驱动系统
function initEventDrivenSystem()
	setupMusicNotifications()
	setupApplicationWatcher()
	setupSpaceWatcher()
	setupProgressTimer()
end

-- 1. 音乐应用通知监听
function setupMusicNotifications()
	eventListeners.musicNotification = hs.distributednotifications.new(function(name, object, userInfo)
		handleMusicNotification(name, object, userInfo)
	end, "com.apple.Music.playerInfo")
	
	if eventListeners.musicNotification then
		eventListeners.musicNotification:start()
	end
	
	-- Spotify 支持
	eventListeners.spotifyNotification = hs.distributednotifications.new(function(name, object, userInfo)
		handleSpotifyNotification(name, object, userInfo)
	end, "com.spotify.client.PlaybackStateChanged")
	
	if eventListeners.spotifyNotification then
		eventListeners.spotifyNotification:start()
	end
end

-- 处理音乐通知
function handleMusicNotification(name, object, userInfo)
    if not userInfo then return end

	-- 标记已收到通知
	hasReceivedNotification = true
    
    local currentTime = hs.timer.secondsSinceEpoch()
    -- 防抖：避免过于频繁的更新
    if currentTime - cachedMusicInfo.lastUpdate < 0.2 then
        return
    end

	-- 写入新值之前，先快照旧值
    cachedMusicInfo._prevTitle = cachedMusicInfo.title
    cachedMusicInfo._prevAlbum = cachedMusicInfo.album

	-- 从通知直接写入可靠字段
    if userInfo["Name"] then cachedMusicInfo.title = userInfo["Name"] end
    if userInfo["Artist"] then cachedMusicInfo.artist = userInfo["Artist"] end
    if userInfo["Album"] then cachedMusicInfo.album = userInfo["Album"] end
    if userInfo["Total Time"] then cachedMusicInfo.duration = userInfo["Total Time"] / 1000 end
	if userInfo["Rating"] then cachedMusicInfo.rating = userInfo["Rating"] / 20 end
	if userInfo["Store URL"] then cachedMusicInfo.storeURL = userInfo["Store URL"] end

    local state = userInfo["Player State"]
    if state then
        cachedMusicInfo.state = state == "Playing" and "playing"
                             or state == "Paused"  and "paused"
                             or "stopped"
    end

    -- kind：仅 applemusic 可准确判断，local/matched 保留原值
    if not userInfo["Location"] then
        cachedMusicInfo.kind = "applemusic"
	else
		cachedMusicInfo.kind = "matched"
    end

    -- 清理缓存以获取最新信息
    Music.clearCache()
    
    -- 延迟更新以合并多个通知
    debounce("musicUpdate", 0.1, function()
        musicBarUpdate()
    end)
    
    cachedMusicInfo.lastUpdate = currentTime
end

-- 防抖函数
local debounceTimers = {}
function debounce(key, delay, func)
    if debounceTimers[key] then
        debounceTimers[key]:stop()
    end
    
    debounceTimers[key] = hs.timer.doAfter(delay, function()
        func()
        debounceTimers[key] = nil
    end)
end

-- 处理 Spotify 通知
function handleSpotifyNotification(name, object, userInfo)
	local currentTime = hs.timer.secondsSinceEpoch()
	if currentTime - cachedMusicInfo.lastUpdate < 0.3 then
		return
	end
	
	local hasChanges = false
	
	-- 检查 Spotify 状态
	local isPlaying = hs.spotify.isPlaying()
	local newPlayState = isPlaying and "playing" or "paused"
	
	if newPlayState ~= cachedMusicInfo.state then
		cachedMusicInfo.state = newPlayState
		hasChanges = true
	end
	
	local currentTrack = hs.spotify.getCurrentTrack()
	if currentTrack and currentTrack ~= cachedMusicInfo.title then
		cachedMusicInfo.title = currentTrack
		hasChanges = true
	end
	
	local currentArtist = hs.spotify.getCurrentArtist()
	if currentArtist and currentArtist ~= cachedMusicInfo.artist then
		cachedMusicInfo.artist = currentArtist
		hasChanges = true
	end
	
	if hasChanges then
		cachedMusicInfo.lastUpdate = currentTime
		musicBarUpdate()
	end
end

-- 应用启动/退出监听
function setupApplicationWatcher()
    eventListeners.appWatcher = hs.application.watcher.new(function(appName, eventType, appObject)
        if appName == "Music" or appName == "Spotify" then
            if eventType == hs.application.watcher.launched then
                print("🎵 音乐应用启动: " .. appName)
                cachedMusicInfo.isRunning = true
                -- 延迟获取初始状态
                hs.timer.doAfter(1, function()
                    musicBarUpdate()
                end)
            elseif eventType == hs.application.watcher.terminated then
                print("⏹️ 音乐应用退出: " .. appName)
                cachedMusicInfo.isRunning = false
                setTitle("quit")
                hideall()
                -- 隐藏歌词并停止计时器
                if c_lyric then
                    hide(c_lyric)
                end
                if Lyric and Lyric.stopTimer then
                    Lyric.stopTimer()
                end
            end
        end
    end)
    
    -- 启动应用监听器
    if eventListeners.appWatcher then
        eventListeners.appWatcher:start()
    end
end

-- 空间切换监听
function setupSpaceWatcher()
	eventListeners.spaceWatcher = hs.spaces.watcher.new(function()
		local currentSpaceID = hs.spaces.activeSpaces()[hs.screen.mainScreen():getUUID()]
		if currentSpaceID ~= cachedMusicInfo.spaceID then
			cachedMusicInfo.spaceID = currentSpaceID
			hideall()
		end
	end)
	
	-- 启动空间监听器
	if eventListeners.spaceWatcher then
		eventListeners.spaceWatcher:start()
	end
end

-- 智能定时器设置
function setupProgressTimer()
    if eventListeners.progressTimer then
        eventListeners.progressTimer:stop()
        eventListeners.progressTimer = nil
    end
    
    -- 使用自适应间隔
    local timerInterval = 1.0
    
    eventListeners.progressTimer = hs.timer.new(timerInterval, function()
        
        -- 根据状态调整更新频率
        if cachedMusicInfo.state == "playing" and c_progress and c_progress:isShowing() then
            updateProgressOnly()
            -- 播放时保持1秒间隔
            if timerInterval ~= 1.0 then
                timerInterval = 1.0
                eventListeners.progressTimer:setNextTrigger(timerInterval)
            end
        else
            -- 非播放状态降低频率
            if timerInterval < 2.0 then
                timerInterval = 2.0
                eventListeners.progressTimer:setNextTrigger(timerInterval)
            end
        end
    end)
end

-- 进度更新函数
function updateProgressOnly()
    if not c_progress or not c_progress:isShowing() then
        return
    end
    
    -- 防止重复更新
    if progressState.isUpdating then
        return
    end
    
    local currentTime = hs.timer.secondsSinceEpoch()
    
    -- 如果刚刚手动调整过进度，给一点缓冲时间
    if currentTime - progressState.lastUpdateTime < 1.0 then
        return
    end
    
    progressState.isUpdating = true
    
    -- 实时获取当前播放位置（强制刷新）
    local currentPos = Music.currentPosition(true) -- 强制获取最新位置
    local duration = cachedMusicInfo and cachedMusicInfo.duration or Music.duration() or 0
    
    -- 验证数据有效性
    if duration <= 0 then
        progressState.isUpdating = false
        return
    end
    
    -- 防止进度超出范围
    currentPos = math.max(0, math.min(currentPos, duration))
    
    -- 计算进度条宽度
    local progressWidth = (currentPos / duration) * c_progress:frame().w
    progressWidth = math.max(0, math.min(progressWidth, c_progress:frame().w))
    
    -- 降低更新阈值，让进度条更流畅
    if math.abs(currentPos - progressState.lastPosition) > 0.3 then
        if progressElement and progressElement[1] then
            progressElement[1].frame.w = progressWidth
            c_progress:replaceElements(progressElement)
            
            progressState.lastPosition = currentPos
            progressState.lastDuration = duration
        end
    end
    
    progressState.isUpdating = false
end

-- 只更新菜单内容，不重建整个菜单
function updateMenuContent()
    if not c_mainMenu or not cachedMusicInfo then
        return
    end
    
    -- 更新文本信息
    local title = cachedMusicInfo.title or ""
    local artist = cachedMusicInfo.artist or ""
    local album = cachedMusicInfo.album or ""
    
    if c_mainMenu["info"] then
        c_mainMenu["info"].text = title .. "\n\n" .. artist .. "\n\n" .. album .. "\n"
    end
    
    -- 更新专辑封面（如果需要）
    if c_mainMenu["artwork"] and Music._artworkCache.image then
        c_mainMenu["artwork"].image = Music._artworkCache.image
    end
end

-- 更新缓存
function mergeMusicInfo(newInfo)
	-- 剔除通知字段后合并 AS 数据
	if infoFromNotification and hasReceivedNotification then
		if not newInfo then return end
		local notifKeys = { title=true, artist=true, album=true, duration=true, rating=true, state=true, kind=true }
		for k in pairs(notifKeys) do
			newInfo[k] = nil
		end
	end
	
	if not newInfo then return end
	
	for k, v in pairs(newInfo) do
        _G.cachedMusicInfo[k] = v
    end
    -- newInfo.isRunning  = _G.cachedMusicInfo.isRunning
    -- newInfo.spaceID    = _G.cachedMusicInfo.spaceID
    -- newInfo.lastUpdate = _G.cachedMusicInfo.lastUpdate
    -- _G.cachedMusicInfo = newInfo
end

-- 音乐状态更新函数
function musicBarUpdate()
    -- 检查应用是否运行
	if not cachedMusicInfo.isRunning then
		if not Music.checkRunning() then
			cachedMusicInfo.isRunning = false
			setTitle("quit")
			hideall()
			if c_lyric then
				hide(c_lyric)
			end
			-- 停止歌词计时器
			if Lyric and Lyric.stopTimer then
				Lyric.stopTimer()
			end
			if eventListeners.progressTimer then
				eventListeners.progressTimer:stop()
			end
			return
		else
			-- AS 确认还在运行，修正缓存
			cachedMusicInfo.isRunning = true
		end
	end
    
    cachedMusicInfo.isRunning = true

	-- 读取旧值（仅用于封面和歌词的判断）
    local prevTitle, prevAlbum, prevState

	if hasReceivedNotification then
		-- 通知模式：旧值在通知写入前已经快照到 _prev 字段
		prevTitle = cachedMusicInfo._prevTitle
		prevAlbum = cachedMusicInfo._prevAlbum
	else
		-- AS 模式：合并前读旧值
		prevTitle = cachedMusicInfo.title
		prevAlbum = cachedMusicInfo.album
	end
	prevState = cachedMusicInfo.state
    
    -- 获取并合并AS音乐信息
	mergeMusicInfo(Music.getCachedInfo())

	-- 变化检测
    local hasTrackChanged = prevTitle ~= cachedMusicInfo.title
    local hasAlbumChanged = prevAlbum ~= cachedMusicInfo.album
    local hasStateChanged = prevState ~= cachedMusicInfo.state
    local isInitializing  = not c_mainMenu  -- 菜单未建过，强制重建
    
    -- 更新菜单栏标题
    setTitle()
    
	 -- 下载歌词（仅在曲目变化时）
	if hasTrackChanged and Lyric and Lyric.main then
		Lyric.main()
	end
	
    if cachedMusicInfo.state == "playing" then
        -- 如果状态从暂停变为播放，恢复歌词计时器
		if Lyric and Lyric.resumeTimer then
            Lyric.resumeTimer()
        end
        
        -- 重建菜单（仅在必要时）
		if isInitializing or hasTrackChanged or hasAlbumChanged then
			buildMenus()
			progressState.lastPosition = 0
			progressState.lastDuration = 0
			progressState.lastUpdateTime = 0
        elseif hasStateChanged then
            -- 仅状态变化（暂停→播放）：只刷新图标
            refreshDisplay()
        end
        
        -- 启动进度条定时器
		if eventListeners.progressTimer and not eventListeners.progressTimer:running() then
			eventListeners.progressTimer:start()
		end
		
	elseif cachedMusicInfo.state == "paused" then
		-- 暂停状态隐藏歌词并暂停歌词计时器
		if c_lyric then
			hide(c_lyric)
		end
		if Lyric and Lyric.pauseTimer then
			Lyric.pauseTimer()
		end
		
		-- 保持菜单显示，但停止进度条更新
		if isInitializing or hasTrackChanged or hasAlbumChanged then
            buildMenus()
        elseif hasStateChanged then
            refreshDisplay()
        end
		
		-- 停止进度条定时器
		if eventListeners.progressTimer and eventListeners.progressTimer:running() then
			eventListeners.progressTimer:stop()
		end
        
    else
        -- 停止状态：隐藏所有内容
        hideall()
        if c_lyric then
            hide(c_lyric)
        end
        if Lyric and Lyric.stopTimer then
            Lyric.stopTimer()
        end
        if eventListeners.progressTimer then
            eventListeners.progressTimer:stop()
        end
        progressState.lastPosition = 0
        progressState.lastDuration = 0
        progressState.lastUpdateTime = 0
    end
	
	-- 保存专辑封面（仅在专辑变化时）
	if hasAlbumChanged or isInitializing then
		gradientCache.bgImage = nil
		gradientCache.isReady = false
		gradientCache.lastAlbum = ""
		Music.clearArtworkCache()  -- 清除旧缓存

		Music.fetchArtwork(function(image)
			if c_mainMenu and c_mainMenu["artwork"] then
				c_mainMenu["artwork"].image = image
			end
			if image then
				updateGradientBackground(image)
			end
		end)
	end
end

-- 清理事件监听器
function cleanupEventListeners()
	for name, listener in pairs(eventListeners) do
		if listener and listener.stop then
			listener:stop()
			print("🧹 已停止监听器: " .. name)
		end
	end
	eventListeners = {}
end

-- 修改后的初始化函数
function initMusicBar()
	-- 生成菜单栏
	if not MusicBar then
		MusicBar = hs.menubar.new(true)
		MusicBar:setClickCallback(toggleCanvas)
	end

	if MusicBar then
		initialX = MusicBar:frame().x
		firstIcon = initialX - 36
	end

	-- 预加载图标
    preloadImages()
	
	-- 初始化事件驱动系统
	initEventDrivenSystem()
	
	-- 获取初始状态
	cachedMusicInfo.spaceID = hs.spaces.activeSpaces()[hs.screen.mainScreen():getUUID()]
	
	-- 立即检查音乐状态并更新
	musicBarUpdate()
	
	-- 保留低频率备用定时器，但频率更合理
	if Switch then
		Switch:stop()
	end
	Switch = hs.timer.new(10, function()  -- 10秒检查一次
		if not cachedMusicInfo.isRunning and Music.checkRunning() then
			print("⚠️ 容错检查：检测到音乐应用运行")
			musicBarUpdate()
		end
	end)
	Switch:start()
end

-- 清理函数
function cleanup()
	cleanupEventListeners()
	if Switch then
		Switch:stop()
	end
	hideall()
	if c_lyric then
		hide(c_lyric)
	end
	-- 停止歌词计时器
	if Lyric and Lyric.stopTimer then
		Lyric.stopTimer()
	end
	print("🧹 音乐栏模块已清理")
end

-- 初始化
initMusicBar()

-- 保持原有快捷键
hotkey.bind(hyper_shift, 'return', Music.togglePlay)
-- HyperKey.bind(hyper_rshift, 'return', Music.togglePlay)
hotkey.bind(hyper_opt, 'right', function()
-- HyperKey.bind(hyper_ropt, 'right', function()
	if hs.spotify.isPlaying() then
		hs.spotify.next()
	else
		Music.next()
	end
end)
hotkey.bind(hyper_opt, 'left', function()
-- HyperKey.bind(hyper_ropt, 'left', function()
	if Music.currentPosition() < 5 then
		if hs.spotify.isPlaying() then
			hs.spotify.previous()
		else
			Music.previous()
		end
	else
		if hs.spotify.isPlaying() then
			hs.spotify.setPosition(0)
		else
			Music.tell('set player position to 0')
		end
	end
end)
-- HyperKey.bind(hyper_ropt, "up", function() setVolume("up") end, nil, function() setVolume("up") end)
-- HyperKey.bind(hyper_ropt, 'down', function() setVolume("down") end, nil, function() setVolume("down") end)
hotkey.bind(hyper_opt, 'up', function() setVolume("up") end, nil, function() setVolume("up") end)
hotkey.bind(hyper_opt, 'down', function() setVolume("down") end, nil, function() setVolume("down") end)