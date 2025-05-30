-- Local variables
local playerData = nil
local inventory = nil
local isMenuOpen = false
local isDataLoading = false

-- Function to request player data
function RequestPlayerData()
    if not isDataLoading then
        isDataLoading = true
        print("^3[DEBUG] Requesting player data from server^7")
        TriggerServerEvent('bloggrs:requestPlayerData')
    else
        print("^1[ERROR] Data is already loading, please wait^7")
    end
end

-- Player loaded event
AddEventHandler('onClientResourceStart', function(resourceName)
    if(GetCurrentResourceName() ~= resourceName) then
        return
    end
    
    print("^2[INFO] Player Menu resource started^7")
    
    -- Wait a moment to ensure auth system is ready
    Citizen.Wait(2000)
    
    -- Check if player is logged in
    local isLoggedIn = exports.bloggrs_auth:IsPlayerLoggedIn()
    print("^3[DEBUG] Is player logged in:", isLoggedIn, "^7")
    
    if isLoggedIn then
        -- Request initial player data
        RequestPlayerData()
    else
        -- Show notification to login
        TriggerEvent('bloggrs:notification', "Please login to access your inventory. Use /login [username] [password]", "info")
    end
end)

-- Set player data from server
RegisterNetEvent('bloggrs:setPlayerData')
AddEventHandler('bloggrs:setPlayerData', function(data)
    print("^2[INFO] Received player data from server^7")
    print("^3[DEBUG] Player data:", json.encode(data), "^7")
    playerData = data
    isDataLoading = false
    
    -- Update UI with new data if menu is open
    if isMenuOpen then
        SendNUIMessage({
            type = "updatePlayerData",
            data = playerData
        })
    end
end)

-- Set inventory from server
RegisterNetEvent('bloggrs:setInventory')
AddEventHandler('bloggrs:setInventory', function(data)
    inventory = data
    
    -- Update UI with new inventory
    if isMenuOpen then
        SendNUIMessage({
            type = "updateInventory",
            inventory = inventory
        })
    end
end)

-- Show notification
RegisterNetEvent('bloggrs:notification')
AddEventHandler('bloggrs:notification', function(message, type)
    SendNUIMessage({
        type = "notification",
        message = message,
        notificationType = type
    })
end)

-- Item used event
RegisterNetEvent('bloggrs:itemUsed')
AddEventHandler('bloggrs:itemUsed', function(item)
    -- Play animation or sound effect
    PlaySound(-1, "PICK_UP", "HUD_FRONTEND_DEFAULT_SOUNDSET", 0, 0, 1)
    
    -- Play animation
    local playerPed = PlayerPedId()
    TaskStartScenarioInPlace(playerPed, "PROP_HUMAN_BUM_BIN", 0, true)
    
    -- Wait for animation to complete
    Citizen.Wait(3000)
    
    -- Clear animation
    ClearPedTasks(playerPed)
end)

-- Weed effect
RegisterNetEvent('bloggrs:weedEffect')
AddEventHandler('bloggrs:weedEffect', function()
    -- Screen effects
    StartScreenEffect("DrugsMichaelAliensFight", 3000, false)
    
    -- Camera shake
    ShakeGameplayCam("DRUNK_SHAKE", 1.0)
    
    -- Clear effects after some time
    Citizen.Wait(10000)
    StopScreenEffect("DrugsMichaelAliensFight")
    ShakeGameplayCam("DRUNK_SHAKE", 0.0)
end)

-- Open phone
RegisterNetEvent('bloggrs:openPhone')
AddEventHandler('bloggrs:openPhone', function()
    -- Phone logic would go here
    TriggerEvent('bloggrs:notification', "Phone functionality not implemented yet.", "info")
end)

-- Toggle inventory menu
function ToggleInventoryMenu()
    print("^3[DEBUG] ToggleInventoryMenu called^7")
    isMenuOpen = not isMenuOpen
    
    if isMenuOpen then
        print("^3[DEBUG] Attempting to open inventory^7")
        -- Check if player is logged in
        local isLoggedIn = exports.bloggrs_auth:IsPlayerLoggedIn()
        print("^3[DEBUG] Is player logged in:", isLoggedIn, "^7")
        
        if not isLoggedIn then
            print("^1[ERROR] Player not logged in^7")
            TriggerEvent('bloggrs:notification', "You must be logged in to access your inventory.", "error")
            isMenuOpen = false
            return
        end
        
        -- Check if player data is loaded
        if not playerData then
            print("^1[ERROR] Player data not loaded, requesting from server^7")
            RequestPlayerData()
            
            -- Wait for data to load with timeout
            local timeout = 0
            while not playerData and timeout < 50 do
                Citizen.Wait(100)
                timeout = timeout + 1
                if timeout % 10 == 0 then
                    print("^3[DEBUG] Waiting for player data... (" .. timeout .. "/50)^7")
                end
            end
            
            if not playerData then
                print("^1[ERROR] Timeout waiting for player data^7")
                TriggerEvent('bloggrs:notification', "Failed to load player data. Please try again.", "error")
            isMenuOpen = false
            return
            end
        end
        
        print("^2[INFO] Opening inventory menu^7")
        -- Open menu
        SendNUIMessage({
            type = "openMenu",
            data = playerData,
            inventory = inventory
        })
        SetNuiFocus(true, true)
        
        -- Disable controls while menu is open
        Citizen.CreateThread(function()
            while isMenuOpen do
                DisableControlAction(0, 1, true) -- LookLeftRight
                DisableControlAction(0, 2, true) -- LookUpDown
                DisableControlAction(0, 142, true) -- MeleeAttackAlternate
                DisableControlAction(0, 18, true) -- Enter
                DisableControlAction(0, 322, true) -- ESC
                DisableControlAction(0, 106, true) -- VehicleMouseControlOverride
                DisableControlAction(0, 24, true) -- Attack
                DisableControlAction(0, 25, true) -- Aim
                DisableControlAction(0, 37, true) -- Select Weapon
                DisableControlAction(0, 47, true) -- Detonate
                DisableControlAction(0, 58, true) -- Throttle
                DisableControlAction(0, 59, true) -- Brake
                DisableControlAction(0, 60, true) -- Move Left/Right
                DisableControlAction(0, 61, true) -- Move Up/Down
                DisableControlAction(0, 62, true) -- Move Up
                DisableControlAction(0, 63, true) -- Move Down
                DisableControlAction(0, 64, true) -- Move Left
                DisableControlAction(0, 65, true) -- Move Right
                DisableControlAction(0, 66, true) -- Duck
                DisableControlAction(0, 67, true) -- Jump
                DisableControlAction(0, 68, true) -- Sprint
                DisableControlAction(0, 69, true) -- Walk
                DisableControlAction(0, 70, true) -- Look Behind
                DisableControlAction(0, 71, true) -- Next Camera
                DisableControlAction(0, 72, true) -- Previous Camera
                DisableControlAction(0, 73, true) -- Next Weapon
                DisableControlAction(0, 74, true) -- Previous Weapon
                DisableControlAction(0, 75, true) -- Skip Cutscene
                DisableControlAction(0, 76, true) -- Character Wheel
                DisableControlAction(0, 77, true) -- Multiplayer Info
                DisableControlAction(0, 78, true) -- Sprint
                DisableControlAction(0, 79, true) -- Jump
                DisableControlAction(0, 80, true) -- Enter
                DisableControlAction(0, 81, true) -- Attack
                DisableControlAction(0, 82, true) -- Special Ability
                DisableControlAction(0, 83, true) -- Special Ability Secondary
                DisableControlAction(0, 84, true) -- Move Left
                DisableControlAction(0, 85, true) -- Move Right
                DisableControlAction(0, 86, true) -- Move Up
                DisableControlAction(0, 87, true) -- Move Down
                DisableControlAction(0, 88, true) -- Attack
                DisableControlAction(0, 89, true) -- Special Ability
                DisableControlAction(0, 90, true) -- Special Ability Secondary
                DisableControlAction(0, 91, true) -- Move Left
                DisableControlAction(0, 92, true) -- Move Right
                DisableControlAction(0, 93, true) -- Move Up
                DisableControlAction(0, 94, true) -- Move Down
                DisableControlAction(0, 95, true) -- Attack
                DisableControlAction(0, 96, true) -- Special Ability
                DisableControlAction(0, 97, true) -- Special Ability Secondary
                DisableControlAction(0, 98, true) -- Move Left
                DisableControlAction(0, 99, true) -- Move Right
                DisableControlAction(0, 100, true) -- Move Up
                DisableControlAction(0, 101, true) -- Move Down
                DisableControlAction(0, 102, true) -- Attack
                DisableControlAction(0, 103, true) -- Special Ability
                DisableControlAction(0, 104, true) -- Special Ability Secondary
                DisableControlAction(0, 105, true) -- Move Left
                DisableControlAction(0, 106, true) -- Move Right
                DisableControlAction(0, 107, true) -- Move Up
                DisableControlAction(0, 108, true) -- Move Down
                DisableControlAction(0, 109, true) -- Attack
                DisableControlAction(0, 110, true) -- Special Ability
                DisableControlAction(0, 111, true) -- Special Ability Secondary
                DisableControlAction(0, 112, true) -- Move Left
                DisableControlAction(0, 113, true) -- Move Right
                DisableControlAction(0, 114, true) -- Move Up
                DisableControlAction(0, 115, true) -- Move Down
                DisableControlAction(0, 116, true) -- Attack
                DisableControlAction(0, 117, true) -- Special Ability
                DisableControlAction(0, 118, true) -- Special Ability Secondary
                DisableControlAction(0, 119, true) -- Move Left
                DisableControlAction(0, 120, true) -- Move Right
                DisableControlAction(0, 121, true) -- Move Up
                DisableControlAction(0, 122, true) -- Move Down
                DisableControlAction(0, 123, true) -- Attack
                DisableControlAction(0, 124, true) -- Special Ability
                DisableControlAction(0, 125, true) -- Special Ability Secondary
                DisableControlAction(0, 126, true) -- Move Left
                DisableControlAction(0, 127, true) -- Move Right
                DisableControlAction(0, 128, true) -- Move Up
                DisableControlAction(0, 129, true) -- Move Down
                DisableControlAction(0, 130, true) -- Attack
                DisableControlAction(0, 131, true) -- Special Ability
                DisableControlAction(0, 132, true) -- Special Ability Secondary
                DisableControlAction(0, 133, true) -- Move Left
                DisableControlAction(0, 134, true) -- Move Right
                DisableControlAction(0, 135, true) -- Move Up
                DisableControlAction(0, 136, true) -- Move Down
                DisableControlAction(0, 137, true) -- Attack
                DisableControlAction(0, 138, true) -- Special Ability
                DisableControlAction(0, 139, true) -- Special Ability Secondary
                DisableControlAction(0, 140, true) -- Move Left
                DisableControlAction(0, 141, true) -- Move Right
                DisableControlAction(0, 142, true) -- Move Up
                DisableControlAction(0, 143, true) -- Move Down
                DisableControlAction(0, 144, true) -- Attack
                DisableControlAction(0, 145, true) -- Special Ability
                DisableControlAction(0, 146, true) -- Special Ability Secondary
                DisableControlAction(0, 147, true) -- Move Left
                DisableControlAction(0, 148, true) -- Move Right
                DisableControlAction(0, 149, true) -- Move Up
                DisableControlAction(0, 150, true) -- Move Down
                DisableControlAction(0, 151, true) -- Attack
                DisableControlAction(0, 152, true) -- Special Ability
                DisableControlAction(0, 153, true) -- Special Ability Secondary
                DisableControlAction(0, 154, true) -- Move Left
                DisableControlAction(0, 155, true) -- Move Right
                DisableControlAction(0, 156, true) -- Move Up
                DisableControlAction(0, 157, true) -- Move Down
                DisableControlAction(0, 158, true) -- Attack
                DisableControlAction(0, 159, true) -- Special Ability
                DisableControlAction(0, 160, true) -- Special Ability Secondary
                DisableControlAction(0, 161, true) -- Move Left
                DisableControlAction(0, 162, true) -- Move Right
                DisableControlAction(0, 163, true) -- Move Up
                DisableControlAction(0, 164, true) -- Move Down
                DisableControlAction(0, 165, true) -- Attack
                DisableControlAction(0, 166, true) -- Special Ability
                DisableControlAction(0, 167, true) -- Special Ability Secondary
                DisableControlAction(0, 168, true) -- Move Left
                DisableControlAction(0, 169, true) -- Move Right
                DisableControlAction(0, 170, true) -- Move Up
                DisableControlAction(0, 171, true) -- Move Down
                DisableControlAction(0, 172, true) -- Attack
                DisableControlAction(0, 173, true) -- Special Ability
                DisableControlAction(0, 174, true) -- Special Ability Secondary
                DisableControlAction(0, 175, true) -- Move Left
                DisableControlAction(0, 176, true) -- Move Right
                DisableControlAction(0, 177, true) -- Move Up
                DisableControlAction(0, 178, true) -- Move Down
                DisableControlAction(0, 179, true) -- Attack
                DisableControlAction(0, 180, true) -- Special Ability
                DisableControlAction(0, 181, true) -- Special Ability Secondary
                DisableControlAction(0, 182, true) -- Move Left
                DisableControlAction(0, 183, true) -- Move Right
                DisableControlAction(0, 184, true) -- Move Up
                DisableControlAction(0, 185, true) -- Move Down
                DisableControlAction(0, 186, true) -- Attack
                DisableControlAction(0, 187, true) -- Special Ability
                DisableControlAction(0, 188, true) -- Special Ability Secondary
                DisableControlAction(0, 189, true) -- Move Left
                DisableControlAction(0, 190, true) -- Move Right
                DisableControlAction(0, 191, true) -- Move Up
                DisableControlAction(0, 192, true) -- Move Down
                DisableControlAction(0, 193, true) -- Attack
                DisableControlAction(0, 194, true) -- Special Ability
                DisableControlAction(0, 195, true) -- Special Ability Secondary
                DisableControlAction(0, 196, true) -- Move Left
                DisableControlAction(0, 197, true) -- Move Right
                DisableControlAction(0, 198, true) -- Move Up
                DisableControlAction(0, 199, true) -- Move Down
                DisableControlAction(0, 200, true) -- Attack
                DisableControlAction(0, 201, true) -- Special Ability
                DisableControlAction(0, 202, true) -- Special Ability Secondary
                DisableControlAction(0, 203, true) -- Move Left
                DisableControlAction(0, 204, true) -- Move Right
                DisableControlAction(0, 205, true) -- Move Up
                DisableControlAction(0, 206, true) -- Move Down
                DisableControlAction(0, 207, true) -- Attack
                DisableControlAction(0, 208, true) -- Special Ability
                DisableControlAction(0, 209, true) -- Special Ability Secondary
                DisableControlAction(0, 210, true) -- Move Left
                DisableControlAction(0, 211, true) -- Move Right
                DisableControlAction(0, 212, true) -- Move Up
                DisableControlAction(0, 213, true) -- Move Down
                DisableControlAction(0, 214, true) -- Attack
                DisableControlAction(0, 215, true) -- Special Ability
                DisableControlAction(0, 216, true) -- Special Ability Secondary
                DisableControlAction(0, 217, true) -- Move Left
                DisableControlAction(0, 218, true) -- Move Right
                DisableControlAction(0, 219, true) -- Move Up
                DisableControlAction(0, 220, true) -- Move Down
                DisableControlAction(0, 221, true) -- Attack
                DisableControlAction(0, 222, true) -- Special Ability
                DisableControlAction(0, 223, true) -- Special Ability Secondary
                DisableControlAction(0, 224, true) -- Move Left
                DisableControlAction(0, 225, true) -- Move Right
                DisableControlAction(0, 226, true) -- Move Up
                DisableControlAction(0, 227, true) -- Move Down
                DisableControlAction(0, 228, true) -- Attack
                DisableControlAction(0, 229, true) -- Special Ability
                DisableControlAction(0, 230, true) -- Special Ability Secondary
                DisableControlAction(0, 231, true) -- Move Left
                DisableControlAction(0, 232, true) -- Move Right
                DisableControlAction(0, 233, true) -- Move Up
                DisableControlAction(0, 234, true) -- Move Down
                DisableControlAction(0, 235, true) -- Attack
                DisableControlAction(0, 236, true) -- Special Ability
                DisableControlAction(0, 237, true) -- Special Ability Secondary
                DisableControlAction(0, 238, true) -- Move Left
                DisableControlAction(0, 239, true) -- Move Right
                DisableControlAction(0, 240, true) -- Move Up
                DisableControlAction(0, 241, true) -- Move Down
                DisableControlAction(0, 242, true) -- Attack
                DisableControlAction(0, 243, true) -- Special Ability
                DisableControlAction(0, 244, true) -- Special Ability Secondary
                DisableControlAction(0, 245, true) -- Move Left
                DisableControlAction(0, 246, true) -- Move Right
                DisableControlAction(0, 247, true) -- Move Up
                DisableControlAction(0, 248, true) -- Move Down
                DisableControlAction(0, 249, true) -- Attack
                DisableControlAction(0, 250, true) -- Special Ability
                DisableControlAction(0, 251, true) -- Special Ability Secondary
                DisableControlAction(0, 252, true) -- Move Left
                DisableControlAction(0, 253, true) -- Move Right
                DisableControlAction(0, 254, true) -- Move Up
                DisableControlAction(0, 255, true) -- Move Down
                Citizen.Wait(0)
            end
        end)
    else
        print("^2[INFO] Closing inventory menu^7")
        -- Close menu
        SendNUIMessage({
            type = "closeMenu"
        })
        SetNuiFocus(false, false)
    end
end

-- NUI Callbacks
RegisterNUICallback('closeMenu', function(data, cb)
    ToggleInventoryMenu()
    cb('ok')
end)

RegisterNUICallback('useItem', function(data, cb)
    TriggerServerEvent('bloggrs:useItem', data.item)
    cb('ok')
end)

RegisterNUICallback('dropItem', function(data, cb)
    TriggerServerEvent('bloggrs:removeItem', data.item, data.count)
    cb('ok')
end)

RegisterNUICallback('transferMoney', function(data, cb)
    TriggerServerEvent('bloggrs:transferMoney', data.from, data.to, data.amount)
    cb('ok')
end)

RegisterNUICallback('giveItem', function(data, cb)
    local closestPlayer, closestDistance = GetClosestPlayer()
    
    if closestPlayer ~= -1 and closestDistance <= 3.0 then
        TriggerServerEvent('bloggrs:transferItem', GetPlayerServerId(closestPlayer), data.item, data.count)
    else
        TriggerEvent('bloggrs:notification', "No players nearby.", "error")
    end
    
    cb('ok')
end)

-- Helper function to get closest player
function GetClosestPlayer()
    local players = GetActivePlayers()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local closestDistance = -1
    local closestPlayer = -1
    
    for i = 1, #players do
        local targetPed = GetPlayerPed(players[i])
        
        if targetPed ~= playerPed then
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(playerCoords - targetCoords)
            
            if closestDistance == -1 or closestDistance > distance then
                closestPlayer = players[i]
                closestDistance = distance
            end
        end
    end
    
    return closestPlayer, closestDistance
end
