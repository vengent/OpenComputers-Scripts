local comp = require "component"
local event = require "event"
local serialization = require "serialization"
local ghelper = require "glasses_helper"

local password = "entryPasswordToSecretBatcave"

local g = comp.glasses
local m = comp.modem
local s = comp.motion_sensor
local rfid = comp.os_rfidreader
local e = comp.os_entdetector

s.setSensitivity(0.1)

g.removeAll()

local entity_widgets = {}
local running = true
local motion_dot = {}
local ent_dot = {}
local player_dot = {}
local base_y = 40
local base_x = 10
local base_width = 130
local base_text_scale = 0.8
local primary_color = {1, 1, 1}
--local primary_color = {0.467, 0, 1 }
local primary_color_dark = {primary_color[1] - 0.2, primary_color[2] - 0.2, primary_color[3] - 0.2}
local red_color = {1, 0, 0 }
local green_color = {0, 1, 0}

local entdetector_coords = {
    ["x"] = 899,
    ["z"] = -2200,
    ["y"] = 74
}

local terminal_coords = {
    ["x"] = 900,
    ["z"] = -2205,
    ["y"] = 68
}

local motion_center = {
    ["x"] = (base_x + base_width)*0.25,
    ["y"] = base_y + 40
}

local entdetector_center = {
    ["x"] = (base_x + base_width)*0.75,
    ["y"] = base_y + 40
}

m.open(8001)

function initUI()

end

function checkRfids()
    local i = 1
    local player = {}
    local rfids = rfid.scan()
    for k,v in pairs(rfids) do
        if v["data"] == password then
            v["verified"] = true
        else
            v["verified"] = false
        end
        player[i] = v
        i = i + 1
    end
    return player
end

function compareData(motion, rfids)

end

function unknownEvent()

end

function string.starts(String,Start)
    return string.sub(String,1,string.len(Start))==Start
end

function detect_players()
    local players = e.scanPlayers(64)
    for k,v in pairs(players) do
        local ent_name = v["name"]
        local cube_x = (v["x"]-terminal_coords["x"]) - 0.5
        local cube_y = (v["y"]-terminal_coords["y"])
        local cube_z = (v["z"]-terminal_coords["z"]) - 0.5
        local dot_x = entdetector_center["x"] - (v["x"]-entdetector_coords["x"])*2
        local dot_y = entdetector_center["y"] - (v["z"]-entdetector_coords["z"])*2
        local label_x = dot_x*2 - string.len(ent_name) * 2
        local label_y = dot_y*2 - 10

        if  player_dot[ent_name] == nil then
            player_dot[ent_name] = {}
            player_dot[ent_name]["dot"] = ghelper.dot(dot_x, dot_y, 2, green_color)
            player_dot[ent_name]["label"] = ghelper.infoText(ent_name, label_x, label_y, 0.5, green_color)
            player_dot[ent_name]["cube"] = ghelper.cube(cube_x, cube_y, cube_z, 0.9, green_color, 0.75, true, 100)
        else
            if math.abs(v["range"])<9.5 then
                player_dot[ent_name]["dot"].setAlpha(1)
                player_dot[ent_name]["label"].setAlpha(1)
                player_dot[ent_name]["cube"].setAlpha(0.75)

                player_dot[ent_name]["dot"].setPosition(dot_x, dot_y)
                player_dot[ent_name]["label"].setPosition(label_x, label_y)
                player_dot[ent_name]["cube"].set3DPos(cube_x, cube_y, cube_z)
            else
                player_dot[ent_name]["dot"].setAlpha(0.1)
                player_dot[ent_name]["label"].setAlpha(0.1)
                player_dot[ent_name]["cube"].setAlpha(0)
            end
        end
    end
end

local player_detect_timer = event.timer(0.2, detect_players, math.huge)

function cleanExit()
    event.cancel(player_detect_timer)
    running = false
    print("exiting")
end

local tab_functions = {
    [1] = function() cleanExit() os.execute("home_hud.lua") end,
    [2] = function() cleanExit() os.execute("reactor_hud.lua") end,
    [3] = function() cleanExit() os.execute("entity_sensor_hud.lua") end,
    [4] = function() cleanExit() os.execute("time_widget.lua") end,
    [5] = function() g.removeAll() end,
    [6] = function() g.removeAll() cleanExit() end
}

local myEventHandlers = setmetatable({}, { __index = function() return unknownEvent end })

function myEventHandlers.modem_message(_, _, port, _, msg)
    local msg = serialization.unserialize(msg)

    if port == 8001 then
        print("executing function: "..msg[1])
        tab_functions[msg[1]]()
    end
end

function myEventHandlers.motion(_, x, y, z, entity_name)
    local dot_x = motion_center["x"] - x*2
    local dot_y = motion_center["y"] - z*2
    local label_x = dot_x*2 - string.len(entity_name) * 2
    local label_y = dot_y*2 - 10

    if  motion_dot[entity_name] == nil then
        motion_dot[entity_name] = {}
        motion_dot[entity_name]["dot"] = ghelper.dot(dot_x, dot_y, 2, red_color)
        motion_dot[entity_name]["label"] = ghelper.infoText(entity_name, label_x, label_y, 0.5, red_color)
    else
        motion_dot[entity_name]["dot"] .setPosition(dot_x, dot_y)
        motion_dot[entity_name]["label"] .setPosition(label_x, label_y)
    end
end

function handleEvent(eventID, ...)
    if (eventID) then
        myEventHandlers[eventID](...)
    end
end

ghelper.bgBox(base_x - 4, base_y - 10, 100, base_width, primary_color_dark)
ghelper.headlineText("Sensor Grid", base_x, base_y, base_width, base_text_scale, primary_color)
ghelper.dot(motion_center["x"], motion_center["y"], 3, primary_color)
ghelper.dot(entdetector_center["x"], entdetector_center["y"], 3, primary_color)

while running == true do
    handleEvent(event.pull())
end
