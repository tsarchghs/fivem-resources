-- Local variables
local inventory = {}
local inventoryWeight = 0

-- Update inventory from server
RegisterNetEvent('bloggrs:setInventory')
AddEventHandler('bloggrs:setInventory', function(newInventory)
    inventory = newInventory
    CalculateInventoryWeight()
    
    -- Update UI
    SendNUIMessage({
        type = "updateInventory",
        inventory = inventory
    })
end)

-- Calculate inventory weight
function CalculateInventoryWeight()
    local weight = 0
    
    if inventory then
        for _, data in pairs(inventory) do
            -- Each item counts as 0.1 weight
            weight = weight + (0.1 * data.count)
        end
    end
    
    inventoryWeight = weight
    return weight
end

-- Check if player can carry item
function CanCarryItem(item, count)
    if not inventory then
        return false
    end
    
    local currentWeight = CalculateInventoryWeight()
    local addedWeight = 0.1 * count -- Each item is 0.1 weight
    
    return (currentWeight + addedWeight) <= Config.MaxInventoryWeight
end

-- Get item count
function GetItemCount(item)
    if not inventory or not inventory[item] then
        return 0
    end
    
    return inventory[item].count
end

-- Check if player has item
function HasItem(item, count)
    count = count or 1
    return GetItemCount(item) >= count
end

-- Request inventory update
function RequestInventoryUpdate()
    TriggerServerEvent('bloggrs:getInventory')
end

-- Initialize inventory on resource start
Citizen.CreateThread(function()
    Citizen.Wait(1000) -- Wait for auth to initialize
    RequestInventoryUpdate()
end)

-- Export functions
exports('CalculateInventoryWeight', CalculateInventoryWeight)
exports('CanCarryItem', CanCarryItem)
exports('GetItemCount', GetItemCount)
exports('HasItem', HasItem)
exports('RequestInventoryUpdate', RequestInventoryUpdate)
