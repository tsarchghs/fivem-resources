-- Local cache for player inventories
local playerInventories = {}

-- Function to load player inventory from database
function LoadPlayerInventory(source, userId)
    MySQL.Async.fetchAll('SELECT * FROM bloggrs_inventory WHERE user_id = @userId', {
        ['@userId'] = userId
    }, function(results)
        local inventory = {}
        
        -- Format inventory data directly from database results
        for _, item in ipairs(results) do
            inventory[item.item] = {
                count = item.count,
                label = item.item:gsub("^%l", string.upper), -- Capitalize first letter
                data = {
                    weight = 0.1, -- Default weight if needed
                    description = "Item from inventory",
                    category = "misc"
                }
            }
        end
        
        -- Cache inventory
        playerInventories[source] = {
            userId = userId,
            inventory = inventory
        }
        
        -- Send to client
        TriggerClientEvent('bloggrs:setInventory', source, inventory)
    end)
end

-- Get player inventory
RegisterNetEvent('bloggrs:getInventory')
AddEventHandler('bloggrs:getInventory', function()
    local source = source
    local userId = exports.bloggrs_auth:GetUserId(source)
    
    if not userId then
        TriggerClientEvent('bloggrs:notification', source, "Not authenticated.", "error")
        return
    end
    
    if not playerInventories[source] then
        LoadPlayerInventory(source, userId)
    else
        TriggerClientEvent('bloggrs:setInventory', source, playerInventories[source].inventory)
    end
end)

-- Add item to player inventory
RegisterNetEvent('bloggrs:addItem')
AddEventHandler('bloggrs:addItem', function(item, count)
    local source = source
    local userId = exports.bloggrs_auth:GetUserId(source)
    count = count or 1
    
    if not userId then
        TriggerClientEvent('bloggrs:notification', source, "Not authenticated.", "error")
        return
    end
    
    -- Check if item exists
    if not Items[item] then
        TriggerClientEvent('bloggrs:notification', source, "Item does not exist.", "error")
        return
    end
    
    -- Check if player has inventory loaded
    if not playerInventories[source] then
        LoadPlayerInventory(source, userId)
        TriggerClientEvent('bloggrs:notification', source, "Please try again in a moment.", "info")
        return
    end
    
    -- Check if player already has this item
    if playerInventories[source].inventory[item] then
        -- Update count in memory
        playerInventories[source].inventory[item].count = playerInventories[source].inventory[item].count + count
        
        -- Update count in database
        MySQL.Async.execute('UPDATE bloggrs_inventory SET count = count + @count, last_updated = NOW() WHERE user_id = @userId AND item = @item', {
            ['@count'] = count,
            ['@userId'] = userId,
            ['@item'] = item
        }, function(rowsChanged)
            if rowsChanged > 0 then
                TriggerClientEvent('bloggrs:setInventory', source, playerInventories[source].inventory)
                TriggerClientEvent('bloggrs:notification', source, "Added " .. count .. "x " .. Items[item].label .. " to your inventory.", "success")
            else
                TriggerClientEvent('bloggrs:notification', source, "Failed to add item to inventory.", "error")
            end
        end)
    else
        -- Add new item to memory
        playerInventories[source].inventory[item] = {
            count = count,
            label = GetItemLabel(item),
            data = GetItemData(item)
        }
        
        -- Add new item to database
        MySQL.Async.execute('INSERT INTO bloggrs_inventory (user_id, item, count, created_at, last_updated) VALUES (@userId, @item, @count, NOW(), NOW())', {
            ['@userId'] = userId,
            ['@item'] = item,
            ['@count'] = count
        }, function(rowsChanged)
            if rowsChanged > 0 then
                TriggerClientEvent('bloggrs:setInventory', source, playerInventories[source].inventory)
                TriggerClientEvent('bloggrs:notification', source, "Added " .. count .. "x " .. Items[item].label .. " to your inventory.", "success")
            else
                TriggerClientEvent('bloggrs:notification', source, "Failed to add item to inventory.", "error")
            end
        end)
    end
end)

-- Remove item from player inventory
RegisterNetEvent('bloggrs:removeItem')
AddEventHandler('bloggrs:removeItem', function(item, count)
    local source = source
    local userId = exports.bloggrs_auth:GetUserId(source)
    count = count or 1
    
    if not userId then
        TriggerClientEvent('bloggrs:notification', source, "Not authenticated.", "error")
        return
    end
    
    -- Check if player has inventory loaded
    if not playerInventories[source] then
        LoadPlayerInventory(source, userId)
        TriggerClientEvent('bloggrs:notification', source, "Please try again in a moment.", "info")
        return
    end
    
    -- Check if player has this item
    if not playerInventories[source].inventory[item] or playerInventories[source].inventory[item].count < count then
        TriggerClientEvent('bloggrs:notification', source, "You don't have enough of this item.", "error")
        return
    end
    
    -- Update count in memory
    playerInventories[source].inventory[item].count = playerInventories[source].inventory[item].count - count
    
    -- If count is 0, remove item
    if playerInventories[source].inventory[item].count <= 0 then
        -- Remove from memory
        playerInventories[source].inventory[item] = nil
        
        -- Remove from database
        MySQL.Async.execute('DELETE FROM bloggrs_inventory WHERE user_id = @userId AND item = @item', {
            ['@userId'] = userId,
            ['@item'] = item
        }, function(rowsChanged)
            if rowsChanged > 0 then
                TriggerClientEvent('bloggrs:setInventory', source, playerInventories[source].inventory)
                TriggerClientEvent('bloggrs:notification', source, "Removed " .. count .. "x " .. GetItemLabel(item) .. " from your inventory.", "info")
            else
                TriggerClientEvent('bloggrs:notification', source, "Failed to remove item from inventory.", "error")
            end
        end)
    else
        -- Update count in database
        MySQL.Async.execute('UPDATE bloggrs_inventory SET count = count - @count, last_updated = NOW() WHERE user_id = @userId AND item = @item', {
            ['@count'] = count,
            ['@userId'] = userId,
            ['@item'] = item
        }, function(rowsChanged)
            if rowsChanged > 0 then
                TriggerClientEvent('bloggrs:setInventory', source, playerInventories[source].inventory)
                TriggerClientEvent('bloggrs:notification', source, "Removed " .. count .. "x " .. GetItemLabel(item) .. " from your inventory.", "info")
            else
                TriggerClientEvent('bloggrs:notification', source, "Failed to remove item from inventory.", "error")
            end
        end)
    end
end)

-- Use item from inventory
RegisterNetEvent('bloggrs:useItem')
AddEventHandler('bloggrs:useItem', function(item)
    local source = source
    local userId = exports.bloggrs_auth:GetUserId(source)
    
    if not userId then
        TriggerClientEvent('bloggrs:notification', source, "Not authenticated.", "error")
        return
    end
    
    -- Check if player has inventory loaded
    if not playerInventories[source] then
        LoadPlayerInventory(source, userId)
        TriggerClientEvent('bloggrs:notification', source, "Please try again in a moment.", "info")
        return
    end
    
    -- Check if player has this item
    if not playerInventories[source].inventory[item] or playerInventories[source].inventory[item].count < 1 then
        TriggerClientEvent('bloggrs:notification', source, "You don't have this item.", "error")
        return
    end
    
    -- Check if item can be used
    local itemData = GetItemData(item)
    if not itemData or not itemData.canUse then
        TriggerClientEvent('bloggrs:notification', source, "This item cannot be used.", "error")
        return
    end
    
    -- Apply item effect
    if Config.ItemEffects[item] then
        Config.ItemEffects[item](source)
    end
    
    -- Remove one item after use
    TriggerEvent('bloggrs:removeItem', source, item, 1)
    
    -- Notify client about item use
    TriggerClientEvent('bloggrs:itemUsed', source, item)
end)

-- Transfer item to another player
RegisterNetEvent('bloggrs:transferItem')
AddEventHandler('bloggrs:transferItem', function(targetId, item, count)
    local source = source
    local userId = exports.bloggrs_auth:GetUserId(source)
    local targetUserId = exports.bloggrs_auth:GetUserId(targetId)
    count = count or 1
    
    if not userId or not targetUserId then
        TriggerClientEvent('bloggrs:notification', source, "Authentication error.", "error")
        return
    end
    
    -- Check if both players have inventory loaded
    if not playerInventories[source] or not playerInventories[targetId] then
        TriggerClientEvent('bloggrs:notification', source, "Please try again in a moment.", "info")
        return
    end
    
    -- Check if player has this item
    if not playerInventories[source].inventory[item] or playerInventories[source].inventory[item].count < count then
        TriggerClientEvent('bloggrs:notification', source, "You don't have enough of this item.", "error")
        return
    end
    
    -- Remove item from source player
    TriggerEvent('bloggrs:removeItem', source, item, count)
    
    -- Add item to target player
    TriggerEvent('bloggrs:addItem', targetId, item, count)
    
    -- Notify both players
    local sourceUsername = exports.bloggrs_auth:GetUsername(source)
    local targetUsername = exports.bloggrs_auth:GetUsername(targetId)
    TriggerClientEvent('bloggrs:notification', source, "You gave " .. count .. "x " .. GetItemLabel(item) .. " to " .. targetUsername .. ".", "info")
    TriggerClientEvent('bloggrs:notification', targetId, "You received " .. count .. "x " .. GetItemLabel(item) .. " from " .. sourceUsername .. ".", "success")
end)

-- Clean up player inventory cache on player drop
AddEventHandler('playerDropped', function()
    local source = source
    if playerInventories[source] then
        playerInventories[source] = nil
    end
end)
