-- 判断是否为全屏窗口
function getGoodFocusedWindow(nofull)
    local currentWin = win.focusedWindow()
    if not currentWin or not currentWin:isStandard() then return end
    if nofull and currentWin:isFullScreen() then return end
    return currentWin
end

-- 跳转至指定桌面
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
function moveWindowOneSpace_origin(dir,switch)
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

-- workaround方案
local hse, hsee, hst = hs.eventtap, hs.eventtap.event, hs.timer

function moveWindowOneSpace(dir,switch)
   local currentWin = getGoodFocusedWindow(true)
   if not currentWin then return end
   local screen=currentWin:screen()
   local uuid=screen:getUUID()
   local userSpaces=nil
   for k,v in pairs(spaces.allSpaces()) do
      userSpaces=v
      if k==uuid then break end
   end
   if not userSpaces then return end

   for i, spc in ipairs(userSpaces) do
      if spaces.spaceType(spc)~="user" then -- skippable space
	 table.remove(userSpaces, i)
      end
   end
   if not userSpaces then return end

   local initialSpace = spaces.windowSpaces(currentWin)
   if not initialSpace then return else initialSpace=initialSpace[1] end
   local currentCursor = hs.mouse.getRelativePosition()

   if (dir == "right" and initialSpace == userSpaces[#userSpaces]) or
      (dir == "left" and initialSpace == userSpaces[1]) then
      flashScreen(screen)   -- End of Valid Spaces
   else
      local zoomPoint = hs.geometry(currentWin:zoomButtonRect()) 
      local safePoint = zoomPoint:move({-1,-1}).topleft
      hsee.newMouseEvent(hsee.types.leftMouseDown, safePoint):post()
      switchSpace(1, dir)
      hst.waitUntil(
	 function () return spaces.windowSpaces(currentWin)[1]~=initialSpace end,
	 function ()
	    hsee.newMouseEvent(hsee.types.leftMouseUp, safePoint):post()
	    hs.mouse.setRelativePosition(currentCursor)
      end, 0.05)
   end
end


hotkey.bind(hyper_cc, "right", nil, function() moveWindowOneSpace("right",true) end)
hotkey.bind(hyper_cc, "left", nil, function() moveWindowOneSpace("left",true) end)