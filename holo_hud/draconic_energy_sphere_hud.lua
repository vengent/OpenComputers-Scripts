local comp = require "component"
local event = require "event"
local serialization = require "serialization"
local ghelper = require "glasses_helper"

local g = comp.glasses

g.removeAll()

local base_y = 40
local base_x = 10
local base_width = 125
local base_text_scale = 0.8
local primary_color = {1, 1, 1 }
local primary_color_dark = {primary_color[1] - 0.2, primary_color[2] - 0.2, primary_color[3] - 0.2}

local c_energy = 0
local energy_box = 0
capacity_end_box = 0
capacity_start_box = 0


local tab_functions = {
    [1] = function() os.execute("home_hud.lua") os.exit() end,
    [3] = function() os.execute("entity_sensor_hud.lua") os.exit() end,
    [4] = function() os.execute("time_widget.lua") end,
    [5] = function() g.removeAll() end,
    [6] = function() g.removeAll() os.exit() end
}

function roundTo(nmbr, digits)
    local shift = 10 ^ digits
    return math.floor( nmbr*shift + 0.5 ) / shift
end

function initPowerDisplay(y)
    energy_box = g.addRect()
    capacity_end_box = g.addRect()
    capacity_start_box = g.addRect()

    capacity_start_box.setSize(10.8, 0.8)
    capacity_start_box.setPosition(base_x - 0.8, y-0.4)
    capacity_start_box.setColor(primary_color_dark[1], primary_color_dark[2] , primary_color_dark[3])

    capacity_end_box.setSize(10.8, 0.8)
    capacity_end_box.setPosition(base_x + base_width - 10, y-0.4)
    capacity_end_box.setColor(primary_color_dark[1], primary_color_dark[2] , primary_color_dark[3])

    energy_box.setColor(primary_color[1], primary_color[2] , primary_color[3])
    energy_box.setAlpha(0.9)
end

function updatePowerDisplay(energy, capacity, y)
    local energy_ratio = energy/capacity
    local energy_width = energy_ratio*100*((base_width - 10)/100)

    energy_box.setSize(10, energy_width)
    energy_box.setPosition(base_x, y)
end

function calculateNetEnergy(curr_energy)
    local energy_dif = curr_energy - c_energy

    net_energy_info.setText("Net-Energy in kRF/t: "..roundTo((energy_dif/1000)/20, 2))
    if energy_dif < 0 then
        net_energy_info.setColor(1, 0, 0)
    elseif energy_dif == 0 then
        net_energy_info.setColor(1, 1, 1)
    else
        net_energy_info.setColor(0, 1, 0)
    end

    c_energy = curr_energy
end

ghelper.bgBox(base_x - 4, base_y - 10, 45, base_width, primary_color_dark)
ghelper.headlineText("Energy", base_x, base_y, base_width, base_text_scale, primary_color)
local power_info = ghelper.infoText("", base_x, base_y + 10, base_text_scale, primary_color)
net_energy_info = ghelper.infoText("", base_x, base_y + 20, base_text_scale, primary_color)
initPowerDisplay(base_y + 20)
power_info.setText("Waiting for signal")

while true do
    local _, _, _, port, _, message = event.pull("modem_message")
    local msg = serialization.unserialize(message)

    if port == 8000 then
        power_info.setText("Energy stored in GRF: "..roundTo(msg[1]/1000000000, 2))
        calculateNetEnergy(msg[1])
        updatePowerDisplay(msg[1], msg[2], base_y + 20)
    elseif port == 8001 then
        print("executing function: "..msg[1])
        tab_functions[msg[1]]()
    end
end
