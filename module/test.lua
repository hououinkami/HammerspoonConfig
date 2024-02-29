local dataa = {
    ["music.search.SearchCgiService"]={
        ["method"]="DoSearchForQQMusicDesktop",
        ["module"]="music.search.SearchCgiService",
        ["param"]={
            ["num_per_page"]=1,
            ["page_num"]=1,
            ["query"]="アイドル",
            ["search_type"]=0
        }
    }
}
musicdata = hs.json.encode(dataa)
musicheaders = {
				["Referer"] = "https://c.y.qq.com"
			}
hs.http.asyncPost("https://u.y.qq.com/cgi-bin/musicu.fcg", musicdata, musicheaders, function (musicStatus,musicBody,musicHeader)
    if musicStatus == 200 then 
        a = hs.json.decode(musicBody)
        print(musicBody)
        b = a["music.search.SearchCgiService"].data.body.song.list[1].mid
        print(b)
        b = a["music.search.SearchCgiService"].data.body.song.list[1].name
        print(b)
        b = a["music.search.SearchCgiService"].data.body.song.list[1].album.name
        print(b)
        b = a["music.search.SearchCgiService"].data.body.song.list[1].singer[1].name
        print(b)
    end
end)