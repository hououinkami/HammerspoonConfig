local cmdArr = {
    "cd ~/.hammerspoon && git pull",
}
function shell(cmd)
    result = hs.osascript.applescript(string.format('do shell script "%s"', cmd))
end
function runAutoScripts()
    for key, cmd in ipairs(cmdArr) do
        shell(cmd)
    end
    hs.reload()
end
-- 定时触发自动更新
hs.timer.doWhile(function()
			return true
        end, runAutoScripts, 86400)
-- 手动触发快捷键
hs.hotkey.bind(Hyper, 'r', runAutoScripts)
