local robot = require "robot"
local comp = require "component"
local sides = require "sides"
local event = require "event"

local ic = comp.inventory_controller
local m = comp.modem

local in_side = sides.top
local out_side = sides.right
local inv_size = ic.getInventorySize(in_side)

local doFarmLoop = false

function checkInv()
    local slots = {}

    for i = 1, 16 do
        local stack = ic.getStackInInternalSlot(i)
        if stack ~= nil then
            slots[i] = stack
        end
    end

    return slots
end

function checkInput()
    for i = 1, inv_size do
        local stack = ic.getStackInSlot(in_side, i)
        if stack ~= nil then
            if stack["id"] == 4130 then
                robot.select(1)
                ic.suckFromSlot(in_side, i)
            end
        end
    end
end

function dropSeeds(internal_inv)
    for k, v in pairs(internal_inv) do
        if v["id"] == 4130 then
            robot.select(k)
            robot.dropDown()
        end
    end
end

function collectSeeds()
    local crystals_below = true
    robot.select(1)
    while crystals_below do
        crystals_below = robot.suckDown()
    end
end

function storeCrystals(internal_inv)
    for k, v in pairs(internal_inv) do
        if v["id"] == 4134 then
            robot.select(k)
            ic.dropIntoSlot(out_side, k)
        end
    end
end

function checkCallback(_, _, _, _, _, msg)
    doFarmLoop = msg
end

m.open(8003)
event.listen("modem_message", checkCallback)

if inv_size ~= nil then
    while doFarmLoop == true do
        collectSeeds()
        storeCrystals(checkInv())
        checkInput()
        dropSeeds(checkInv())
        os.sleep(10)
    end
end