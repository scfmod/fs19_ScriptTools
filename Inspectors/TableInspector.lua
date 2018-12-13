---@class InspectorOptions
---@field nMaxDepth number
---@field nDepth number
---@field bNoSorting boolean
---@field bShowHidden boolean
---@field bPrintAsComment boolean
---@field fSortFunction function
---@field bPrintKeyTable boolean


--------------------------------


---@class TableInspector
TableInspector = TClass:extend('TableInspector')

TableInspector.DEFAULT_MAX_DEPTH = 1
TableInspector.MAX_DEPTH = 4

function TableInspector:init(sTableNamePath, tSourceTable)
    self.maxDepth = TableInspector.DEFAULT_MAX_DEPTH
    self.maxDepthReached = false
    self.sourceTable = tSourceTable
    self.namePath = sTableNamePath
    self.functions = {}
    self.variables = {}
end

function TableInspector:getFunctions()
    return self.functions
end

function TableInspector:getFunctionsSorted(fSortFunction)
    return sortTableByKeyValue(self.functions, 'name', fSortFunction)
end

function TableInspector:getVariables()
    return self.variables
end

function TableInspector:getVariablesSorted(fSortFunction)
    return sortTableByKeyValue(self.variables, 'name', fSortFunction)
end

---@param nDepth number
---@param opt InspectorOptions
function TableInspector:traverse(nDepth, opt)
    opt = opt or {}
    nDepth = nDepth or 1

    self.maxDepth = opt.nMaxDepth or TableInspector.DEFAULT_MAX_DEPTH

    -- check variable type of sourceTable
    if type(self.sourceTable) ~= 'table' then
        print('WARNING: TableInspector:traverse > ' .. tostring(self.namePath))
        print('WARNING: Expected table, got ' .. type(self.sourceTable))
        return false
    end

    -- depth check (recursive depth)
    if nDepth > self.maxDepth then
        self.maxDepthReached = true
        return false
    elseif nDepth > TableInspector.MAX_DEPTH then
        self.maxDepthReached = true
        return false
    end

    -- loop table variables
    for k, val in pairs(self.sourceTable) do
        if (string.sub(tostring(k), 1, 2) ~= '__' or bShowHidden == true) then
            if type(val) == 'function' then
                table.insert(self.functions, {
                    name = k,
                    value = nil
                })
            elseif type(val) == 'table' then
                local inspector = TableInspector(tostring(k), val)
                inspector:traverse(nDepth + 1, opt)

                table.insert(self.variables, {
                    name = k,
                    value = inspector
                })
            else
                table.insert(self.variables, {
                    name = k,
                    value = val
                })
            end
        end
    end

    return true
end

---@param opt InspectorOptions
function TableInspector:print(opt)
    opt = opt or {}
    local variables, functions

    local function space(depth)
        depth = depth or 1

        if opt.bPrintAsComment then
            if depth == 0 then return '-- ' end
            return '-- ' .. string.rep('  ', depth)
        else
            if depth == 0 then return '' end
            return string.rep('  ', depth)
        end
    end

    local function _print(depth, str)
        print(space(depth) .. str)
    end

    if opt.bNoSorting == true then
        variables = self:getVariables()
        functions = self:getFunctions()
    else
        variables = self:getVariablesSorted(fSortFunction)
        functions = self:getFunctionsSorted(fSortFunction)
    end

    _print(0, tostring(self.namePath) .. ' = {')

    for i = 1, #variables do
        local entry = variables[i]
        local name = tostring(entry.name)

        if type(entry.name) == 'number' then
            name = '[' .. tostring(name) .. ']'
        end

        if opt.nMaxLines and i > opt.nMaxLines then
            _print(1, '-- nMaxLines limit')
            break
        end

        if type(entry.name) == 'table' then
            if opt.bPrintKeyTable then
                if i == #variables or (opt.nMaxLines and i == opt.nMaxLines) then
                    _print(1, '{} -- key is ' .. tostring(entry.name))
                else
                    _print(1, '{}, -- key is ' .. tostring(entry.name))
                end
            end
        elseif type(entry.value) == 'table' then
            if entry.value.maxDepthReached == true then
                if i == #variables or (opt.nMaxLines and i == opt.nMaxLines) then
                    _print(1, name .. ' = {} -- MAX_DEPTH')
                else
                    _print(1, name .. ' = {}, -- MAX_DEPTH')
                end
            elseif getTableLength(entry.value) < 1 then
                if i == #variables or (opt.nMaxLines and i == opt.nMaxLines) then
                    _print(1, name .. ' = {} -- empty')
                else
                    _print(1, name .. ' = {}, -- empty')
                end
            elseif type(entry.value.printAsChild) == 'function' then
                _print(1, name .. ' = {')

                entry.value:printAsChild(2, opt)

                if i == #variables or (opt.nMaxLines and i == opt.nMaxLines) then
                    _print(1, '}')
                else
                    _print(1, '},')
                end
            else
                if i == #variables or (opt.nMaxLines and i == opt.nMaxLines) then
                    _print(1, name .. ' = {}')
                else
                    _print(1, name .. ' = {},')
                end
            end
        elseif type(entry.value) == 'string' then
            if i == #variables or (opt.nMaxLines and i == opt.nMaxLines) then
                _print(1, name .. ' = \'' .. entry.value .. '\'')
            else
                _print(1, name .. ' = \'' .. entry.value .. '\',')
            end
        elseif type(entry.value) == 'userdata' then
            if i == #variables or (opt.nMaxLines and i == opt.nMaxLines) then
                _print(1, name .. ' = {} --' .. tostring(entry.value))
            else
                _print(1, name .. ' = {}, -- ' .. tostring(entry.value))
            end
        else
            if i == #variables or (opt.nMaxLines and i == opt.nMaxLines) then
                _print(1, name .. ' = ' .. tostring(entry.value))
            else
                _print(1, name .. ' = ' .. tostring(entry.value) .. ',')
            end
        end
    end

    _print(0, '}')

    if #functions > 0 then

        for i = 1, #functions do
            if opt.nMaxLines and i > opt.nMaxLines then
                _print(1, '-- nMaxLines limit')
                break
            end
            _print(0, 'function ' .. self.namePath .. ':' .. tostring(functions[i].name) .. '() end')
        end
        --print('')
        --for _, f in pairs(functions) do
        --    _print(0, 'function ' .. self.namePath .. ':' .. tostring(f.name) .. '() end')
        --end
    end

end

---@param opt InspectorOptions
function TableInspector:printAsChild(nDepth, opt)
    opt = opt or {}
    local variables, functions

    local function space(depth)
        depth = depth or 1

        if opt.bPrintAsComment then
            if depth == 0 then return '-- ' end
            return '-- ' .. string.rep('  ', depth)
        else
            if depth == 0 then return '' end
            return string.rep('  ', depth)
        end
    end
    local function _print(depth, str)
        print(space(depth) .. str)
    end

    --print('self = ' .. tostring(self))
    --print('nDepth = ' .. tostring(nDepth))

    if opt.bNoSorting == true then
        variables = self:getVariables()
        functions = self:getFunctions()
    else
        variables = self:getVariablesSorted(fSortFunction)
        functions = self:getFunctionsSorted(fSortFunction)
    end

    for i = 1, #variables do
        local entry = variables[i]
        local name = tostring(entry.name)

        if type(entry.name) == 'number' then
            name = '[' .. tostring(name) .. ']'
        end

        if opt.nMaxLines and i > opt.nMaxLines then
            _print(1, '-- nMaxLines limit')
            break
        end

        if type(entry.name) == 'table' then
            if opt.bPrintKeyTable then
                if i == #variables or (opt.nMaxLines and i == opt.nMaxLines) then
                    _print(1, '{} -- key is ' .. tostring(entry.name))
                else
                    _print(1, '{}, -- key is ' .. tostring(entry.name))
                end
            end
        elseif type(entry.value) == 'table' then
            if getTableLength(entry.value) < 1 then
                if i == #variables or (opt.nMaxLines and i == opt.nMaxLines) then
                    _print(nDepth, name .. ' = {} -- empty')
                else
                    _print(nDepth, name .. ' = {}, -- empty')
                end
            elseif entry.value.maxDepthReached == true then
                if i == #variables or (opt.nMaxLines and i == opt.nMaxLines) then
                    _print(nDepth, name .. ' = {} -- MAX_DEPTH')
                else
                    _print(nDepth, name .. ' = {}, -- MAX_DEPTH')
                end
            else
                _print(nDepth, name .. ' = {')

                entry.value:printAsChild(nDepth + 1, opt)

                if i == #variables or (opt.nMaxLines and i == opt.nMaxLines) then
                    _print(nDepth, '}')
                else
                    _print(nDepth, '},')
                end
            end
        elseif type(entry.value) == 'string' then
            if i == #variables or (opt.nMaxLines and i == opt.nMaxLines) then
                _print(nDepth, name .. ' = \'' .. entry.value .. '\'')
            else
                _print(nDepth, name .. ' = \'' .. entry.value .. '\',')
            end
        elseif type(entry.value) == 'userdata' then
            if i == #variables or (opt.nMaxLines and i == opt.nMaxLines) then
                _print(1, name .. ' = {} --' .. tostring(entry.value))
            else
                _print(1, name .. ' = {}, -- ' .. tostring(entry.value))
            end
        else
            if i == #variables or (opt.nMaxLines and i == opt.nMaxLines) then
                _print(nDepth, name .. ' = ' .. tostring(entry.value))
            else
                _print(nDepth, name .. ' = ' .. tostring(entry.value) .. ',')
            end
        end
    end

    for i = 1, #functions do
        local entry = functions[i]
        local name = entry.name
        if type(name) == 'number' then
            name = '[' .. tostring(name) .. ']'
        end

        if opt.nMaxLines and i > opt.nMaxLines then
            _print(1, '-- nMaxLines limit')
            break
        end

        if i == #functions then
            _print(nDepth, tostring(name) .. ' = function() end')
        else
            _print(nDepth, tostring(name) .. ' = function() end,')
        end
    end

end


--------------------------------


---@param name string|number
---@param tbl table
---@param opt InspectorOptions
function inspectTableAndPrint(name, tbl, opt)
    --print('inspectTableAndPrint: ' .. tostring(name))
    local inspector = TableInspector(name, tbl)
    inspector:traverse(nil, opt)
    inspector:print(opt)
end


--------------------------------


registerGlobal('TableInspector', TableInspector)
registerGlobal('inspectTableAndPrint', inspectTableAndPrint)