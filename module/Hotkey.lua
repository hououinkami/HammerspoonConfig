local hotkey = require "hs.hotkey"
local window = require "hs.window"
-- 删除短信
function delMes()
    local appObj = window.focusedWindow():application()
    appObj:selectMenuItem({"ファイル", "チャットを削除…"})
    hs.osascript.applescript([[tell application "System Events" to tell process "Messages" to tell button "削除" of sheet 1 of window 1 to perform action "AXPress"]])
end
hs.hotkey.bind({"option"}, "delete", delMes)