win = require("hs.window")
c = require("hs.canvas")
as = require("hs.osascript")
local wRe = 0.12
local hRe = 2 / 3
local gap = 10
-- 仿台前调度
function windowsControl()
	local allWindows = win.orderedWindows()
    local winCount = 0
    for i, v in ipairs(allWindows) do
        winCount = winCount + 1
    end
	local winSnap = {}
    screenframe = hs.screen.mainScreen():frame()
    background = c.new({x = screenframe.x, y = screenframe.h * hRe / 4, h = screenframe.h * hRe, w = screenframe.w * wRe}):level(c.windowLevels.cursor)
    background:replaceElements(
		{-- 背景
			id = "background",
			type = "rectangle",
			action = "fill",
			roundedRectRadii = {xRadius = 6, yRadius = 6},
			fillColor = {alpha = bgAlpha, red = bgColor[1] / 255, green = bgColor[2] / 255, blue = bgColor[3] / 255},
			trackMouseEnterExit = true,
			trackMouseUp = true
		}
    )
    snapHeight = (background:frame().h - (winCount + 1) * gap) / winCount
    count = 1
    for i, v in ipairs(allWindows) do
        background:appendElements(
            {
                id = v:id(),
                frame = {x = gap, y = gap * count + snapHeight * (count - 1), h = snapHeight, w = background:frame().w - 2 * gap},
                type = "image",
                image = win.snapshotForID(v:id()),
                trackMouseEnterExit = true,
                trackMouseUp = true
            }
        )
        count = count + 1
	end
    --background:show()
end
--windowsControl()




local screenfullframe = hs.screen.mainScreen():fullFrame()
local iconW,iconH = 120,110
local icongap = 5
local firstIconFrame = {x = screenfullframe.w * (1615 - 60 - icongap / 2) / 1680, y = screenfullframe.h * (30 - icongap / 2) / 1050, w = 120 + icongap, h = 110 + icongap}
local geticonpositionscript = [[
        tell application "Finder"
	        get desktop position of every item of desktop
        end tell
	]]
local _,iconPosition,_ = as.applescript(geticonpositionscript)
local geticoncountscript = [[
        tell application "Finder"
	        set i to index of every item of desktop
            get length of i
        end tell
	]]
local _,iconCount,_ = as.applescript(geticoncountscript)
local seticonvarscript = [[
        tell application "Finder"
            set iconvar to {}
            set i to index of every item of desktop
            repeat with v from 1 to (length of i)
                set end of iconvar to "icon" & v
            end repeat
            return iconvar
        end tell
	]]
local _,icon,_ = as.applescript(seticonvarscript)
count = 1
repeat
    icon[count] = c.new({x = iconPosition[count][1] - iconW / 2, y = iconPosition[count][2] - 35 * screenfullframe.h / 1050, h = iconH, w = iconW}):level(c.windowLevels.desktopIcon + 1):replaceElements(
        {-- 背景
            id = "icon" .. count,
            type = "rectangle",
            action = "fill",
            fillColor = {alpha = bgAlpha, red = bgColor[1] / 255, green = bgColor[2] / 255, blue = bgColor[3] / 255},
            trackMouseEnterExit = true,
            trackMouseUp = true
        }
    )
    --icon[count]:show()
    count = count + 1
until count > iconCount

