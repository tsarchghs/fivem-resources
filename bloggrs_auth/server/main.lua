local activeSessions = {}

-- Initialize database
AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    
    -- Check if table exists, if not create it
    exports['mysql-async']:mysql_execute([[
        CREATE TABLE IF NOT EXISTS `]]..Config.DatabaseTable..[[` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `username` VARCHAR(50) NOT NULL UNIQUE,
            `password` VARCHAR(255) NOT NULL,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            `last_login` TIMESTAMP NULL,
            `is_admin` BOOLEAN DEFAULT FALSE
        )
    ]])
    print("^2Bloggrs Authentication System initialized^7")
end)

-- Hash password function (using a simple hash for demonstration)
-- In production, use a proper password hashing library
local function HashPassword(password)
    return password -- Replace with proper hashing in production
end

-- Verify password
local function VerifyPassword(password, hashedPassword)
    return password == hashedPassword -- Replace with proper verification in production
end

-- Register command
RegisterCommand("register", function(source, args, rawCommand)
    local player = source
    
    -- Validate input
    if #args < 2 then
        TriggerClientEvent('bloggrs:notification', player, Config.Messages.UsageRegister, "error")
        return
    end
    
    local username = args[1]
    local password = args[2]
    
    -- Validate username and password length
    if string.len(username) < Config.MinUsernameLength then
        TriggerClientEvent('bloggrs:notification', player, Config.Messages.InvalidUsername, "error")
        return
    end
    
    if string.len(password) < Config.MinPasswordLength then
        TriggerClientEvent('bloggrs:notification', player, Config.Messages.InvalidPassword, "error")
        return
    end
    
    -- Check if username already exists using a more reliable approach
    local query = 'SELECT 1 FROM `'..Config.DatabaseTable..'` WHERE `username` = ? LIMIT 1'
    local params = {username}
    
    exports['mysql-async']:mysql_fetch_all(query, params, function(result)
        if result and #result > 0 then
            TriggerClientEvent('bloggrs:notification', player, Config.Messages.UserExists, "error")
            return
        end
        
        -- Hash the password
        local hashedPassword = HashPassword(password)
        
        -- Insert new user
        local insertQuery = 'INSERT INTO `'..Config.DatabaseTable..'` (`username`, `password`) VALUES (?, ?)'
        local insertParams = {username, hashedPassword}
        
        exports['mysql-async']:mysql_execute(insertQuery, insertParams, function(rowsChanged)
            if rowsChanged and rowsChanged > 0 then
                -- Create session
                activeSessions[player] = {
                    username = username,
                    timestamp = os.time(),
                    isAdmin = false
                }
                
                print("^3[DEBUG] Player registered successfully: " .. username .. "^7")
                
                -- Send registration success UI to client
                TriggerClientEvent('bloggrs:showRegisterSuccess', player, username)
                TriggerClientEvent('bloggrs:notification', player, Config.Messages.RegisterSuccess, "success")
                
                -- After successful registration in the register command handler
                print("^3[DEBUG] Triggering onPlayerRegister event for: " .. username .. "^7")
                TriggerEvent('bloggrs:onPlayerRegister', username)
            else
                print("^1[ERROR] Registration failed for username: " .. username .. "^7")
                TriggerClientEvent('bloggrs:notification', player, "Registration failed. Please try again.", "error")
            end
        end)
    end)
end, false)

-- Login command
RegisterCommand("login", function(source, args, rawCommand)
    local player = source
    
    -- Validate input
    if #args < 2 then
        TriggerClientEvent('bloggrs:notification', player, Config.Messages.UsageLogin, "error")
        return
    end
    
    local username = args[1]
    local password = args[2]
    
    -- Check if user exists and get password
    local query = 'SELECT `id`, `password`, `is_admin` FROM `'..Config.DatabaseTable..'` WHERE `username` = ? LIMIT 1'
    local params = {username}
    
    exports['mysql-async']:mysql_fetch_all(query, params, function(results)
        if not results or #results == 0 then
            TriggerClientEvent('bloggrs:notification', player, Config.Messages.UserNotFound, "error")
            return
        end
        
        local userId = results[1].id
        local hashedPassword = results[1].password
        local isAdmin = results[1].is_admin
        
        -- Verify password
        if not VerifyPassword(password, hashedPassword) then
            TriggerClientEvent('bloggrs:notification', player, Config.Messages.IncorrectPassword, "error")
            return
        end
        
        -- Update last login
        local updateQuery = 'UPDATE `'..Config.DatabaseTable..'` SET `last_login` = CURRENT_TIMESTAMP WHERE `id` = ?'
        local updateParams = {userId}
        
        exports['mysql-async']:mysql_execute(updateQuery, updateParams)
        
        -- Create session
        activeSessions[player] = {
            username = username,
            timestamp = os.time(),
            isAdmin = isAdmin
        }
        
        print("^3[DEBUG] Player logged in successfully: " .. username .. "^7")
        
        -- Send login success UI to client
        TriggerClientEvent('bloggrs:showLoginSuccess', player, username, isAdmin)
        TriggerClientEvent('bloggrs:notification', player, Config.Messages.LoginSuccess, "success")
        
        -- After successful login in the login command handler
        print("^3[DEBUG] Triggering onPlayerLogin event for: " .. username .. "^7")
        TriggerEvent('bloggrs:onPlayerLogin', username)
    end)
end, false)

-- Check session status
function IsPlayerLoggedIn(playerId)
    if activeSessions[playerId] then
        local sessionTime = os.time() - activeSessions[playerId].timestamp
        if sessionTime > (Config.SessionTimeout * 60) then
            -- Session expired
            activeSessions[playerId] = nil
            return false
        end
        return true
    end
    return false
end

-- Get player username
function GetPlayerUsername(playerId)
    if IsPlayerLoggedIn(playerId) then
        return activeSessions[playerId].username
    end
    return nil
end

-- Check if player is admin
function IsPlayerAdmin(playerId)
    if IsPlayerLoggedIn(playerId) then
        return activeSessions[playerId].isAdmin
    end
    return false
end

-- Export functions
exports('IsPlayerLoggedIn', IsPlayerLoggedIn)
exports('GetPlayerUsername', GetPlayerUsername)
exports('IsPlayerAdmin', IsPlayerAdmin)

-- Handle player disconnect
AddEventHandler('playerDropped', function()
    local source = source
    activeSessions[source] = nil
end)

-- Admin command to list all online users
RegisterCommand("users", function(source, args, rawCommand)
    local player = source
    
    if not IsPlayerAdmin(player) then
        TriggerClientEvent('bloggrs:notification', player, "You don't have permission to use this command.", "error")
        return
    end
    
    local onlineUsers = {}
    for playerId, session in pairs(activeSessions) do
        table.insert(onlineUsers, {
            id = playerId,
            username = session.username,
            loginTime = os.date("%H:%M:%S", session.timestamp)
        })
    end
    
    TriggerClientEvent('bloggrs:showOnlineUsers', player, onlineUsers)
end, false)
