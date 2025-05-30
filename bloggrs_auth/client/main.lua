local isLoggedIn = false
local username = nil
local isAdmin = false

-- Show notification
RegisterNetEvent('bloggrs:notification')
AddEventHandler('bloggrs:notification', function(message, type)
    SendNUIMessage({
        type = "notification",
        message = message,
        notificationType = type
    })
end)

-- Show registration success UI
RegisterNetEvent('bloggrs:showRegisterSuccess')
AddEventHandler('bloggrs:showRegisterSuccess', function(user)
    username = user
    isLoggedIn = true
    
    SendNUIMessage({
        type = "registerSuccess",
        username = username
    })
    
    -- Play success sound
    PlaySoundFrontend(-1, "Mission_Pass_Notify", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", 1)
    
    -- Display notification in-game
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName("~g~Registration successful! Welcome to Bloggrs, " .. username)
    EndTextCommandThefeedPostTicker(true, true)
end)

-- Show login success UI
RegisterNetEvent('bloggrs:showLoginSuccess')
AddEventHandler('bloggrs:showLoginSuccess', function(user, admin)
    username = user
    isLoggedIn = true
    isAdmin = admin
    
    SendNUIMessage({
        type = "loginSuccess",
        username = username,
        isAdmin = isAdmin
    })
    
    -- Play success sound
    PlaySoundFrontend(-1, "Mission_Pass_Notify", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", 1)
    
    -- Display notification in-game
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName("~g~Login successful! Welcome back to Bloggrs, " .. username)
    EndTextCommandThefeedPostTicker(true, true)
end)

-- Show online users (admin only)
RegisterNetEvent('bloggrs:showOnlineUsers')
AddEventHandler('bloggrs:showOnlineUsers', function(users)
    SendNUIMessage({
        type = "showOnlineUsers",
        users = users
    })
end)

-- Check if player is logged in
function IsPlayerLoggedIn()
    return isLoggedIn
end

-- Get player username
function GetPlayerUsername()
    return username
end

-- Check if player is admin
function IsPlayerAdmin()
    return isAdmin
end

-- Export functions
exports('IsPlayerLoggedIn', IsPlayerLoggedIn)
exports('GetPlayerUsername', GetPlayerUsername)
exports('IsPlayerAdmin', IsPlayerAdmin)
