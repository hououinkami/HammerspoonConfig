-- 删除短信
function delMes()
    local appObj = win.focusedWindow():application()
    appObj:selectMenuItem({"ファイル", "チャットを削除…"})
    as.applescript([[tell application "System Events" to tell process "Messages" to tell button "削除" of sheet 1 of window 1 to perform action "AXPress"]])
end
hotkey.bind(hyper_opt, "delete", delMes)