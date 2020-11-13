-- 设置
logger = hs.logger.new("config", "verbose")
hs.alert.defaultStyle.strokeColor = { white = 0, alpha = 0.75 }
hs.alert.defaultStyle.textSize = 25
-- hs.application.enableSpotlightForNameSearches(true)
-- 启动或激活App
function launchApp(basicKey, object)
  hs.hotkey.bind(basicKey, object.key, function() 
      hs.application.launchOrFocus(object.app)
      local application = hs.application.get(object.app)
      if application ~= nil then
          local window = application:focusedWindow()
          -- if window ~= nil then
            -- moveToCenterOfWindow(window)
          -- end
      end
  end)
end
-- App快捷键设置
hs.fnutils.each({
  { key = "`", app = "Finder" },
  { key = "s", app = "Safari" },
  { key = "m", app = "Music" },
  { key = "w", app = "WeChat" },
  { key = "q", app = "QQ" },
}, function(object)
  launchApp(keymap, object)
end)


