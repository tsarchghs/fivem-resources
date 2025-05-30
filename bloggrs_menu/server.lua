-- server.lua

-- Event handler: client requests updated money
RegisterNetEvent('bloggrs:GetMoney')
AddEventHandler('bloggrs:GetMoney', function()
    local src = source
    
    -- Check if player is logged in via auth system
    local isLoggedIn = exports.bloggrs_auth:IsPlayerLoggedIn(src)
    if not isLoggedIn then
        TriggerClientEvent('bloggrs:UpdateMoney', src, 0, 0)
        TriggerClientEvent('bloggrs:notification', src, "You must be logged in to access your money.", "error")
        return
    end
    
    -- Get player username from auth system
    local username = exports.bloggrs_auth:GetPlayerUsername(src)
    if not username then
        TriggerClientEvent('bloggrs:UpdateMoney', src, 0, 0)
        TriggerClientEvent('bloggrs:notification', src, "Could not retrieve player data.", "error")
        return
    end

    -- Query the database for cash and bank using the correct table names
    MySQL.Async.fetchAll([[
        SELECT p.cash, p.bank 
        FROM bloggrs_users u 
        LEFT JOIN bloggrs_players p ON p.user_id = u.id 
        WHERE u.username = @username
    ]], {
        ['@username'] = username
    }, function(results)
        if results[1] then
            local cash = results[1].cash or 1000 -- Use default value if null
            local bank = results[1].bank or 5000 -- Use default value if null
            -- Send the data back to the client
            TriggerClientEvent('bloggrs:UpdateMoney', src, cash, bank)
        else
            -- No record found; create new player data
            MySQL.Async.fetchScalar('SELECT id FROM bloggrs_users WHERE username = @username', {
                ['@username'] = username
            }, function(userId)
                if userId then
                    -- Create new player data entry with default values
                    MySQL.Async.execute('INSERT INTO bloggrs_players (user_id, cash, bank) VALUES (@userId, 1000, 5000)', {
                        ['@userId'] = userId
                    }, function()
                        -- Send initial money values to client
                        TriggerClientEvent('bloggrs:UpdateMoney', src, 1000, 5000)
                    end)
                else
                    -- Something went wrong, send zeros
                    TriggerClientEvent('bloggrs:UpdateMoney', src, 0, 0)
                    TriggerClientEvent('bloggrs:notification', src, "Failed to initialize player data.", "error")
                end
            end)
        end
    end)
end)

-- Event handler: client requests server time
RegisterNetEvent('bloggrs:GetTime')
AddEventHandler('bloggrs:GetTime', function()
    local src = source
    -- Get current server time in HH:MM format
    local hour = tonumber(os.date("%H"))
    local min = tonumber(os.date("%M"))
    local timeStr = string.format("%02d:%02d", hour, min)
    -- Send time back to client
    TriggerClientEvent('bloggrs:UpdateTime', src, timeStr)
end)

-- Ensure MySQL is ready (optional; this runs when resource starts if needed)
MySQL.ready(function()
    -- Initialize tables if they don't exist
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS player_data (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT NOT NULL,
            cash INT DEFAULT 0,
            bank INT DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES bloggrs_users(id) ON DELETE CASCADE
        )
    ]], {}, function(success)
        if success then
            print("^2Player data table initialized^7")
        end
    end)
end)
