if TableInspector == nil then
    error('Missing ScriptTools: TableInspector')
end
if watchTable == nil then
    error('Missing ScriptTools: watchTable()')
end

local TestScript = {}


local hudWatcher = watchTable('HUD', HUD)
hudWatcher:attachAll()

local vehicleWatcher = watchTable('Vehicle', Vehicle)
vehicleWatcher:attach('addNodeObjectMapping')
vehicleWatcher:attach('setRelativePosition')
vehicleWatcher:attach('registerStateChange')

function TestScript:draw() end
function TestScript:update() end
function TestScript:loadMap() end
function TestScript:deleteMap() end
function TestScript:mouseEvent() end
function TestScript:keyEvent(u, s, m, i)
    local opt = {
        bPrintReturnValues = true,
        bPrintReturnTableValues = true,
        bPrintParameterValues = true,
        bPrintParameterTableValues = true,
        bPrintAsComment = true,

        nMaxDepth = 1,
        nMaxLines = 5
    }

    if i then
        if s == Input.KEY_1 then
            -- print HUD watcher result(s)
            hudWatcher:printFunctionSamples(opt)
        elseif s == Input.KEY_2 then
            -- print Vehicle watcher result(s)
            vehicleWatcher:printFunctionSamples(opt)
        elseif s == Input.KEY_4 then
            inspectTableAndPrint('g_currentMission', g_currentMission, {nMaxDepth = 1})
        end
    end
end

addModEventListener(TestScript)