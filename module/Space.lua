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
                spaces.moveWindowToSpace(currentWin:id(), dir=="left" and last or spc)
                -- 获取下一个桌面的ID
                local spacesIds = getSpacesIdsTable()
                for i=1,5 do
                    if spacesIds[i] == (dir=="left" and last or spc) then
                        spaceID=i
                        break
                    end
                end
                -- hs.eventtap.keyStroke({"ctrl"},spaceID)
                -- 或
                -- spaces.changeToSpace(spaceID, false) -- 此方法会高概率导致菜单栏变色
                -- 以下方法可以直接跳转
                if spaceID == 1 then
                    hs.eventtap.keyStroke({"ctrl"},"1")
                elseif spaceID == 2 then
                    hs.eventtap.keyStroke({"ctrl"},"2")
                elseif spaceID == 3 then
                    hs.eventtap.keyStroke({"ctrl"},"3")
                elseif spaceID == 4 then
                    hs.eventtap.keyStroke({"ctrl"},"4")
                elseif spaceID == 5 then
                    hs.eventtap.keyStroke({"ctrl"},"5")
                elseif spaceID == 6 then
                    hs.eventtap.keyStroke({"ctrl"},"6")
                end
                currentWin:focus()
                return
            end
            last=spc
            skipSpaces=0
        end 
    end
    flashScreen(screen)
end

hotkey.bind(hyper_cc, "right", nil, function() moveWindowOneSpace("right",true) end)
hotkey.bind(hyper_cc, "left", nil, function() moveWindowOneSpace("left",true) end)