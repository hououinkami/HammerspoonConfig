--------**--------
-- 变量设置
--------**--------
win.animationDuration = 0
local resizeStep = 20
local winhistory = {}
local winhistoryMap = {}
local windowWatcher = {}
local newWindowWatcher = {}

-- 缓存常用函数，避免重复查找
local focusedWindow = win.focusedWindow

--------**--------
-- 窗口管理核心
--------**--------
-- 记录窗口初始位置
local function windowStash(window)
    local winid = window:id()
    if winhistoryMap[winid] then return end -- 避免重复记录
    
    local winf = window:frame()
    if #winhistory >= 50 then
        local removed = table.remove(winhistory, 1)
        winhistoryMap[removed[1]] = nil
        -- 批量重新索引，提升性能
        for i, record in ipairs(winhistory) do
            winhistoryMap[record[1]] = i
        end
    end
    
    local winstru = {winid, winf}
    table.insert(winhistory, winstru)
    winhistoryMap[winid] = #winhistory
end

-- 窗口元数据
local windowMeta = {}
function windowMeta.new()
    local window = focusedWindow()
    if not window then return nil end
    
    local screen = window:screen()
    return {
        window = window,
        id = window:id(),
        currentScreenFrame = screen:frame(),
        windowFrame = window:frame()
    }
end

-- 处理有问题的App窗口
local function changeFocusedWindowDimensions(action)
    local window = focusedWindow()

    if not window then return end

    local app = window:application()
    local ax_app = hs.axuielement.applicationElement(app)

    local was_enhanced = ax_app.AXEnhancedUserInterface
    local original_animation_duration = win.animationDuration

    if was_enhanced then
        ax_app.AXEnhancedUserInterface = false
        win.animationDuration = 0
        action(window)
        
        ax_app.AXEnhancedUserInterface = was_enhanced
        win.animationDuration = original_animation_duration
    else
        action(window)
    end
end

-- 平滑调节窗口大小
local function resizeWindow(window, dir, step)
    local frame = window:frame()
    local max = window:screen():frame()
    
    -- 使用查找表替代多个if-elseif
    local resizeActions = {
        right = function() frame.w = frame.w + step end,
        left = function() frame.w = frame.w - step end,
        up = function() frame.h = frame.h - step end,
        down = function() frame.h = frame.h + step end
    }
    
    if resizeActions[dir] then
        resizeActions[dir]()
    end
    
    -- 边界检查
    frame.x = math.max(frame.x, max.x)
    frame.y = math.max(frame.y, max.y)
    frame.w = math.min(frame.w, max.w)
    frame.h = math.min(frame.h, max.h)
    
    window:move(frame)
end

--------**--------
-- 主要窗口调节函数
--------**--------
function pushCurrent(x, y, w, h)
    local this = windowMeta.new()
    if not this then return end
    
    windowStash(this.window)

    -- 使用查找表优化字符串匹配
    local actions = {
        center = function()
            this.window:move({
                (this.currentScreenFrame.w - this.windowFrame.w) / 2, 
                (this.currentScreenFrame.h - this.windowFrame.h) / 2, 
                this.windowFrame.w, 
                this.windowFrame.h
            })
        end,
        fullscreen = function() this.window:toggleFullScreen() end,
        reset = function()
            local winid = this.id
            for i = #winhistory, 1, -1 do -- 反向查找，最近的记录在后面
                if winhistory[i][1] == winid then
                    changeFocusedWindowDimensions(function(window)
                        window:setFrame(winhistory[i][2])
                    end)
                    break
                end
            end
        end,
        toleft = function()
            if this.windowFrame.x > 0 then
                this.window:move({0, (this.currentScreenFrame.h - this.windowFrame.h) / 2, this.windowFrame.w, this.windowFrame.h})
            else
                this.window:moveOneScreenWest()
            end
        end,
        toright = function()
            if this.windowFrame.x + this.windowFrame.w < this.currentScreenFrame.w then
                this.window:move({this.currentScreenFrame.w - this.windowFrame.w, (this.currentScreenFrame.h - this.windowFrame.h) / 2, this.windowFrame.w, this.windowFrame.h})
            else
                this.window:moveOneScreenEast()
            end
        end,
        toup = function()
            if this.windowFrame.y > 0 then
                this.window:move({this.windowFrame.x, 0, this.windowFrame.w, this.windowFrame.h})
            else
                this.window:moveOneScreenNorth()
            end
        end,
        todown = function()
            if this.windowFrame.y + this.windowFrame.h < this.currentScreenFrame.h then
                this.window:move({this.windowFrame.x, this.currentScreenFrame.h + 22.5 - this.windowFrame.h, this.windowFrame.w, this.windowFrame.h})
            else
                this.window:moveOneScreenSouth()
            end
        end,
        reLeft = function() resizeWindow(this.window, "left", resizeStep) end,
        reRight = function() resizeWindow(this.window, "right", resizeStep) end,
        reUp = function() resizeWindow(this.window, "up", resizeStep) end,
        reDown = function() resizeWindow(this.window, "down", resizeStep) end
    }

    if type(x) == "number" then
        changeFocusedWindowDimensions(function(window)
            window:move({
                this.currentScreenFrame.x + (this.currentScreenFrame.w * x), 
                this.currentScreenFrame.y + (this.currentScreenFrame.h * y), 
                this.currentScreenFrame.w * w, 
                this.currentScreenFrame.h * h
            })
        end)
    elseif actions[x] then
        actions[x]()
    end
end

-- 撤销功能
function Undo()
    local cwin = focusedWindow()
    if not cwin then return end
    
    local cwinid = cwin:id()
    -- 反向查找最新记录
    for i = #winhistory, 1, -1 do
        if winhistory[i][1] == cwinid then
            cwin:setFrame(winhistory[i][2])
            break
        end
    end
end

--------**--------
-- 快捷键绑定
--------**--------
local function windowsManagement(hyperkey, keyFuncTable, holding)
    for key, fn in pairs(keyFuncTable) do
        if holding then
            hotkey.bind(hyperkey, key, fn, nil, fn)
        else
            hotkey.bind(hyperkey, key, fn)
        end
    end
end

-- 快捷键配置（保持原有不变）
windowsManagement(hyper_oc, {
    left = function() pushCurrent(0, 0, 1/2, 1) end,
    right = function() pushCurrent(1/2, 0, 1/2, 1) end,
    up = function() pushCurrent(0, 0, 1, 1/2) end,
    down = function() pushCurrent(0, 1/2, 1, 1/2) end, 
    c = function() pushCurrent("center") end,
    ["return"] = function() pushCurrent(0, 0, 1, 1) end,
    ["delete"] = function() pushCurrent("reset") end,
}, true)

windowsManagement(hyper_co, {
    left = function() pushCurrent("toleft") end,
    right = function() pushCurrent("toright") end,
    up = function() pushCurrent("toup") end,
    down = function() pushCurrent("todown") end,
    c = function() pushCurrent("center") end,
    ["return"] = function() pushCurrent(0, 0, 1, 1) end,
}, false)

--------**--------
-- App窗口布局
--------**--------
local layouts = {
    {
        name = {"Safari"},
        func = function(index, win) pushCurrent("fullscreen") end
    },
    {
        name = {"WeChat"},
        func = function(index, win)
            local frame = win:screen():frame()
            win:move({ frame.w / 2, (frame.h - win:frame().h) / 2, frame.w / 2, win:frame().h })
        end
    },
    {
        name = {"Telegram"},
        func = function(index, win)
            local frame = win:screen():frame()
            win:move({ 0, (frame.h - win:frame().h) / 2, frame.w / 2, win:frame().h })
        end
    },
}

-- 应用窗口布局
function applyLayout(layouts, app)
    if not app then return end
    
    local appName = app:title()
    
    for _, layout in ipairs(layouts) do
        local names = type(layout.name) == "table" and layout.name or {layout.name}
        
        for _, layAppName in ipairs(names) do
            if layAppName == appName and layout.func then
                local wins = app:allWindows()
                local counter = 1
                
                for _, win in ipairs(wins) do
                    if win:isVisible() then
                        layout.func(counter, win)
                        counter = counter + 1
                    end
                end
                return
            end
        end
    end
end

-- 手动布局快捷键
hotkey.bind(hyper_ctrl, "`", function() 
    local win = focusedWindow()
    if win then
        applyLayout(layouts, win:application()) 
    end
end)

--------**--------
-- App监听器
--------**--------
local function windowWatcherListener(element, event, watcher, userData) 
    local app = app.find(userData.name)
    if app then
        applyLayout(layouts, app)
    end
end

local function applicationWatcher(appName, eventType, appObject)
    -- 预定义位置配置
    local appPositions = {
        QQ = { 20, 160 },
        WeChat = { 810, 140 },
        Telegram = { 20, 140 }
    }
    
    if eventType == app.watcher.activated then
        local pos = appPositions[appName]
        if pos and appObject:focusedWindow() then
            local win = appObject:focusedWindow()
            win:move({ pos[1], pos[2], win:frame().w, win:frame().h })
        elseif appName == "" and appObject:focusedWindow() and appObject:focusedWindow():title() then
            appObject:setFrontmost(true)
        end
    elseif eventType == app.watcher.launched then
        hs.timer.doAfter(0.5, function()
            applyLayout(layouts, appObject)
        end)
        
        for _, aname in ipairs(newWindowWatcher) do
            if appName == aname and not windowWatcher[aname] then
                windowWatcher[aname] = appObject:newWatcher(windowWatcherListener, { name = appName })
                windowWatcher[aname]:start({hs.uielement.watcher.windowCreated})
                break
            end
        end
    elseif eventType == app.watcher.terminated then  
        for _, aname in ipairs(newWindowWatcher) do
            if appName == aname and windowWatcher[aname] then
                windowWatcher[aname]:stop()
                windowWatcher[aname] = nil
                break
            end
        end
    end
end

-- 调试信息快捷键
hotkey.bind(hyper_coc, ".", function()
    local win = focusedWindow()
    if not win then return end
    
    local app = win:application()
    local info = app:path() .. "\n" .. app:name() .. "\n" .. 
                hs.keycodes.currentSourceID() .. "\n" .. win:title() .. "\n" .. app:bundleID()
    
    hs.pasteboard.setContents(app:path())
    hs.alert.show("App Path: " .. app:path() .. "\nApp Name: " .. app:name() .. 
                 "\nIME Source ID: " .. hs.keycodes.currentSourceID() .. 
                 "\nWindow Title: " .. win:title() .. "\nApp Bundle ID: " .. app:bundleID())
end)

-- appWatcherForresize = app.watcher.new(applicationWatcher)
-- appWatcherForresize:start()