---@param name string|number
---@param tbl table
---@param opt InspectorOptions
function inspectTableAndPrint(name, tbl, opt)
    --print('inspectTableAndPrint: ' .. tostring(name))
    local inspector = TableInspector(name, tbl)
    inspector:traverse(nil, opt)
    inspector:print(opt)
end

inspectTableAndPrint('GameSettings', GameSettings, { nMaxDepth = 2 })