---------------------
-- Music菜单栏设置项
---------------------
-- 播放中图标
playIcon = '♫'
-- 暂停图标
pauseIcon = '❙ ❙'
-- 停止图标
stopIcon = '◼'
-- 菜单栏标题的间隔字符
gaptext = "｜"
-- 淡入淡出时间
fadetime = 0.6
-- 显示时间
staytime = 2
-- 刷新时间
updatetime = 0.5
-- 专辑封面显示尺寸
artworksize = {h = 200, w = 200}
-- 边框尺寸
border = {x = 10, y = 10}
-- 项目之间的间隔
gap = {x = 10, y = 10}
-- 默认最小尺寸
smallsize = 600
-- 悬浮菜单字体大小
textsize = 20
-- 菜单图标大小
imagesize = {h = 15, w = 15}
-- 背景颜色（RGB）
bgColor = {35, 37, 34}
-- 背景透明度
bgAlpha = 0.96
-- 菜单背景默认颜色（RGB）
menubgColor = {35, 37, 34}
-- 菜单背景透明度
menubgAlpha = 0.96
-- 菜单背景选中颜色（RGB）
menubgColorS = {127.5, 127.5, 127.5}
-- 菜单背景选中透明度
menubgAlphaS = 0.8
-- 菜单字体默认颜色（RGB）
menuTextColor = {255, 255, 255}
-- 菜单字体选中颜色（RGB）
menuTextColorS = {232, 68, 79}
-- 菜单边框颜色（RGB）
menuStrokeColor = {255, 255, 255}
-- 菜单边框透明度
menuStrokeAlpha = 0.8
-- 进度条颜色
progressColor = {185, 185, 185}
-- Apple Music红
AMRed = {232, 68, 79}
AMBlue = {0, 120, 255}
-- 进度条透明度
progressAlpha = 0.6
-- 浅色模式
if not darkMode then
-- 背景颜色（RGB）
	bgColor = {255, 255, 255}
-- 菜单背景默认颜色（RGB）
	menubgColor = {255, 255, 255}
-- 菜单字体默认颜色（RGB）
	menuTextColor = {0, 0, 0}
-- 菜单边框颜色（RGB）
	menuStrokeColor = {0, 0, 0}
-- 进度条颜色
	progressColor = {35, 37, 34}
end
-- 本地化适配
if string.find(owner,"Kami") or string.find(owner,"カミ") then
	MusicApp = "ミュージック"
	Stopped = "停止中"
	ClicktoRun = '起動していない'
	MusicLibrary = "ライブラリ"
	localFile = "AACオーディオファイル"
	connectingFile = "接続中…"
	streamingFile = "インターネットオーディオストリーム"
	genius = "Genius"
	unknowTitle = "未知"
	station = "ステーション"
-- Edit here for other languages!
else
	MusicApp = "音乐"
	Stopped = "已停止"
	ClicktoRun = '未启动'
	MusicLibrary = "资料库"
	localFile = "AAC音频文件"
	connectingFile = "正在连接…"
	streamingFile = "互联网音频流"
	genius = "妙选"
	unknowTitle = "未知"
	station = "电台"
end