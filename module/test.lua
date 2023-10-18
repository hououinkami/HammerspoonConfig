win = require("hs.window")
c = require("hs.canvas")
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
windowsControl()