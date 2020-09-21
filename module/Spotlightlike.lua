local owner = hs.host.localizedName()
if string.find(owner,"カミ") then
	copied = "クリップボードにコピーしました"
	wikiUrl = "https://ja.wikipedia.org/wiki/keyword"
else
	copied = "已复制到剪贴板"
	wikiUrl = "https://en.wikipedia.org/wiki/keyword"
end
-- 添加ToolBar
local toolbarItems = {
	{
		id = "google",
		label = false,
		fn = function() searchFun("https://www.google.com/search?q=keyword") end,
		image = hs.image.imageFromPath(hs.configdir .. "/image/ToolBar/google.png"):setSize(imagesize, absolute == true),
	},
	{
		id = "baidu",
		label = false,
		fn = function() searchFun("https://www.baidu.com/s?wd=keyword") end,
		image = hs.image.imageFromPath(hs.configdir .. "/image/ToolBar/baidu.png"):setSize(imagesize, absolute == true),
	},
	{
		id = "wiki",
		label = false,
		fn = function() searchFun(wikiUrl) end,
		image = hs.image.imageFromPath(hs.configdir .. "/image/ToolBar/wiki.png"):setSize(imagesize, absolute == true),
	},
	{
		id = "translate",
		label = false,
		fn = function() searchFun("https://translate.google.com/#view=home&op=translate&sl=auto&tl=zh-CN&text=keyword") end,
		image = hs.image.imageFromPath(hs.configdir .. "/image/ToolBar/translate.png"):setSize(imagesize, absolute == true),
	}
}
local chooserToolbar = hs.webview.toolbar.new("chooserToolbarTest")
chooserToolbar:addItems(toolbarItems)
chooserToolbar:displayMode("default")
chooserToolbar:canCustomize(true)
-- 生成搜索框
function searchBox()
	local searchengine = 'https://duckduckgo.com/ac/?q=%s'
	-- 若使用Google搜索建议，替换为"https://suggestqueries.google.com/complete/search?&output=toolbar&hl=jp&q=%s&gl=ja"，有被Ban IP的可能性
	local choices = {}
    local tab = nil
	local copy = nil
	chooser = hs.chooser.new(function(choosen)
		if copy then
			copy:delete()
		end
		if tab then
			tab:delete()
		end
		copy = nil
		tab = nil
		-- 搜索选中关键词
		searchcompletionCallback(choosen)
    end)
    -- 删除框中所有项目
    function reset()
        chooser:choices({})
	end
	-- 实时更新搜索框候选
	function updateChooser()
		if tab == nil then
			-- 利用Tab键键入高亮候选项（默认为第一项）
			tab = hs.hotkey.bind('', 'tab', function()
				local id = chooser:selectedRow()
				local item = choices[id]
				-- 如果无高亮选项
				if not item then
					return
				end
				chooser:query(item.text)
				reset()
				updateChooser()
			end)
		end
		if copy == nil then
			-- 复制高亮候选项
			copy = hs.hotkey.bind('cmd', 'c', function()
				local id = chooser:selectedRow()
				local item = choices[id]
				if item then
					chooser:hide()
					hs.pasteboard.setContents(item.text)
					hs.alert.show(copied, 1)
				end
			end)
		end
        local string = chooser:query()
        local query = hs.http.encodeForQuery(string)
        -- 如果无输入则清空列表
		if string:len() == 0 then
			return reset()
		end
		-- 获取搜索建议并显示
		hs.http.asyncGet(string.format(searchengine, query), nil, function(status, data)
			if not data then 
				return 
			end
			local ok, results = pcall(function() return hs.json.decode(data) end)
			if not ok then 
				return
			end
			choices = hs.fnutils.imap(results, function(result)
				return {
					["text"] = result["phrase"],
				}
			end)
			--[[若使用Google搜索建议，上述imap代码替换为
			choices = hs.fnutils.imap(results[2], function(result)
                return {
                    ["text"] = result,
                }
			end)
			]]--
			table.insert(choices,1,{text = chooser:query()})
			if #choices > 1 then
				if choices[1].text == choices[2].text then
					table.remove(choices,1)
				end
			end
			chooser:choices(choices)
		end)
	end
	chooser:attachedToolbar(chooserToolbar)
	chooser:queryChangedCallback(updateChooser)
	chooser:searchSubText(false)
	chooser:rows(11)
end
-- 搜索函数
function searchFun(engineUrl)
	local script = [[tell application "Safari" to activate (open location "searchurl")]]
	local baseUrl = engineUrl
	-- Encode搜索词
	if chooser:selectedRowContents() == nil then
		return
	else
		encodedKeyword = hs.http.encodeForQuery(chooser:selectedRowContents()["text"])
		if string.find(encodedKeyword, "%%") then
			encodedKeyword = encodedKeyword:gsub("%%", "%%%%")
		end
		searchUrl = baseUrl:gsub("keyword", encodedKeyword)
		if searchUrl:find("%%") then
			searchUrl = searchUrl:gsub("%%", "%%%%")
		else
			searchUrl = searchUrl
		end
		urlscript = script:gsub("searchurl", searchUrl)
    end
	hs.osascript.applescript(urlscript)
	chooser:hide()
end
-- 执行的动作
function searchcompletionCallback(rowInfo)
	local script = [[tell application "Safari" to activate (open location "searchurl")]]
	local baseUrl = "https://www.google.com/search?q=keyword"
	-- Encode搜索词
	if rowInfo == nil then
		return
	elseif string.find(rowInfo["text"], "://") ~= nil or string.find(rowInfo["text"], "www.") ~= nil or string.find(rowInfo["text"], ".com") ~= nil or string.find(rowInfo["text"], ".jp") ~= nil then
		--hs.urlevent.openURLWithBundle(search:query(), "com.apple.Safari")
		urlscript = script:gsub("searchurl", rowInfo["text"])
	else
		encodedKeyword = hs.http.encodeForQuery(rowInfo["text"])
		if string.find(encodedKeyword, "%%") then
			encodedKeyword = encodedKeyword:gsub("%%", "%%%%")
		end
		searchUrl = baseUrl:gsub("keyword", encodedKeyword)
		if searchUrl:find("%%") then
			searchUrl = searchUrl:gsub("%%", "%%%%")
		else
			searchUrl = searchUrl
		end
		urlscript = script:gsub("searchurl", searchUrl)
    end
	hs.osascript.applescript(urlscript)
end
searchBox()
-- 触发快捷键
hs.hotkey.bind({"option"}, 'space', function()
	if chooser:isVisible() then
		chooser:hide()
	else
		chooser:query(nil)
		chooser:show()
		hs.keycodes.setMethod("Pinyin - Simplified")
	end
end)