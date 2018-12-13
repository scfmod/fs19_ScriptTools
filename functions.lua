---@param name any
---@param value any
function registerGlobal(name, value)
    getfenv(tostring)[name] = value
end


----------------------------------------------------------------


---@param tbl table
function getTableLength(tbl)
    local c = 0
    for _ in pairs(tbl) do c = c + 1 end
    return c
end


----------------------------------------------------------------


function pack(...)
    local n = select('#', ...)
    return setmetatable({...}, {
        __len = function() return n end,
    })
end


----------------------------------------------------------------


---@overload fun(fSrc:function, fDst:function):any
---@param fSrc function
---@param fDst function
---@param fResultCallback function
function hook(fSrc, fDst, fResultCallback)
    return function(...)
        if type(fResultCallback) == 'function' then
            fDst(nil, ...)
            return fResultCallback(fSrc(...))
        else
            fDst(nil, ...)
            return fSrc(...)
        end
    end
end


----------------------------------------------------------------


function sortPairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys + 1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys
    if order then
        table.sort(keys, function(a, b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end


----------------------------------------------------------------


function sortTableByKeyValue(tSource, sKeyName, value, fSortFunction)

    if type(tSource) ~= 'table' then
        return false, 'Function argument tSource is not a table'
    end

    local result = {}

    for k, v in sortPairs(tSource, fSortFunction or function(t, a, b)
        if type(t[a][sKeyName]) == 'table' then
            return false
        elseif type(t[b][sKeyName]) == 'table' then
            return true
        end
        return t[a][sKeyName] < t[b][sKeyName]
    end) do
        table.insert(result, v)
    end

    return result
end


----------------------------------------------------------------


registerGlobal('registerGlobal', registerGlobal)
registerGlobal('getTableLength', getTableLength)
registerGlobal('pack', pack)
registerGlobal('hook', hook)
registerGlobal('sortPairs', sortPairs)
registerGlobal('sortTableByKeyValue', sortTableByKeyValue)
