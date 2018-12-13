-- map for shortening variable types to variable names
local typeNameMap = {
    ['function'] = 'func',
    ['string'] = 'str',
    ['number'] = 'num',
    ['table'] = 'tbl',
    ['userdata'] = 'udata',
    ['boolean'] = 'bool',
    ['thread'] = 'thread',
    ['nil'] = 'var'
}

---@param sType string
function typeToShortName(sType)
    return typeNameMap[sType]
end

----------------------------------------------------------------


-- Class definitions for type hinting

---@class FunctionResult
---@field type string
---@field value any

---@class WatcherPrintOptions
---@field bPrintReturnValues boolean
---@field bPrintReturnTableValues boolean
---@field bPrintParameterValues boolean
---@field bPrintParameterTableValues boolean
---@field nMaxLines number
---@field nMaxDepth number

----------------------------------------------------------------


---@class FunctionArgument
local FunctionArgument = TClass:extend('FunctionArgument')

function FunctionArgument:init(value)
    ---@type string
    self.name = nil
    ---@type string
    self.type = type(value)
    ---@type any
    self.value = nil

    if self.type == 'table' then
        local inspector = TableInspector('arg', value)
        if inspector:traverse(nil, {nMaxDepth = 1}) ~= false then
            self.value = inspector
        end
    elseif self.type == 'string' or self.type == 'number' or self.type == 'boolean' then
        self.value = value
    end
end


----------------------------------------------------------------


---@class TableFunctionWatchSample
local TableFunctionWatchSample = TClass:extend('TableFunctionWatchSample')

---@param watcher TableWatcher
---@param name string
---@param result any
function TableFunctionWatchSample:init(watcher, name, result, ...)
    ---@type TableWatcher
    self.watcher = watcher
    ---@type string
    self.name = name
    ---@type table<any, FunctionArgument>
    self.args = {}

    self.isInstance = true

    ---@type FunctionResult
    self.result = {
        type = type(result),
        value = nil
    }

    if self.result.type == 'string' or self.result.type == 'number' or self.result.type == 'boolean' then
        self.result.value = result
    elseif self.result.type == 'table' then
        local inspector = TableInspector('result', result)

        if inspector:traverse(nil, {nMaxDepth = 1}) ~= false then
            self.result.value = inspector
        end
    end

    for i = 1, select('#', ...) do
        local arg = select(i, ...)

        if i == 1 and arg == self.watcher.getTable() then
            -- later maybe
        else
            table.insert(self.args, FunctionArgument(arg))
        end
    end
end

---@param opt WatcherPrintOptions
---@return void
function TableFunctionWatchSample:print(opt)
    opt = opt or {}

    local varTypeCount = {}

    ---@param sType string
    ---@return string
    local function generateVariableName(sType)
        if varTypeCount[sType] == nil then
            varTypeCount[sType] = 1
        else
            varTypeCount[sType] = varTypeCount[sType] + 1
        end
        return typeToShortName(sType) .. '_' .. tostring(varTypeCount[sType])
    end

    local sFunctionParams = ''

    for _, arg in pairs(self.args) do
        arg.name = generateVariableName(arg.type)
        print('---@param ' .. arg.name .. ' ' .. arg.type)
        sFunctionParams = sFunctionParams .. tostring(arg.name) .. ', '
    end

    -- remove ', ' at the end of string
    if string.len(sFunctionParams) > 1 then
        sFunctionParams = string.sub(sFunctionParams, 1, #sFunctionParams - 2)
    end

    --if opt.bPrintReturnValues then
    --    print('---@return ' .. self.result.type)
    --end

    if self.isInstance then
        if self.watcher.printNamePath then
            print('function ' .. tostring(self.watcher.namePath) .. ':' .. tostring(self.name) .. '(' .. sFunctionParams .. ')')
        else
            print('function ' .. tostring(self.name) .. '(' .. sFunctionParams .. ')')
        end
    else
        if self.watcher.printNamePath then
            print(tostring(self.watcher.namePath) .. '.' .. tostring(self.name) .. ' = function(' .. sFunctionParams .. ')')
        else
            print(tostring(self.name) .. ' = function(' .. sFunctionParams .. ')')
        end
    end

    if opt.bPrintParameterValues == true then
        for _, arg in pairs(self.args) do
            if arg.type == 'string' then
                print('-- ' .. tostring(arg.name) .. ' = \'' .. tostring(arg.value) .. '\'')
            elseif arg.type == 'number' or arg.type == 'boolean' then
                print('-- ' .. tostring(arg.name) .. ' = ' .. tostring(arg.value))
            elseif arg.type == 'table' and type(arg.value) == 'table' and opt.bPrintParameterTableValues == true then
                if arg.value.print ~= nil then
                    if arg.value.classId ~= nil then
                        print('-- (classId:' .. tostring(arg.value.classId) .. ')')
                    end
                    arg.value.namePath = tostring(arg.name)
                    arg.value:print(opt)
                else
                    if arg.value.classId ~= nil then
                        print('-- ' .. tostring(arg.name) .. ' = ' .. tostring(arg.value) .. ' (classId:' .. tostring(arg.value.classId) .. ')')
                    else
                        print('-- ' .. tostring(arg.name) .. ' = ' .. tostring(arg.value))
                    end
                end
            elseif arg.type == 'table' then
                if arg.value.classId ~= nil then
                    print('-- ' .. tostring(arg.name) .. ' = {} ' .. tostring(arg.value) .. ' (classId:' .. tostring(arg.value.classId) .. ')')
                else
                    print('-- ' .. tostring(arg.name) .. ' = {} ' .. tostring(arg.value))
                end
            else
                print('-- ' .. tostring(arg.name) .. ' = ' .. arg.type)
            end
        end
        print('--')
    end

    if self.result.type == 'table' and opt.bPrintReturnTableValues then
        if self.result.value == nil then
            print('-- return value: nil')
        elseif type(self.result.value == 'table') then
            if self.result.value.print ~= nil then -- inspector
                local nLength = getTableLength(result.value.variables)
                if nLength == 0 then
                    print('-- return value: {} empty table')
                elseif nLength == 1 then
                    if type(result.value.variables[1]) == 'string' then
                        print('-- return value: \'' .. result.value.variables[1] .. '\'')
                    else
                        print('-- return value: ' .. tostring(self.result.value))
                    end
                else
                    if self.result.value.classId ~= nil then
                        print('(classId:' .. tostring(self.result.value.classId) .. ')')
                    end
                    self.result.value.namePath = 'result'
                    self.result.value:print(opt)
                end
            elseif getTableLength(self.result.value) == 0 then
                print('-- return value: {} empty table')
            elseif getTableLength(self.result.value) == 1 then
                if type(self.result.value) == 'string' then
                    print('-- return value: \'' .. tostring(self.result.value[1]) .. '\'')
                else
                    print('-- return value: ' .. tostring(self.result.value[1]))
                end
            else
                if self.result.value.classId ~= nil then
                    print('(classId:' .. tostring(self.result.value.classId) .. ')')
                end
                local inspector = TableInspector('result', self.result.value)
                inspector:traverse(1, {bPrintAsComment = true, nMaxLines = opt.nMaxLines or 5})
                inspector:print({nMaxLines = 5, bPrintAsComment = true})
            end
        end
        --
        --if type(self.result.value) == 'table' and self.result.value.print ~= nil then
        --    arg.result.value.namePath = 'result'
        --    arg.result.value:print(opt)
        --elseif getTableLength(self.result.value) == 0 then
        --    print('-- return value: {} empty table')
        --else
        --    -- print('-- return value: ' .. tostring(self.result.value))
        --    local inspector = TableInspector('result', self.result.value)
        --    inspector:traverse(1, {bPrintAsComment = true, nMaxLines = opt.nMaxLines or 5})
        --    inspector:print({nMaxLines = 5, bPrintAsComment = true})
        --end
    else
        if type(self.result.value) == 'string' then
            print('-- return value: \'' .. tostring(self.result.value) .. '\'')
        else
            print('-- return value: ' .. tostring(self.result.value))
        end
    end

    print('end')
end


----------------------------------------------------------------



---@class TableWatcher
local TableWatcher = TClass:extend('TableWatcher')

TableWatcher.DEFAULT_SAMPLE_LIMIT = 1

---@param tableNamePath string
function TableWatcher:init(tableNamePath)
    ---@type function
    self.callback = nil
    ---@type table<string, function>
    self.source_functions = {}
    ---@type table<string, function>
    self.callback_functions = {}
    ---@type table<string, number>
    self.samples_count = {}
    ---@type table<string, number>
    self.samples_limit = {}
    ---@type table<string, TableFunctionWatchSample>
    self.function_samples = {}
    ---@type string
    self.namePath = tableNamePath
    self.printNamePath = true
end

---@param fCallback function
function TableWatcher:setCallbackFunction(fCallback)
    self.callback = fCallback
end

---@param functionName string
---@param result any
function TableWatcher:logSample(functionName, result, ...)
    -- print('logFunctionResult from ' .. functionName)
    table.insert(self.function_samples[functionName], TableFunctionWatchSample(self, functionName, result, ...))
    self.samples_count[functionName] = self.samples_count[functionName] + 1
end

---@overload fun():void
---@param functionName string (optional)
---@return void
function TableWatcher:resetSampleCount(functionName)
    if functionName ~= nil then
        self.samples_count[functionName] = 0
    else
        for k in pairs(self.samples_count) do
            self.samples_count[k] = 0
        end
    end
end

---@param opt WatcherPrintOptions
---@return void
function TableWatcher:printFunctionSamples(opt)
    for _, f in pairs(self.function_samples) do
        for _, sample in pairs(f) do
            sample:print(opt)
            print('')
        end
    end
end



----------------------------------------------------------------


registerGlobal('TableWatcher', TableWatcher)
