-- Local variables
local playersData = {}

-- Initialize database
AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    
    -- Check if player table exists, if not create it
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `]]..Config.PlayerTable..[[` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `user_id` INT NOT NULL,
            `cash` INT DEFAULT ]]..Config.StartingCash..[[,
            `bank` INT DEFAULT ]]..Config.StartingBank..[[,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            FOREIGN KEY (`user_id`) REFERENCES `bloggrs_users`(`id`) ON DELETE CASCADE
        )
    ]], {}, function(rowsChanged)
        print("^2Bloggrs Player Menu initialized^7")
    end)
end)

-- When player connects, load their data
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local source = source
    deferrals.defer()
    deferrals.update("Checking player data...")
    
    -- Wait a moment to ensure auth system is ready
    Citizen.Wait(1000)
    
    deferrals.update("Loading player data...")
    -- Continue connection
    deferrals.done()
end)

-- Handle player data request
RegisterNetEvent('bloggrs:requestPlayerData')
AddEventHandler('bloggrs:requestPlayerData', function()
    local source = source
    print("^3[DEBUG] Received player data request from source:", source, "^7")
    
    -- Check if player is logged in via auth system
    local isLoggedIn = exports.bloggrs_auth:IsPlayerLoggedIn(source)
    print("^3[DEBUG] Is player logged in:", isLoggedIn, "^7")
    
    if not isLoggedIn then
        print("^1[ERROR] Player not logged in^7")
        TriggerClientEvent('bloggrs:notification', source, "You must be logged in to access player data.", "error")
        return
    end
    
    -- Get player username from auth system
    local username = exports.bloggrs_auth:GetPlayerUsername(source)
    print("^3[DEBUG] Retrieved username:", username, "^7")
    
    if not username then
        print("^1[ERROR] Could not retrieve username from auth system^7")
        TriggerClientEvent('bloggrs:notification', source, "Could not retrieve player data.", "error")
        return
    end
    
    -- Get user ID from database
    MySQL.Async.fetchScalar('SELECT `id` FROM `bloggrs_users` WHERE `username` = @username', {
        ['@username'] = username
    }, function(userId)
        print("^3[DEBUG] Retrieved user ID:", userId, "^7")
        
        if not userId then
            print("^1[ERROR] User not found in database^7")
            TriggerClientEvent('bloggrs:notification', source, "User not found in database.", "error")
            return
        end
        
        -- Check if player data exists
        MySQL.Async.fetchAll('SELECT * FROM `'..Config.PlayerTable..'` WHERE `user_id` = @userId', {
            ['@userId'] = userId
        }, function(results)
            print("^3[DEBUG] Player data results:", json.encode(results), "^7")
            
            if #results == 0 then
                print("^3[DEBUG] Creating new player data^7")
                -- Create new player data
                MySQL.Async.execute('INSERT INTO `'..Config.PlayerTable..'` (`user_id`) VALUES (@userId)', {
                    ['@userId'] = userId
                }, function(rowsChanged)
                    print("^3[DEBUG] New player data rows changed:", rowsChanged, "^7")
                    
                    if rowsChanged > 0 then
                        -- Get the newly created player data
                        MySQL.Async.fetchAll('SELECT * FROM `'..Config.PlayerTable..'` WHERE `user_id` = @userId', {
                            ['@userId'] = userId
                        }, function(newResults)
                            print("^3[DEBUG] New player data results:", json.encode(newResults), "^7")
                            
                            if #newResults > 0 then
                                -- Store player data
                                playersData[source] = {
                                    userId = userId,
                                    username = username,
                                    cash = newResults[1].cash,
                                    bank = newResults[1].bank
                                }
                                
                                print("^2[INFO] Created new player data^7")
                                print("^3[DEBUG] Stored player data:", json.encode(playersData[source]), "^7")
                                
                                -- Create default inventory for new player
                                CreateDefaultInventory(source, userId)
                                
                                -- Send player data to client
                                TriggerClientEvent('bloggrs:setPlayerData', source, playersData[source])
                                TriggerClientEvent('bloggrs:notification', source, "Player data created successfully!", "success")
                            else
                                print("^1[ERROR] Failed to retrieve newly created player data^7")
                                TriggerClientEvent('bloggrs:notification', source, "Failed to create player data.", "error")
                            end
                        end)
                    else
                        print("^1[ERROR] Failed to create new player data^7")
                        TriggerClientEvent('bloggrs:notification', source, "Failed to create player data.", "error")
                    end
                end)
            else
                -- Store existing player data
                playersData[source] = {
                    userId = userId,
                    username = username,
                    cash = results[1].cash,
                    bank = results[1].bank
                }
                
                print("^2[INFO] Loaded existing player data^7")
                print("^3[DEBUG] Stored player data:", json.encode(playersData[source]), "^7")
                
                -- Load player inventory
                LoadPlayerInventory(source, userId)
                
                -- Send player data to client
                TriggerClientEvent('bloggrs:setPlayerData', source, playersData[source])
                TriggerClientEvent('bloggrs:notification', source, "Player data loaded successfully!", "success")
            end
        end)
    end)
end)

-- Create default inventory for new player
function CreateDefaultInventory(source, userId)
    -- First check if inventory table exists
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `]]..Config.InventoryTable..[[` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `user_id` INT NOT NULL,
            `item` VARCHAR(50) NOT NULL,
            `count` INT NOT NULL DEFAULT 1,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            FOREIGN KEY (`user_id`) REFERENCES `bloggrs_users`(`id`) ON DELETE CASCADE
        )
    ]], {}, function()
        -- Add default items
        for _, itemData in ipairs(Config.DefaultItems) do
            MySQL.Async.execute('INSERT INTO `'..Config.InventoryTable..'` (`user_id`, `item`, `count`) VALUES (@userId, @item, @count)', {
                ['@userId'] = userId,
                ['@item'] = itemData.item,
                ['@count'] = itemData.count
            })
        end
        
        -- Load the newly created inventory
        LoadPlayerInventory(source, userId)
    end)
end

-- Load player inventory from database
function LoadPlayerInventory(source, userId)
    MySQL.Async.fetchAll('SELECT * FROM `'..Config.InventoryTable..'` WHERE `user_id` = @userId', {
        ['@userId'] = userId
    }, function(results)
        local inventory = {}
        
        for _, item in ipairs(results) do
            inventory[item.item] = {
                count = item.count,
                label = GetItemLabel(item.item),
                data = GetItemData(item.item)
            }
        end
        
        -- Store inventory in player data
        if playersData[source] then
            playersData[source].inventory = inventory
        end
        
        -- Send inventory to client
        TriggerClientEvent('bloggrs:setInventory', source, inventory)
    end)
end

-- Get player money
RegisterNetEvent('bloggrs:getMoney')
AddEventHandler('bloggrs:getMoney', function(type)
    local source = source
    
    if not playersData[source] then
        TriggerClientEvent('bloggrs:notification', source, "Player data not loaded.", "error")
        return
    end
    
    if type == "cash" then
        return playersData[source].cash
    elseif type == "bank" then
        return playersData[source].bank
    end
    
    return 0
end)

-- Update player money
RegisterNetEvent('bloggrs:updateMoney')
AddEventHandler('bloggrs:updateMoney', function(type, amount)
    local source = source
    
    if not playersData[source] then
        TriggerClientEvent('bloggrs:notification', source, "Player data not loaded.", "error")
        return
    end
    
    if type ~= "cash" and type ~= "bank" then
        TriggerClientEvent('bloggrs:notification', source, "Invalid money type.", "error")
        return
    end
    
    -- Update money in memory
    playersData[source][type] = amount
    
    -- Update money in database
    MySQL.Async.execute('UPDATE `'..Config.PlayerTable..'` SET `'..type..'` = @amount WHERE `user_id` = @userId', {
        ['@amount'] = amount,
        ['@userId'] = playersData[source].userId
    }, function(rowsChanged)
        if rowsChanged > 0 then
            -- Send updated player data to client
            TriggerClientEvent('bloggrs:setPlayerData', source, playersData[source])
        else
            TriggerClientEvent('bloggrs:notification', source, "Failed to update money.", "error")
        end
    end)
end)

-- Add money to player
RegisterNetEvent('bloggrs:addMoney')
AddEventHandler('bloggrs:addMoney', function(type, amount)
    local source = source
    
    if not playersData[source] then
        TriggerClientEvent('bloggrs:notification', source, "Player data not loaded.", "error")
        return
    end
    
    if type ~= "cash" and type ~= "bank" then
        TriggerClientEvent('bloggrs:notification', source, "Invalid money type.", "error")
        return
    end
    
    -- Update money in memory
    playersData[source][type] = playersData[source][type] + amount
    
    -- Update money in database
    MySQL.Async.execute('UPDATE `'..Config.PlayerTable..'` SET `'..type..'` = `'..type..'` + @amount WHERE `user_id` = @userId', {
        ['@amount'] = amount,
        ['@userId'] = playersData[source].userId
    }, function(rowsChanged)
        if rowsChanged > 0 then
            -- Send updated player data to client
            TriggerClientEvent('bloggrs:setPlayerData', source, playersData[source])
            TriggerClientEvent('bloggrs:notification', source, "Added $" .. amount .. " to your " .. Config.MoneyTypes[type] .. ".", "success")
        else
            TriggerClientEvent('bloggrs:notification', source, "Failed to add money.", "error")
        end
    end)
end)

-- Remove money from player
RegisterNetEvent('bloggrs:removeMoney')
AddEventHandler('bloggrs:removeMoney', function(type, amount)
    local source = source
    
    if not playersData[source] then
        TriggerClientEvent('bloggrs:notification', source, "Player data not loaded.", "error")
        return
    end
    
    if type ~= "cash" and type ~= "bank" then
        TriggerClientEvent('bloggrs:notification', source, "Invalid money type.", "error")
        return
    end
    
    -- Check if player has enough money
    if playersData[source][type] < amount then
        TriggerClientEvent('bloggrs:notification', source, "Not enough money.", "error")
        return false
    end
    
    -- Update money in memory
    playersData[source][type] = playersData[source][type] - amount
    
    -- Update money in database
    MySQL.Async.execute('UPDATE `'..Config.PlayerTable..'` SET `'..type..'` = `'..type..'` - @amount WHERE `user_id` = @userId', {
        ['@amount'] = amount,
        ['@userId'] = playersData[source].userId
    }, function(rowsChanged)
        if rowsChanged > 0 then
            -- Send updated player data to client
            TriggerClientEvent('bloggrs:setPlayerData', source, playersData[source])
            TriggerClientEvent('bloggrs:notification', source, "Removed $" .. amount .. " from your " .. Config.MoneyTypes[type] .. ".", "info")
            return true
        else
            TriggerClientEvent('bloggrs:notification', source, "Failed to remove money.", "error")
            return false
        end
    end)
end)

-- Transfer money between cash and bank
RegisterNetEvent('bloggrs:transferMoney')
AddEventHandler('bloggrs:transferMoney', function(from, to, amount)
    local source = source
    
    if not playersData[source] then
        TriggerClientEvent('bloggrs:notification', source, "Player data not loaded.", "error")
        return
    end
    
    if from ~= "cash" and from ~= "bank" then
        TriggerClientEvent('bloggrs:notification', source, "Invalid source money type.", "error")
        return
    end
    
    if to ~= "cash" and to ~= "bank" then
        TriggerClientEvent('bloggrs:notification', source, "Invalid destination money type.", "error")
        return
    end
    
    if from == to then
        TriggerClientEvent('bloggrs:notification', source, "Cannot transfer to the same account.", "error")
        return
    end
    
    -- Check if player has enough money
    if playersData[source][from] < amount then
        TriggerClientEvent('bloggrs:notification', source, "Not enough money in " .. Config.MoneyTypes[from] .. ".", "error")
        return
    end
    
    -- Update money in memory
    playersData[source][from] = playersData[source][from] - amount
    playersData[source][to] = playersData[source][to] + amount
    
    -- Update money in database
    MySQL.Async.execute('UPDATE `'..Config.PlayerTable..'` SET `'..from..'` = `'..from..'` - @amount, `'..to..'` = `'..to..'` + @amount WHERE `user_id` = @userId', {
        ['@amount'] = amount,
        ['@userId'] = playersData[source].userId
    }, function(rowsChanged)
        if rowsChanged > 0 then
            -- Send updated player data to client
            TriggerClientEvent('bloggrs:setPlayerData', source, playersData[source])
            TriggerClientEvent('bloggrs:notification', source, "Transferred $" .. amount .. " from " .. Config.MoneyTypes[from] .. " to " .. Config.MoneyTypes[to] .. ".", "success")
        else
            TriggerClientEvent('bloggrs:notification', source, "Failed to transfer money.", "error")
        end
    end)
end)

-- Handle player disconnect
AddEventHandler('playerDropped', function(reason)
    local source = source
    
    -- Clear player data from memory
    if playersData[source] then
        playersData[source] = nil
    end
end)
