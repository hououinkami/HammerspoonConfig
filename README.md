# Hammerspoon-Config

## 安装、更新及重新加载（Install & Update & Reload）

### 安装（Install）

git clone https://github.com/hououinkami/HammerspoonConfig.git ~/.hammerspoon

### 更新（Update）

cd ~/.hammerspoon && git pull

### 重新加载（Reload）

<kbd>⌃</kbd> + <kbd>⌘</kbd> + <kbd>shift</kbd> + <kbd>R</kbd>

## Music悬浮菜单栏（Apple Music Canvas Menu）

![image](https://github.com/hououinkami/HammerspoonConfig/raw/main/image/README/Music.png)

1. 菜单栏显示当前正在播放的歌曲标题及艺术家, 显示长度会根据菜单栏空白空间自动调节

2. 单击后显示悬浮菜单，悬浮菜单长度根据歌曲名称长度自动调节

3. 点击悬浮菜单上的曲目信息跳转到Music对应曲目

4. 若为本地曲库中的歌曲，则显示“星级评价”图标，点击对应星级可以对歌曲进行评价，点击第一颗星底部附近可以取消星级评价

5. 若为Apple Music中的歌曲，则a显示“喜爱”图标，点击可以切换“喜爱”状态

6. 若为本地曲目上传后匹配了Apple Music曲库的歌曲，则同时显示“喜爱”和“星级评价”图标

7. 下方控制菜单包含随机状态切换、循环状态切换

8. 下方控制菜单“+”图标，若为Apple Music曲目，点击则为添加到本地曲库，添加成功后，图标将显示为红色；若为本地曲目或是已经添加到曲库中的Apple Music曲目，点击则弹出播放列表菜单，点击相应列表可将当前曲目添加到对应播放列表

9. 下方边缘为当前曲目进度条，点击相应位置可以跳转至对应位置播放

10. 鼠标移出悬浮菜单后自动隐藏，若没有正常触发隐藏，则当鼠标不在菜单栏文字或悬浮菜单范围内时一定时间后自动隐藏

## 桌面悬浮歌词（Desktop Canvas Lyrics）

![image](https://github.com/hououinkami/HammerspoonConfig/raw/main/image/README/Lyrics.png)

1. 与Music悬浮菜单栏模块配合使用，切换曲目时会自动从网易云音乐搜寻歌词

2. 歌词搜寻结果自动选择匹配度最高的歌词

3. 菜单栏上的歌词图标可以从候选结果中手动选择想要匹配的歌词

4. 若为本地曲库中的歌曲或是标记了“喜爱”的歌曲，会将歌词保存为本地文件，保存路径为~/Music/Lyrics（可在配置文件中更改）

5. 歌词配置项（/config/lyric.lua）单独分离出来，可以随时更改随时生效，无需重载配置

6. 菜单栏上的歌词图标可以控制歌词模块是否启用、是否显示桌面歌词、标记错误歌词、删除本地歌词文件


## 类Spotlight搜索（SpotlightLike Search）

<kbd>⌥</kbd> + <kbd>Space</kbd>

![image](https://github.com/hououinkami/HammerspoonConfig/raw/main/image/README/SpotlightLike.png)

1. 实时调用并显示DuckDuckGO的搜索建议

2. 默认使用Google搜索

3. 点击工具栏对应图标则将选用对应搜索引擎搜索当前高亮关键词


## 窗口管理（Windows Manage）

左半屏幕：<kbd>⌃</kbd> + <kbd>⌥</kbd> + <kbd>◀︎</kbd>

右半屏幕：<kbd>⌃</kbd> + <kbd>⌥</kbd> + <kbd>►</kbd>

上半屏幕：<kbd>⌃</kbd> + <kbd>⌥</kbd> + <kbd>▲</kbd>

下半屏幕：<kbd>⌃</kbd> + <kbd>⌥</kbd> + <kbd>▼</kbd>

维持原大小左边贴到桌面左边缘：<kbd>⌃</kbd> + <kbd>⌥</kbd> + <kbd>⌘</kbd> + <kbd>◀︎</kbd>

维持原大小右边贴到桌面右边缘：<kbd>⌃</kbd> + <kbd>⌥</kbd> + <kbd>⌘</kbd> + <kbd>►</kbd>

维持原大小上边贴到桌面上边缘：<kbd>⌃</kbd> + <kbd>⌥</kbd> + <kbd>⌘</kbd> + <kbd>▲</kbd>

维持原大小下边贴到桌面下边缘：<kbd>⌃</kbd> + <kbd>⌥</kbd> + <kbd>⌘</kbd> + <kbd>▼</kbd>

最大化：<kbd>⌃</kbd> + <kbd>⌥</kbd> + <kbd>return</kbd>

全屏 / 非全屏：<kbd>⌃</kbd> + <kbd>⌥</kbd> + <kbd>⌘</kbd> + <kbd>return</kbd>

回到初始状态：<kbd>⌃</kbd> + <kbd>⌥</kbd> + <kbd>delete</kbd>

## 输入法切换（IME Switch）

### 快捷键（Hot Keys）

切换成拼音：<kbd>⌃</kbd> + <kbd>⌥</kbd> + <kbd>/</kbd>

切换成日文：<kbd>⌃</kbd> + <kbd>⌥</kbd> + <kbd>.</kbd>

切换成英文：<kbd>⌃</kbd> + <kbd>⌥</kbd> + <kbd>,</kbd>

### 根据App自动切换输入法语言（Auto switch IME with App）

拼音：Finder、Spotlight、设置、Safari、WeChat、QQ、企业微信、Google Chrome、预览、Microsoft Office、iWorks

日文：Music（Apple Music）

英文：终端
