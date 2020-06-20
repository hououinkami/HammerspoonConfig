function toggleclashx()
    local ssid = hs.wifi.currentNetwork()
    if (ssid == "BabyShrimp") or (ssid == "BabyShrimp-2.4G") then
        hs.osascript.applescript([[tell application "ClashX Pro" to quit]])
    else
        hs.osascript.applescript([[tell application "ClashX Pro" to activate]])
    end
end
wifiWatcher = hs.wifi.watcher.new(toggleclashx)
wifiWatcher:start()