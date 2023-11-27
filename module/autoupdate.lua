local cmdArr = {
    "cd ~/.hammerspoon && git pull",
}
function shell(cmd)
    result = as.applescript(string.format('do shell script "%s"', cmd))
end
function runAutoScripts()
    for key, cmd in ipairs(cmdArr) do
        shell(cmd)
    end
    hs.reload()
end
-- 每天 12 点检查一遍更新
hs.timer.doAt('12:00', hs.timer.days(1), runAutoScripts):start()
-- 手动触发快捷键
hotkey.bind(hyper_coc, 'u', runAutoScripts)
