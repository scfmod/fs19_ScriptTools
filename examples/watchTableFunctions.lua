
local vWatcher = watchTable('Vehicle', Vehicle)

-- observe all functions in table
vWatcher:attachAll()

-- or observe specific function(s) in table
-- vWatcher.attach('setComponentJointFrame')

-- vWatcher will now observe function calls and sample 1 call
-- to print results (do it on command - i.e key press)
vWatcher:printFunctionSamples({
    bPrintParameterTableValues = true, -- if a function parameter is a table, use this to print content (limited by nMaxLines & nMaxDepth)
    bPrintReturnValues = true,         -- print function return value
    bPrintReturnTableValues = false,   -- if function returns a table, print content
    bPrintParameterValues = true,      -- print function parameter values (limited by nMaxLines & nMaxDepth)
    nMaxDepth = 1,                     -- max depth when traversing tables
    nMaxLines = 10,                    -- max # of lines when printing table(s)
})