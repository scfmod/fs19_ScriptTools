-- TClass - extended from 30log class

source(g_currentModDirectory .. 'lib/30log.lua')

---@class TClass
TClass = log30_Class('TClass')

getmetatable(TClass).__tostring = function(t)
    return "TClass <" .. (t.name or 'unknown') .. ">"
end

registerGlobal('TClass', TClass)