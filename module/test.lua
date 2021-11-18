hs.window.animationDuration = 0
local screen = hs.window.focusedWindow():screen()
local w = screen:fullFrame().w
local h = screen:fullFrame().h
hs.grid.setGrid(w .. 'x' .. h, screen, screen:fullFrame())
local win = hs.window.focusedWindow()
mash = {"control", "shift"}
hs.hotkey.bind(mash, 'k', function() 
    hs.grid.adjustWindow(
    function(cell)
        cell.x = 0
        cell.y = 0
        cell.w = 10
        cell.h = 20
        return hs.grid
    end, window)
end)
hs.hotkey.bind(mash, 'j', function() 
    local currentSize = hs.grid.get(win)
    hs.grid.set(win,{currentSize.x,currentSize.y,currentSize.w+1,currentSize.h}, screen)
end)
hs.hotkey.bind(mash, 'l', function() hs.grid.pushWindowRight(win) end)
hs.hotkey.bind(mash, 'h', function() hs.grid.pushWindowLeft(win) end)