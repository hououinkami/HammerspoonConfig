c = require("hs.canvas")
function setCanvas()
    a = c.new{x = 100, y = 100, w = 200, h = 200 }
    a[1] = {
        type="image",
        -- the Hammerspoon menu icon has this name within the Application bundle, so we can get it this way:
        image = hs.image.imageFromName("statusicon"):template(false),
        imageScaling = "scaleToFit"
    }
    a[2] = {
        type = "rectangle",
        action = "fill",
        fillGradientColors = {
            { red = 1 },
            { red = 1, green = .65 },
            { red = 1, green = 1 },
            { green = 1 },
            { blue = 1 },
            { red = .30, blue = .5 },
            { red = .93, green = .5, blue = .93 }
        },
    fillGradient = "radial"
    }
end
function togglecanvas()
    if a:isShowing() == true then
        a:hide(0.6)
    else
        a:show(0.6)
    end
end
setCanvas()
testBar = hs.menubar.new()
testBar:setTitle('TEST')
testBar:setClickCallback(togglecanvas)