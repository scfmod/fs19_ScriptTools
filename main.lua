-- IMPORTANT!
-- Set mod directory manually in case g_currentModDirectory is not set yet
-- This is mainly for inspecting when hooked into LuaJIT (.exe is starting) [REQUIRES x86_64 ASSEMBLY DEBUGGER KNOWLEDGE]
-- For normal mod usage this isn't required
if g_currentModDirectory == nil then
    g_currentModDirectory = 'C:/...'
end

source(g_currentModDirectory .. 'functions.lua')
source(g_currentModDirectory .. 'lib/TClass.lua')
source(g_currentModDirectory .. 'Inspectors/TableInspector.lua')
source(g_currentModDirectory .. 'Watchers/TableWatcher.lua')
source(g_currentModDirectory .. 'Watchers/watchTable.lua')

-- This one is on the todo-list
-- Meanwhile you can use hook(...) in functions.lua
-- source(g_currentModDirectory .. 'Watchers/FunctionWatcher.lua')