require ('module.utils') 

-- 每天 12 点检查一遍更新
hs.timer.doAt('12:00', hs.timer.days(1), updateHammerspoon):start()
-- 手动触发快捷键
hotkey.bind(hyper_coc, 'u', updateHammerspoon)
