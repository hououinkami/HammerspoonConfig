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
-- 淡入淡出时间
lyricFadetime = 0.2
-- 本地化
lyricString = {
    enable = "歌詞モジュールの適用",
    show = "歌詞の表示",
    search = {
        "QQ音乐からの検索結果候補",
        "网易云音乐からの検索結果候補",
    },
    error = "歌詞をエラーとしてマーク",
    delete = "歌詞ファイルを削除して再検索",
    api = "歌詞検索のデフォルトAPI",
    reload = "歌詞モジュールをリロード",
    updateConfig = "Hammerspoonプロフィールを更新"
}
-- 粉色歌词
if not string.find(owner,"Kami") then
    lyricTextColor = {189, 138, 189}
    lyricString = {
        enable = "启用歌词模块",
        show = "显示歌词",
        search = {
            "来自QQ音乐的候选结果",
            "来自网易云音乐的候选结果",
        },
        error = "标记错误歌词",
        delete = "删除歌词文件并重新搜索",
        api = "歌词搜索默认API",
        reload = "重载歌词模块",
        updateConfig = "更新Hammerspoon配置"
    }
end
-- 歌词黑名单
blackList = {
    "作曲",
    "曲",
    "作詞",
    "作词",
    "詞",
    "词",
    "歌詞",
    "Lyric",
    "編曲",
    "编曲",
    "歌",
    "歌手",
    "制作人",
}
-- 本地歌词文件存储路径
lyricPath = HOME .. "/Music/Lyrics/"
-- 默认歌词搜索引擎（1: QQ音乐；2: 网易云音乐）
lyricDefaultNO = 1