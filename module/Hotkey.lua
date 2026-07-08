local M = {}

local eventtap = require "hs.eventtap"
local types = eventtap.event.types

-- 停止所有旧监听器
if _G.HyperFlagWatcher then _G.HyperFlagWatcher:stop(); _G.HyperFlagWatcher = nil end
if _G.HyperKeyWatcher  then _G.HyperKeyWatcher:stop();  _G.HyperKeyWatcher  = nil end
if _G.HyperWatcher     then _G.HyperWatcher:stop();     _G.HyperWatcher     = nil end

local bindings = {}

-- 修饰键 keyCode 映射（flagsChanged 事件）
local MOD_KEYCODES = {
    lshift = 56, rshift = 60,
    lctrl  = 59, rctrl  = 62,
    lopt   = 58, ropt   = 61,
    lcmd   = 55, rcmd   = 54,
}

-- 反查表：keyCode → mod 名
local KEYCODE_TO_MOD = {}
for mod, kc in pairs(MOD_KEYCODES) do
    KEYCODE_TO_MOD[kc] = mod
end

-- 当前按下的修饰键集合
local activeModifiers = {}

-- 监听修饰键按下/松开，精确追踪左右
_G.HyperFlagWatcher = eventtap.new({types.flagsChanged}, function(e)
    local kc  = e:getKeyCode()
    local mod = KEYCODE_TO_MOD[kc]
    if mod then
        local flags = e:getFlags()
        -- flags 里对应的通用名（alt/shift/cmd/ctrl）
        local genericFlag = flags.alt or flags.shift or flags.cmd or flags.ctrl
        -- 判断是按下还是松开：flags 里有值说明按下
        local anyMod = false
        for _, v in pairs(flags) do
            if v then anyMod = true; break end
        end
        -- 更精确：看这个 keyCode 对应的通用 flag 是否存在
        local modFamily = {
            lshift="shift", rshift="shift",
            lctrl="ctrl",   rctrl="ctrl",
            lopt="alt",     ropt="alt",
            lcmd="cmd",     rcmd="cmd",
        }
        local family = modFamily[mod]
        if family and flags[family] then
            activeModifiers[mod] = true
        else
            activeModifiers[mod] = nil
        end
    end
    return false
end)
_G.HyperFlagWatcher:start()

-- 检查当前 activeModifiers 是否精确匹配 mods 列表
local function modsMatch(mods)
    -- 统计期望的修饰键
    local required = {}
    for _, mod in ipairs(mods) do
        required[mod] = true
    end
    -- activeModifiers 里不能有多余的键
    for mod, _ in pairs(activeModifiers) do
        if not required[mod] then return false end
    end
    -- 期望的键必须都在
    for mod, _ in pairs(required) do
        if not activeModifiers[mod] then return false end
    end
    return true
end

-- 主事件监听
_G.HyperWatcher = eventtap.new({types.keyDown, types.keyRepeat}, function(e)

    local t  = e:getType()
    local kc = e:getKeyCode()

    for _, binding in ipairs(bindings) do
        if binding.key == kc and modsMatch(binding.mods) then
            if t == types.keyDown then
                binding.fn()
                return true
            elseif t == types.keyRepeat then
                binding.repeatFn()
                return true
            end
        end
    end
    return false
end)
_G.HyperWatcher:start()

-- 对外接口
function M.bind(mods, key, fn, repeatDelay, repeatFn)
    local kc = hs.keycodes.map[key]
    if not kc then
        print("HyperKey.bind: 未知按键 " .. tostring(key))
        return
    end
    for _, mod in ipairs(mods) do
        if not MOD_KEYCODES[mod] then
            print("HyperKey.bind: 未知修饰键 " .. tostring(mod))
            return
        end
    end
    local actualRepeatFn = repeatFn or fn
    table.insert(bindings, {
        key      = kc,
        mods     = mods,
        fn       = fn,
        repeatFn = actualRepeatFn,
    })
    print(string.format("HyperKey: 已绑定 [%s] + %s", table.concat(mods, "+"), key))
end

function M._bindings()
    return bindings
end

_G.HyperKey = M
return M