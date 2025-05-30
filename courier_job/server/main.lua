-- Initialize database
AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    
    if not MySQL then
        print("^1[ERROR] MySQL module not found. Ensure mysql-async is started before courier_job^7")
        return
    end
    
    -- Check if inventory table exists, if not create it
    MySQL.ready(function()
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
        ]], {}, function(rowsChanged)
            print("^2Bloggrs Courier Job initialized^7")
        end)
    end)
end)

-- Function to add item to inventory with error handling
function AddItemToInventory(userId, item, count, source)
    if not MySQL then
        TriggerClientEvent('bloggrs:showNotification', source, "Database error occurred", "error")
        return
    end
    
    -- Check if item already exists in inventory
    MySQL.Async.fetchAll("SELECT * FROM " .. Config.InventoryTable .. " WHERE user_id = @userId AND item = @item", {
        ['@userId'] = userId,
        ['@item'] = item
    }, function(result)
        if result then
            if #result > 0 then
                -- Update existing item
                MySQL.Async.execute("UPDATE " .. Config.InventoryTable .. " SET count = count + @count, last_updated = CURRENT_TIMESTAMP WHERE user_id = @userId AND item = @item", {
                    ['@userId'] = userId,
                    ['@item'] = item,
                    ['@count'] = count
                }, function(rowsChanged)
                    if rowsChanged > 0 then
                        TriggerClientEvent('bloggrs:showNotification', source, "Inventory updated successfully", "success")
                    else
                        TriggerClientEvent('bloggrs:showNotification', source, "Failed to update inventory", "error")
                    end
                end)
            else
                -- Add new item
                MySQL.Async.execute("INSERT INTO " .. Config.InventoryTable .. " (user_id, item, count) VALUES (@userId, @item, @count)", {
                    ['@userId'] = userId,
                    ['@item'] = item,
                    ['@count'] = count
                }, function(rowsChanged)
                    if rowsChanged > 0 then
                        TriggerClientEvent('bloggrs:showNotification', source, "Item added to inventory", "success")
                    else
                        TriggerClientEvent('bloggrs:showNotification', source, "Failed to add item to inventory", "error")
                    end
                end)
            end
        else
            TriggerClientEvent('bloggrs:showNotification', source, "Database error occurred", "error")
        end
    end)
end

-- Function to get user ID from username with error handling
function GetUserIdFromUsername(username, callback, source)
    if not MySQL then
        TriggerClientEvent('bloggrs:showNotification', source, "Database error occurred", "error")
        callback(nil)
        return
    end
    
    MySQL.Async.fetchScalar("SELECT id FROM bloggrs_users WHERE username = @username", {
        ['@username'] = username
    }, function(userId)
        callback(userId)
    end)
end

-- Function to find a safe spawn point near the player
function FindSafeSpawnPoint(playerCoords)
    if not playerCoords then
        print("^1[ERROR] Invalid player coordinates in FindSafeSpawnPoint^7")
        return nil
    end
    
    -- Convert playerCoords to vector3 if it's not already
    local pCoords
    if type(playerCoords) == "vector3" then
        pCoords = playerCoords
    elseif type(playerCoords) == "table" then
        if playerCoords.x and playerCoords.y and playerCoords.z then
            pCoords = vector3(playerCoords.x + 0.0, playerCoords.y + 0.0, playerCoords.z + 0.0)
        elseif #playerCoords >= 3 then
            pCoords = vector3(playerCoords[1] + 0.0, playerCoords[2] + 0.0, playerCoords[3] + 0.0)
        else
            print("^1[ERROR] Invalid player coordinates format^7")
            return nil
        end
    else
        print("^1[ERROR] Invalid player coordinates type^7")
        return nil
    end
    
    -- Simple offset from player position
    local offset = Config.VehicleSpawnDistance or 5.0
    local offsetX = math.cos(math.rad(0)) * offset
    local offsetY = math.sin(math.rad(0)) * offset
    
    return {
        coords = vector3(pCoords.x + offsetX, pCoords.y + offsetY, pCoords.z),
        heading = 0.0
    }
end

-- Function to spawn a vehicle for the courier job
function SpawnCourierVehicle(source)
    local player = source
    local playerPed = GetPlayerPed(player)
    local playerCoords = GetEntityCoords(playerPed)
    
    print(string.format("^3[DEBUG] Spawning vehicle for player at coords: x=%.2f, y=%.2f, z=%.2f^7",
        playerCoords.x, playerCoords.y, playerCoords.z))
    
    -- Find a safe spawn location near the player
    local spawnPoint = FindSafeSpawnPoint(playerCoords)
    if not spawnPoint then
        print("^1[ERROR] Could not find safe spawn point^7")
        TriggerClientEvent('bloggrs:showNotification', player, "Could not find safe spawn point", "error")
        return
    end
    
    print(string.format("^3[DEBUG] Found spawn point at: x=%.2f, y=%.2f, z=%.2f, heading=%.2f^7",
        spawnPoint.coords.x, spawnPoint.coords.y, spawnPoint.coords.z, spawnPoint.heading))
    
    -- Spawn the vehicle
    local vehicleHash = GetHashKey(Config.CourierVehicle)
    
    -- Create the vehicle using the vec3 coordinates
    local vehicle = CreateVehicle(vehicleHash, 
        spawnPoint.coords.x, 
        spawnPoint.coords.y, 
        spawnPoint.coords.z, 
        spawnPoint.heading, 
        true, -- isNetwork
        false -- netMissionEntity
    )
    
    if not vehicle or vehicle == 0 then
        print("^1[ERROR] Failed to create vehicle^7")
        TriggerClientEvent('bloggrs:showNotification', player, "Failed to spawn vehicle", "error")
        return
    end
    
    print(string.format("^2[DEBUG] Created vehicle with handle: %s^7", tostring(vehicle)))
    
    -- Set vehicle properties
    SetVehicleNumberPlateText(vehicle, "COURIER")
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleDoorsLocked(vehicle, 0) -- Unlock the vehicle
    
    -- Ensure the vehicle is networked
    NetworkRegisterEntityAsNetworked(vehicle)
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    SetNetworkIdExistsOnAllMachines(netId, true)
    SetNetworkIdCanMigrate(netId, true)
    
    print(string.format("^2[DEBUG] Vehicle spawned successfully with netId: %s^7", tostring(netId)))
    
    -- Send the vehicle network ID to the client
    TriggerClientEvent('bloggrs:courier:vehicleSpawned', player, netId)
end

-- Complete courier job event with better error handling
RegisterNetEvent('bloggrs:courier:completeJob')
AddEventHandler('bloggrs:courier:completeJob', function(totalReward)
    local source = source
    
    -- Check if player is logged in using the auth resource
    local isLoggedIn = exports['bloggrs_auth']:IsPlayerLoggedIn(source)
    
    if not isLoggedIn then
        TriggerClientEvent('bloggrs:showNotification', source, Config.Messages.NotLoggedIn, "error")
        return
    end
    
    local username = exports['bloggrs_auth']:GetPlayerUsername(source)
    if not username then
        TriggerClientEvent('bloggrs:showNotification', source, "Could not get player username", "error")
        return
    end
    
    -- Get user ID from username
    GetUserIdFromUsername(username, function(userId)
        if userId then
            -- Add final reward to inventory
            AddItemToInventory(userId, "weed", totalReward, source)
        else
            TriggerClientEvent('bloggrs:showNotification', source, "Could not find your user account", "error")
        end
    end, source)
end)

-- Checkpoint reached event for immediate rewards
RegisterNetEvent('bloggrs:courier:checkpointReached')
AddEventHandler('bloggrs:courier:checkpointReached', function(reward)
    local source = source
    
    -- Check if player is logged in using the auth resource
    local isLoggedIn = exports['bloggrs_auth']:IsPlayerLoggedIn(source)
    
    if not isLoggedIn then
        TriggerClientEvent('bloggrs:showNotification', source, Config.Messages.NotLoggedIn, "error")
        return
    end
    
    local username = exports['bloggrs_auth']:GetPlayerUsername(source)
    if not username then
        TriggerClientEvent('bloggrs:showNotification', source, "Could not get player username", "error")
        return
    end
    
    -- Get user ID from username
    GetUserIdFromUsername(username, function(userId)
        if userId then
            -- Add checkpoint reward to inventory
            AddItemToInventory(userId, "weed", reward, source)
        else
            TriggerClientEvent('bloggrs:showNotification', source, "Could not find your user account", "error")
        end
    end, source)
end)

-- Consistent notification event naming
RegisterNetEvent('bloggrs:showNotification')
AddEventHandler('bloggrs:showNotification', function(message, type)
    local source = source
    TriggerClientEvent('bloggrs:showNotification', source, message, type)
end)

-- Vehicle request event
RegisterNetEvent('bloggrs:courier:requestJobVehicle')
AddEventHandler('bloggrs:courier:requestJobVehicle', function()
    local source = source
    
    -- Check if player is logged in using the auth resource
    local isLoggedIn = exports['bloggrs_auth']:IsPlayerLoggedIn(source)
    
    if not isLoggedIn then
        TriggerClientEvent('bloggrs:showNotification', source, Config.Messages.NotLoggedIn, "error")
        return
    end
    
    -- Spawn the vehicle for the player
    SpawnCourierVehicle(source)
end)
