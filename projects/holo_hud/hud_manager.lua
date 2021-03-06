local comp = require("component")
local event = require("event")
local serialization = require("serialization")
local computer = require("computer")
local term = require("term")

local g = comp.glasses
local m = comp.modem

local last_cmd = ""
local last_msg = ""

local tab_functions = {
    ["home"] = function() switchTo("home_hud.lua") end,
    ["energy"] = function() switchTo("energy_hud.lua") end,
    ["farming"] = function() switchTo("farming_hud.lua") end,
    ["clear"] = function() g.removeAll() end,
    -- ["timeOn"] = function() os.execute("time_widget.lua") end,
    -- ["sensor"] = function() switchTo("entity_sensor_hud.lua") end,
    ["exit"] = cleanExit
}

function switchTo(script_name)
    print("Switching to "..script_name)
    event.push("closeWidget")
    os.execute(script_name)
end

function cleanExit()
    print("Exiting")
    event.push("closeWidget")
    g.removeAll()
    event.ignore("modem_message")
    m.close(80)
    m.close(8000)
    m.close(8001)
    os.exit()
end

function executeFunction(_, _, _, port, _, packet)
    term.clear()
    last_msg = "{"..port..": "..packet.."}"
    local msg = serialization.unserialize(packet)
    if port == 8001 and msg["command"] ~= nil then
        last_cmd = "execute function: "..msg["command"]
        tab_functions[msg["command"]]()
    end
    print("Last msg:")
    print(last_msg)
    print("Last cmd:")
    print(last_cmd)
end

function executeSwitch(_, target)
    tab_functions[target]()
end

print("startup")
g.removeAll()
m.open(80)
m.open(8000)
m.open(8001)
event.listen("requestSwitch", executeSwitch)
event.listen("modem_message", executeFunction)
event.listen("interrupted", cleanExit)
switchTo("home_hud.lua")
