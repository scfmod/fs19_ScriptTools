---@param tableNamePath string
---@param tSourceTable table
---@return TableWatcher
function watchTable(tableNamePath, tSourceTable)

    if type(tSourceTable) ~= 'table' then
        print('Argument is not a table - ' .. tostring(tableNamePath))
        return false
    end

    local watcher = TableWatcher(tableNamePath)

    ---@return table
    function watcher:getTable()
        return tSourceTable
    end

    function watcher:setInspectionCallback(f)
        self.inspectCallback = f
    end

    ---@overload fun(functionName:string, fCallback:function):void
    ---@overload fun(functionName:string):void
    ---@param functionName string
    ---@param fCallback function
    ---@param nSampleLimit number
    ---@return void
    function watcher:attach(functionName, fCallback, nSampleLimit)
        -- print('Attaching watcher to ' .. functionName)

        if tSourceTable[functionName] == nil then
            print('ERROR: function "' .. functionName .. '" does not exist in ' .. self.namePath)
            return false
        elseif type(tSourceTable[functionName]) ~= 'function' then
            print('ERROR: "' .. functionName .. '" is not a function')
            return false
        end

        if type(fCallback) == 'function' then
            self.callback_functions[functionName] = fCallback
        end

        self.source_functions[functionName] = tSourceTable[functionName]
        self.samples_count[functionName] = 0
        self.samples_limit[functionName] = nSampleLimit or TableWatcher.DEFAULT_SAMPLE_LIMIT
        self.function_samples[functionName] = {}

        tSourceTable[functionName] = hook(self.source_functions[functionName], function(result, ...)
            --print('Watch: function hook callback from ' .. functionName)

            if self.samples_count[functionName] >= self.samples_limit[functionName] then
                -- print('Sample limit reached for ' .. functionName)
                -- for now we better detach when done
                self:detach(functionName)
                return
            end

            self:logSample(functionName, result, ...)

            if type(self.callback_functions[functionName]) == 'function' then
                self.callback_functions[functionName](functionName, result, ...)
            elseif type(self.callback) == 'function' then
                self.callback(functionName, result, ...)
            else
                -- print('WARNING: No callback function(s) set for ' .. functionName)
            end

            if self.samples_count[functionName] >= self.samples_limit[functionName] then
                print('Done sampling function: ' .. functionName)
            end
        end, function(...)
            -- Spying on function result
            if self.samples_count[functionName] <= self.samples_limit[functionName] then
                if self.function_samples[functionName][1] ~= nil then
                    if ... ~= nil then
                        self.function_samples[functionName][1].result.value = pack(...)
                    else
                        self.function_samples[functionName][1].result.value = nil
                    end
                    self.function_samples[functionName][1].result.type = 'table'
                end
                --end
            end
            return ...
        end)

        return true
    end

    ---@overload fun(tFunctionNames:table<any, string>, fCallback:function):void
    ---@overload fun(tFunctionNames:table<any, string>):void
    ---@param tFunctionNames table<any, string>
    ---@param fCallback function
    ---@param nSampleLimit number
    ---@return void
    function watcher:attachMultiple(tFunctionNames, fCallback, nSampleLimit)
        for _, name in pairs(tFunctionNames) do
            self:attach(name, fCallback, nSampleLimit)
        end
    end

    function watcher:attachAll(fCallback, nSampleLimit)
        for k, v in pairs(tSourceTable) do
            if type(v) == 'function' then
                self:attach(tostring(k), fCallback, nSampleLimit)
            end
        end
    end

    ---@param functionName string
    function TableWatcher:detach(functionName)
        if type(self.source_functions[functionName]) == 'function' then
            tSourceTable[functionName] = self.source_functions[functionName]
            return true
        end
        return false
    end

    function TableWatcher:detachAll()
        for k, v in pairs(self.source_functions) do
            if type(v) == 'function' then
                tSourceTable[k] = self.source_functions[k]
            end
        end
    end

    return watcher
end

registerGlobal('watchTable', watchTable)