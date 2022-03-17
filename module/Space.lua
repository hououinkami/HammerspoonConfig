local spaces = require('hs._asm.undocumented.spaces')
local hotkey = require "hs.hotkey"
local window = require "hs.window"

-- 按mission control的顺序获取桌面ID
local getSpacesIdsTable = function()
    local spacesLayout = spaces.layout()
    local spacesIds = {}
    hs.fnutils.each(hs.screen.allScreens(), function(screen)
        local spaceUUID = screen:spacesUUID()
        local userSpaces = hs.fnutils.filter(spacesLayout[spaceUUID], function(spaceId)
        return spaces.spaceType(spaceId) == spaces.types.user
        end)
        hs.fnutils.concat(spacesIds, userSpaces or {})
    end)
    return spacesIds
end

-- 判断是否为全屏窗口
function getGoodFocusedWindow(nofull)
    local win = window.focusedWindow()
    if not win or not win:isStandard() then return end
    if nofull and win:isFullScreen() then return end
    return win
end

-- 将窗口直接移动至指定ID桌面
local throwToSpace = function(win, spaceIdx)
    local spacesIds = getSpacesIdsTable()
    local spaceId = spacesIds[spaceIdx]
    spaces.moveWindowToSpace(win:id(), spaceId)
end
-- 跳转至指定桌面（配合上一函数使用）
function switchSpace(skip,dir)
    for i=1,skip do
       hs.eventtap.keyStroke({"ctrl"},dir)
    end 
end
-- 闪屏函数
function flashScreen(screen)
    local flash=hs.canvas.new(screen:fullFrame()):appendElements({
      action = "fill",
      fillColor = { alpha = 0.25, red = 1 },
      type = "rectangle"})
    flash:show()
    hs.timer.doAfter(.15,function () destroyCanvasObj(flash,true) end)
 end

 -- 删除闪屏函数
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

-- 在左右桌面间移动窗口
function moveWindowOneSpace(dir,switch)
    local win = getGoodFocusedWindow(true)
    if not win then 
        return 
    end
    local screen=win:screen()
    local uuid=screen:spacesUUID()
    local userSpaces=nil
    for k,v in pairs(spaces.layout()) do
        userSpaces=v
        if k==uuid then
            break
        end
    end
    if not userSpaces then 
        return 
    end
    local thisSpace=win:spaces()
    if not thisSpace then 
        return 
    else 
        thisSpace=thisSpace[1] 
    end
    local last=nil
    local skipSpaces=0
    for _, spc in ipairs(userSpaces) do
        if spaces.spaceType(spc)~=spaces.types.user then
            skipSpaces = skipSpaces + 1
        else
            if last and ((dir=="left"  and spc==thisSpace) or (dir=="right" and last==thisSpace)) then

                -- 方案一
                -- 移动窗口
                win:spacesMoveTo(dir=="left" and last or spc)
                if switch then
                    switchSpace(skipSpaces+1,dir)
                    win:focus()
                end
                
                -- 方案二
                --spaces.moveWindowToSpace(win:id(), dir=="left" and last or spc)

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
                win:focus()

                return
            end
            last=spc
            skipSpaces=0
        end 
    end
    flashScreen(screen)
 end

mash = {"command", "control"}
hotkey.bind(mash, "right", nil, function() moveWindowOneSpace("right",false) end)
hotkey.bind(mash, "left", nil, function() moveWindowOneSpace("left",false) end)