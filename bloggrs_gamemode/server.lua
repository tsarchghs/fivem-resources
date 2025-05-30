-- server.lua

local defaultSpawn = vector4(-1037.7, -2738.7, 13.7, 329.0) -- Airport

-- Listen for successful login
RegisterNetEvent('bloggrs:onPlayerLogin')
AddEventHandler('bloggrs:onPlayerLogin', function(username)
    local src = source
    print("^3[DEBUG] Login event received for player " .. src .. " with username: " .. tostring(username) .. "^7")
    initializeCharacter(src, username)
end)

-- Listen for successful registration
RegisterNetEvent('bloggrs:onPlayerRegister')
AddEventHandler('bloggrs:onPlayerRegister', function(username)
    local src = source
    print("^3[DEBUG] Register event received for player " .. src .. " with username: " .. tostring(username) .. "^7")
    initializeCharacter(src, username)
end)

-- Save position on disconnect
AddEventHandler('playerDropped', function(reason)
    local src = source
    local username = exports.bloggrs_auth:GetPlayerUsername(src)
    if not username then 
        print("^1[ERROR] Could not get username for disconnect save, source: " .. tostring(src) .. "^7")
        return 
    end

    print("^3[DEBUG] Saving position for " .. username .. " on disconnect^7")

    MySQL.Async.fetchScalar('SELECT id FROM bloggrs_users WHERE username = @username', {
        ['@username'] = username
    }, function(user_id)
        if not user_id then 
            print("^1[ERROR] Could not find user_id for disconnect save, username: " .. username .. "^7")
            return 
        end

        -- Get final position
        local ped = GetPlayerPed(src)
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)

        MySQL.Async.execute([[
            UPDATE bloggrs_characters 
            SET pos_x = @x, pos_y = @y, pos_z = @z, pos_heading = @heading 
            WHERE user_id = @user_id
        ]], {
            ['@user_id'] = user_id,
            ['@x'] = coords.x,
            ['@y'] = coords.y,
            ['@z'] = coords.z,
            ['@heading'] = heading
        }, function(rowsChanged)
            if rowsChanged and rowsChanged > 0 then
                print("^2[SUCCESS] Saved disconnect position for " .. username .. "^7")
            else
                print("^1[ERROR] Failed to save disconnect position for " .. username .. "^7")
            end
        end)
    end)
end)

-- Initialize character data
function initializeCharacter(src, username)
    if not username then 
        print("^1[ERROR] initializeCharacter called with nil username for source: " .. tostring(src) .. "^7")
        return 
    end

    print("^3[DEBUG] Starting character initialization for " .. username .. "^7")

    -- Get user_id from username
    MySQL.Async.fetchScalar('SELECT id FROM bloggrs_users WHERE username = @username', {
        ['@username'] = username
    }, function(user_id)
        if not user_id then 
            print("^1[ERROR] Could not find user_id for username: " .. username .. "^7")
            return 
        end

        print("^3[DEBUG] Found user_id: " .. tostring(user_id) .. " for username: " .. username .. "^7")

        -- Check if character exists
        MySQL.Async.fetchAll('SELECT * FROM bloggrs_characters WHERE user_id = @user_id', {
            ['@user_id'] = user_id
        }, function(result)
            print("^3[DEBUG] Character check query completed for user_id: " .. tostring(user_id) .. "^7")
            
            if not result[1] then
                print("^3[DEBUG] No existing character found, creating new one for user_id: " .. tostring(user_id) .. "^7")
                -- Create new character with default values
                local defaultSkin = getRandomDefaultSkin()
                
                local query = [[
                    INSERT INTO bloggrs_characters 
                    (user_id, pos_x, pos_y, pos_z, pos_heading, skin) 
                    VALUES (@user_id, @x, @y, @z, @heading, @skin)
                ]]
                
                local params = {
                    ['@user_id'] = user_id,
                    ['@x'] = defaultSpawn.x,
                    ['@y'] = defaultSpawn.y,
                    ['@z'] = defaultSpawn.z,
                    ['@heading'] = defaultSpawn.w,
                    ['@skin'] = json.encode(defaultSkin)
                }

                print("^3[DEBUG] Executing character creation query with params: " .. json.encode(params) .. "^7")

                MySQL.Async.execute(query, params, function(rowsChanged)
                    if rowsChanged and rowsChanged > 0 then
                        print("^2[SUCCESS] Created new character for " .. username .. " (user_id: " .. tostring(user_id) .. ")^7")
                        -- Spawn player with default values
                        TriggerClientEvent('bloggrs:spawnPlayer', src, defaultSpawn, defaultSkin)
                    else
                        print("^1[ERROR] Failed to create character for " .. username .. " (user_id: " .. tostring(user_id) .. ")^7")
                    end
                end)
            else
                print("^3[DEBUG] Found existing character for " .. username .. ", loading data^7")
                -- Character exists, spawn with saved data without updating position
                local char = result[1]
                local savedPos = vector4(char.pos_x, char.pos_y, char.pos_z, char.pos_heading)
                local skin = json.decode(char.skin or '{}')
                TriggerClientEvent('bloggrs:spawnPlayer', src, savedPos, skin)
                print("^2[SUCCESS] Teleported " .. username .. " to saved position: " .. json.encode(savedPos) .. "^7")
            end
        end)
    end)
end

-- Only save position for first spawn
RegisterNetEvent('bloggrs:firstSpawnComplete')
AddEventHandler('bloggrs:firstSpawnComplete', function()
    local src = source
    local username = exports.bloggrs_auth:GetPlayerUsername(src)
    if not username then 
        print("^1[ERROR] Could not get username for first spawn completion, source: " .. tostring(src) .. "^7")
        return 
    end

    print("^3[DEBUG] First spawn completed for " .. username .. "^7")

    MySQL.Async.fetchScalar('SELECT id FROM bloggrs_users WHERE username = @username', {
        ['@username'] = username
    }, function(user_id)
        if not user_id then 
            print("^1[ERROR] Could not find user_id for first spawn, username: " .. username .. "^7")
            return 
        end

        -- Get current position
        local ped = GetPlayerPed(src)
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)

        MySQL.Async.execute([[
            UPDATE bloggrs_characters 
            SET pos_x = @x, pos_y = @y, pos_z = @z, pos_heading = @heading 
            WHERE user_id = @user_id
        ]], {
            ['@user_id'] = user_id,
            ['@x'] = coords.x,
            ['@y'] = coords.y,
            ['@z'] = coords.z,
            ['@heading'] = heading
        }, function(rowsChanged)
            if rowsChanged and rowsChanged > 0 then
                print("^2[SUCCESS] Saved first spawn position for " .. username .. "^7")
            else
                print("^1[ERROR] Failed to save first spawn position for " .. username .. "^7")
            end
        end)
    end)
end)

RegisterNetEvent('bloggrs:updateSkin')
AddEventHandler('bloggrs:updateSkin', function(skin)
    local src = source
    local username = exports.bloggrs_auth:GetPlayerUsername(src)
    if not username then 
        print("^1[ERROR] Could not get username for skin update, source: " .. tostring(src) .. "^7")
        return 
    end

    print("^3[DEBUG] Updating skin for " .. username .. "^7")

    MySQL.Async.fetchScalar('SELECT id FROM bloggrs_users WHERE username = @username', {
        ['@username'] = username
    }, function(user_id)
        if not user_id then 
            print("^1[ERROR] Could not find user_id for skin update, username: " .. username .. "^7")
            return 
        end

        MySQL.Async.execute([[
            UPDATE bloggrs_characters 
            SET skin = @skin 
            WHERE user_id = @user_id
        ]], {
            ['@user_id'] = user_id,
            ['@skin'] = json.encode(skin)
        }, function(rowsChanged)
            if rowsChanged and rowsChanged > 0 then
                print("^2[SUCCESS] Updated skin for " .. username .. "^7")
            else
                print("^1[ERROR] Failed to update skin for " .. username .. "^7")
            end
        end)
    end)
end)

-- Random simple ped
function getRandomDefaultSkin()
    local peds = {
        "mp_m_freemode_01",
        "mp_f_freemode_01",
        "a_m_m_business_01",
        "a_f_m_fatwhite_01"
    }
    local model = peds[math.random(1, #peds)]
    return { model = model }
end
