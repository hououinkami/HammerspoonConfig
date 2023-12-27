---------------
-- 歌词设置项
---------------
-- 歌词字体大小
lyricTextSize = 28
-- 歌词中文日文字体
lyricTextFont = "WeibeiSC-Bold"
-- 歌词英文数字字体
lyricTextFont2 = "Apple-Chancery"
-- 歌词刷新时间偏移量
lyricTimeOffset = -0.5
-- 背景颜色（RGB）
lyricbgColor = {35, 37, 34}
-- 背景透明度
lyricbgAlpha = 0
-- 歌词颜色（RGB）
lyricTextColor = {0, 120, 255}
-- 阴影颜色（RGB）
lyricShadowColor = {0, 0, 0}
-- 阴影透明度
lyricShadowAlpha = 1/3
-- 阴影模糊度
lyricShadowBlur = 3.0
-- 阴影偏移量
lyricShadowOffset = {h = -1.0, w = 1.0}
-- 0为关闭描边, 负数为描边, 正数为用字体颜色描边空心
lyricStrokeWidth = 0
-- 描边颜色
lyricStrokeColor = {1, 1, 1}
-- 描边透明度
lyricStrokeAlpha = 1
-- 本地化
lyricString = {
    enable = "歌詞モジュールの適用",
    show = "歌詞の表示",
    search = "検索結果の候補",
    error = "歌詞をエラーとしてマーク",
    delete = "歌詞ファイルを削除して再検索"
}
-- 粉色歌词
if not string.find(owner,"Kami") then
    lyricTextColor = {189, 138, 189}
    lyricString = {
        enable = "启用歌词模块",
        show = "显示歌词",
        search = "候选结果",
        error = "标记错误歌词",
        delete = "删除歌词文件并重新搜索"
    }
end
-- 歌词黑名单
blackList = {
    "作曲",
    "作词",
    "编曲",
    "作詞",
    "編曲",
    "曲：",
    "歌：",
    "歌手："
}
-- 本地歌词文件存储路径
lyricPath = HOME .. "/Music/Lyrics/"