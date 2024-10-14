-- 判断是否为全屏窗口
function getGoodFocusedWindow(nofull)
    local currentWin = win.focusedWindow()
    if not currentWin or not currentWin:isStandard() then return end
    if nofull and currentWin:isFullScreen() then return end
    return currentWin
end

function getValidFocusedWindow()
    local currentWin = win.focusedWindow()
    if not currentWin or not currentWin:isStandard() then 
        return 
    end
    if currentWin:isFullScreen() then 
        return 
    end
    return currentWin
 end 

-- 将窗口直接移动至指定ID桌面
local throwToSpace = function(currentWin, spaceIdx)
    local spacesIds = getSpacesIdsTable()
    local spaceId = spacesIds[spaceIdx]
    spaces.moveWindowToSpace(currentWin:id(), spaceId)
end
-- 跳转至指定桌面（配合上一函数使用）
function switchSpace(skip,dir)
    for i=1,skip do
       hs.eventtap.keyStroke({"ctrl","fn"},dir,0) -- "fn" is a bugfix!
    end 
end
-- 闪屏函数
function flashScreen(screen)
    local flash=c.new(screen:fullFrame()):appendElements({
      action = "fill",
      fillColor = { alpha = 0.25, blue=1},
      type = "rectangle"
    })
    flash:show()
    hs.timer.doAfter(.15,function () 
        flash = nil
        collectgarbage()
    end)
end

-- 在左右桌面间移动窗口
function moveWindowOneSpace(dir,switch)
    local currentWin = getGoodFocusedWindow(true)
    if not currentWin then 
        return 
    end
    local screen=currentWin:screen()
    local uuid=screen:getUUID()
    local userSpaces=nil
    for k,v in pairs(spaces.allSpaces()) do
        userSpaces=v
        if k==uuid then
            break
        end
    end
    if not userSpaces then 
        return 
    end
    local thisSpace=spaces.windowSpaces(currentWin)
    if not thisSpace then 
        return 
    else 
        thisSpace=thisSpace[1] 
    end
    local last=nil
    local skipSpaces=0
    for _, spc in ipairs(userSpaces) do
        if spaces.spaceType(spc)~="user" then
            skipSpaces = skipSpaces + 1
        else
            if last and ((dir=="left"  and spc==thisSpace) or (dir=="right" and last==thisSpace)) then
                local newSpace=(dir=="left" and last or spc)
                if switch then
                    -- spaces.gotoSpace(newSpace)  -- also possible, invokes MC
                    switchSpace(skipSpaces+1,dir)
                end
                spaces.moveWindowToSpace(currentWin,newSpace)
                return
            end
            last=spc
            skipSpaces=0
        end 
    end
    flashScreen(screen)
end

-- 按mission control的顺序获取桌面ID
local getSpacesIdsTable = function()
    local spacesLayout = spaces.allSpaces()
    local spacesIds = {}
    hs.fnutils.each(hs.screen.allScreens(), function(screen)
        local spaceUUID = screen:getUUID()
        local userSpaces = hs.fnutils.filter(spacesLayout[spaceUUID], function(spaceId)
        return spaces.spaceType(spaceId) == "user"
        end)
        hs.fnutils.concat(spacesIds, userSpaces or {})
    end)
    return spacesIds
end

-- 在左右桌面间移动窗口
function moveWindowOneSpace2(dir,switch)
    local currentWin = getGoodFocusedWindow(true)
    if not currentWin then 
        return 
    end
    local screen=currentWin:screen()
    local uuid=screen:getUUID()
    local userSpaces=nil
    for k,v in pairs(spaces.allSpaces()) do
        userSpaces=v
        if k==uuid then
            break
        end
    end
    if not userSpaces then 
        return 
    end
    local thisSpace=spaces.windowSpaces(currentWin)
    if not thisSpace then 
        return 
    else 
        thisSpace=thisSpace[1] 
    end
    local last=nil
    local skipSpaces=0
    for _, spc in ipairs(userSpaces) do
        if spaces.spaceType(spc)~="user" then
            skipSpaces = skipSpaces + 1
        else
            if last and ((dir=="left"  and spc==thisSpace) or (dir=="right" and last==thisSpace)) then
                local newSpace=(dir=="left" and last or spc)

                local newMouseEvent = hs.eventtap.event.newMouseEvent
                local leftMouseDown = hs.eventtap.event.types.leftMouseDown
                local leftMouseDragged = hs.eventtap.event.types.leftMouseDragged
                local leftMouseUp = hs.eventtap.event.types.leftMouseUp
                local start_point    = currentWin:frame()
                start_point.x        = start_point.x + start_point.w // 2
                start_point.y        = start_point.y + 4

                local end_point      = screen:frame()
                local window_gap     = 8
                end_point.x          = end_point.x + end_point.w // 2
                end_point.y          = end_point.y + window_gap + 4

                local do_window_drag = coroutine.wrap(function()
                    -- drag window half way there
                    start_point.x = start_point.x + ((end_point.x - start_point.x) // 2)
                    start_point.y = start_point.y + ((end_point.y - start_point.y) // 2)
                    newMouseEvent(leftMouseDragged, start_point):post()
                    coroutine.yield(false) -- not done

                    -- finish drag and release
                    newMouseEvent(leftMouseUp, end_point):post()

                    -- wait until window registers as on the new space
                    repeat
                        coroutine.yield(false) -- not done
                    until spaces.windowSpaces(currentWin)[1] == newSpace
                    
                    return true -- done
                end)

                -- pick up window, switch spaces, wait for space to be ready, drag and drop window, wait for window to be ready
                newMouseEvent(leftMouseDown, start_point):post()
                spaces.gotoSpace(newSpace)
                local start_time = timer.secondsSinceEpoch()
                timer.doUntil(do_window_drag, function(aTimer)
                        if timer.secondsSinceEpoch() - start_time > 4 then
                            aTimer:stop()
                        end
                    end,
                    win.animationDuration)
                -- 原有方案
                -- if switch then
                --     -- spaces.gotoSpace(newSpace)  -- also possible, invokes MC
                --     switchSpace(skipSpaces+1,dir)
                -- end
                -- spaces.moveWindowToSpace(currentWin,newSpace)
                return
            end
            last=spc
            skipSpaces=0
        end 
    end
    flashScreen(screen)
end

hotkey.bind(hyper_cc, "right", nil, function() moveWindowOneSpace2("right",true) end)
hotkey.bind(hyper_cc, "left", nil, function() moveWindowOneSpace2("left",true) end)