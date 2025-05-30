local isOnCourierJob = false
local currentCheckpoint = nil
local blip = nil
local checkpointLocations = {}
local currentLocationIndex = 0

-- Global variables for active markers
local activeMarkers = {}
local currentBlip = nil
local totalRewardThisRun = 0

-- Function to show notification
function ShowNotification(message, type)
    if not message then return end
    
    -- Send to NUI
    SendNUIMessage({
        type = "notification",
        message = message,
        notificationType = type or "info"
    })
    
    -- Also show native notification
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, true)
end

-- Function to create blip for checkpoint
function CreateDeliveryBlip(coords)
    if currentBlip then RemoveBlip(currentBlip) end
    
    currentBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(currentBlip, 501) -- Delivery icon
    SetBlipColour(currentBlip, 5) -- Yellow
    SetBlipScale(currentBlip, 1.0)
    SetBlipAsShortRange(currentBlip, false)
    SetBlipRoute(currentBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Delivery Point")
    EndTextCommandSetBlipName(currentBlip)
    
    return currentBlip
end

-- Function to create checkpoint
function CreateCheckpoint(coords)
    if not coords then 
        print("^1[ERROR] No coordinates provided to CreateCheckpoint^7")
        return nil
    end
    
    print(string.format("^3[DEBUG] Creating checkpoint with coords type: %s^7", type(coords)))
    if type(coords) == "table" then
        print(string.format("^3[DEBUG] Table length: %d^7", #coords))
        if coords.x then
            print(string.format("^3[DEBUG] Coords as object: x=%.2f, y=%.2f, z=%.2f^7", coords.x, coords.y, coords.z))
        elseif #coords >= 3 then
            print(string.format("^3[DEBUG] Coords as array: [1]=%.2f, [2]=%.2f, [3]=%.2f^7", coords[1], coords[2], coords[3]))
        end
    elseif type(coords) == "vector3" then
        print(string.format("^3[DEBUG] Coords as vector3: x=%.2f, y=%.2f, z=%.2f^7", coords.x, coords.y, coords.z))
    end
    
    -- Validate and convert coordinates to vec3
    local checkpointCoords
    if type(coords) == "vector3" then
        checkpointCoords = coords
    elseif type(coords) == "table" then
        if coords.x and coords.y and coords.z then
            checkpointCoords = vector3(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0)
        elseif #coords >= 3 then
            checkpointCoords = vector3(coords[1] + 0.0, coords[2] + 0.0, coords[3] + 0.0)
        else
            print("^1[ERROR] Invalid coordinate format in CreateCheckpoint^7")
            return nil
        end
    else
        print("^1[ERROR] Invalid coordinate type in CreateCheckpoint^7")
        return nil
    end
    
    print(string.format("^2[DEBUG] Final checkpoint coords: x=%.2f, y=%.2f, z=%.2f^7", 
        checkpointCoords.x, checkpointCoords.y, checkpointCoords.z))
    
    -- Create the checkpoint using FiveM native
    local checkpointHandle = Citizen.InvokeNative(0x0134F0835AB6BFCB, 
        45, -- Type (red cylinder)
        checkpointCoords.x,
        checkpointCoords.y,
        checkpointCoords.z - 1.0, -- Offset slightly down so player can walk into it
        checkpointCoords.x,
        checkpointCoords.y,
        checkpointCoords.z + 2.0, -- Direction/height
        5.0, -- Radius
        255, 0, 0, 200, -- Color (RGBA)
        0, -- Reserved
        0 -- p13
    )
    
    if not checkpointHandle then
        print("^1[ERROR] Failed to create checkpoint with native function^7")
        return nil
    end
    
    print(string.format("^2[DEBUG] Created checkpoint with handle: %s^7", tostring(checkpointHandle)))
    
    -- Create blip for this checkpoint
    local blip = CreateDeliveryBlip(checkpointCoords)
    
    -- Store marker data
    local markerId = #activeMarkers + 1
    activeMarkers[markerId] = {
        coords = checkpointCoords,
        type = 1, -- Cylinder type
        scale = vector3(4.0, 4.0, 2.0),
        color = {r = 255, g = 0, b = 0, a = 150}
    }
    
    return {
        checkpoint = checkpointHandle,
        markerId = markerId,
        coords = checkpointCoords,
        blip = blip
    }
end

-- Function to calculate 3D distance between points
function CalculateDistance(point1, point2)
    if not point1 or not point2 then return 999999.9 end
    
    -- Convert points to vec3 if not already
    local p1 = vec3(point1.x + 0.0, point1.y + 0.0, point1.z + 0.0)
    local p2 = vec3(point2.x + 0.0, point2.y + 0.0, point2.z + 0.0)
    
    -- Calculate distance using native function
    return #(p1 - p2)
end

-- Function to start courier job
function StartCourierJob()
    print("^2[DEBUG] Starting courier job^7")
    
    -- Check if player is logged in using the auth resource
    local isLoggedIn = exports['bloggrs_auth']:IsPlayerLoggedIn(GetPlayerServerId(PlayerId()))
    
    if not isLoggedIn then
        ShowNotification(Config.Messages.NotLoggedIn, "error")
        return
    end
    
    if isOnCourierJob then
        ShowNotification(Config.Messages.AlreadyOnJob, "warning")
        return
    end
    
    -- Reset reward counter for new run
    totalRewardThisRun = 0
    
    -- Request vehicle first
    TriggerServerEvent('bloggrs:courier:requestJobVehicle')
    
    -- Copy and validate delivery locations
    checkpointLocations = {}
    print(string.format("^3[DEBUG] Processing %d delivery locations^7", #Config.DeliveryLocations))
    
    for i, loc in ipairs(Config.DeliveryLocations) do
        if type(loc) == "table" and #loc >= 3 then
            local vec = vector3(loc[1] + 0.0, loc[2] + 0.0, loc[3] + 0.0)
            table.insert(checkpointLocations, vec)
        end
    end
    
    if #checkpointLocations == 0 then
        print("^1[ERROR] No valid delivery locations found^7")
        ShowNotification("Error: No valid delivery locations found", "error")
        return
    end
    
    -- Shuffle locations
    for i = #checkpointLocations, 2, -1 do
        local j = math.random(i)
        checkpointLocations[i], checkpointLocations[j] = checkpointLocations[j], checkpointLocations[i]
    end
    
    currentLocationIndex = 1
    isOnCourierJob = true
    
    -- Create first checkpoint
    print("^3[DEBUG] Creating first checkpoint^7")
    local firstCheckpoint = CreateCheckpoint(checkpointLocations[currentLocationIndex])
    
    if firstCheckpoint then
        print("^2[DEBUG] First checkpoint created successfully^7")
        currentCheckpoint = firstCheckpoint
        ShowNotification(Config.Messages.JobStarted, "success")
        TriggerEvent('bloggrs:courier:jobStarted')
    else
        print("^1[ERROR] Failed to create first checkpoint^7")
        ShowNotification("Failed to create checkpoint. Please try again.", "error")
        isOnCourierJob = false
    end
end

-- Function to clean up checkpoint resources
function CleanupCheckpoint(checkpointData)
    if not checkpointData then return end
    
    if checkpointData.checkpoint then
        DeleteCheckpoint(checkpointData.checkpoint)
    end
    
    if checkpointData.blip then
        RemoveBlip(checkpointData.blip)
    end
    
    if checkpointData.markerId and activeMarkers[checkpointData.markerId] then
        activeMarkers[checkpointData.markerId] = nil
    end
end

-- Function to end courier job
function EndCourierJob(completed)
    if currentCheckpoint then
        CleanupCheckpoint(currentCheckpoint)
        currentCheckpoint = nil
    end
    
    isOnCourierJob = false
    
    if completed then
        -- Add completion bonus and trigger final reward
        totalRewardThisRun = totalRewardThisRun + Config.CompletionBonus
        TriggerServerEvent('bloggrs:courier:completeJob', totalRewardThisRun)
        ShowNotification(string.format(Config.Messages.JobCompleted, Config.CompletionBonus, totalRewardThisRun), "success")
    else
        ShowNotification(Config.Messages.JobCancelled, "warning")
    end
    
    -- Reset reward counter
    totalRewardThisRun = 0
    
    TriggerEvent('bloggrs:courier:jobEnded', completed)
end

-- Checkpoint check thread
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(100)
        
        if isOnCourierJob and currentCheckpoint then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local checkpointCoords = currentCheckpoint.coords
            
            local distance = #(playerCoords - checkpointCoords)
            
            if distance < Config.CheckpointRadius then
                -- Player reached checkpoint
                CleanupCheckpoint(currentCheckpoint)
                
                -- Add checkpoint reward
                totalRewardThisRun = totalRewardThisRun + Config.CheckpointReward
                -- Trigger immediate reward for this checkpoint
                TriggerServerEvent('bloggrs:courier:checkpointReached', Config.CheckpointReward)
                
                -- Move to next checkpoint or complete job
                currentLocationIndex = currentLocationIndex + 1
                
                if currentLocationIndex <= #checkpointLocations then
                    local nextCheckpoint = CreateCheckpoint(checkpointLocations[currentLocationIndex])
                    if nextCheckpoint then
                        currentCheckpoint = nextCheckpoint
                        ShowNotification(string.format(Config.Messages.CheckpointReached, Config.CheckpointReward), "success")
                    else
                        EndCourierJob(false)
                        ShowNotification("Failed to create next checkpoint. Job cancelled.", "error")
                    end
                else
                    -- Job completed
                    EndCourierJob(true)
                end
            end
        end
    end
end)

-- Command to start courier job (without spaces)
RegisterCommand('courierjob', function()
    StartCourierJob()
end, false)

-- Command to cancel courier job (without spaces)
RegisterCommand('cancelcourier', function()
    if isOnCourierJob then
        EndCourierJob(false)
    else
        ShowNotification("You are not on a courier job.", "warning")
    end
end, false)

-- Event for successful login from auth system
RegisterNetEvent('bloggrs:showLoginSuccess')
AddEventHandler('bloggrs:showLoginSuccess', function(username, isAdmin)
    -- Show courier job menu after successful login
    Citizen.Wait(2000) -- Wait a bit after login success message
    TriggerEvent('bloggrs:courier:openUI')
end)

-- Event for successful registration from auth system
RegisterNetEvent('bloggrs:showRegisterSuccess')
AddEventHandler('bloggrs:showRegisterSuccess', function(username)
    -- Show courier job menu after successful registration
    Citizen.Wait(2000) -- Wait a bit after registration success message
    TriggerEvent('bloggrs:courier:openUI')
end)

-- UI Callbacks
RegisterNUICallback('startCourierJob', function(data, cb)
    print("^2[DEBUG] startCourierJob NUI callback triggered^7")
    StartCourierJob()
    cb({success = true})
end)

RegisterNUICallback('cancelCourierJob', function(data, cb)
    print("^2[DEBUG] cancelCourierJob NUI callback triggered^7")
    if isOnCourierJob then
        EndCourierJob(false)
        cb({success = true})
    else
        cb({success = false, message = "Not on a courier job"})
    end
end)

RegisterNUICallback('closeUI', function(data, cb)
    print("^2[DEBUG] closeUI NUI callback triggered^7")
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = "closeUI"
    })
    cb({success = true})
end)

-- Open UI
RegisterNetEvent('bloggrs:courier:openUI')
AddEventHandler('bloggrs:courier:openUI', function()
    print("^2[DEBUG] Opening courier UI^7")
    -- Check if player is logged in using the auth resource
    local isLoggedIn = exports['bloggrs_auth']:IsPlayerLoggedIn(GetPlayerServerId(PlayerId()))
    
    if not isLoggedIn then
        ShowNotification(Config.Messages.NotLoggedIn, "error")
        return
    end
    
    local username = exports['bloggrs_auth']:GetPlayerUsername(GetPlayerServerId(PlayerId()))
    local isAdmin = exports['bloggrs_auth']:IsPlayerAdmin(GetPlayerServerId(PlayerId()))
    
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = "openUI",
        username = username,
        isAdmin = isAdmin,
        isOnJob = isOnCourierJob
    })
end)

-- Command to open courier job menu
RegisterCommand('couriermenu', function()
    TriggerEvent('bloggrs:courier:openUI')
end, false)

-- F7 key binding
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsControlJustReleased(0, 168) then -- 168 is F7
            TriggerEvent('bloggrs:courier:openUI')
        end
    end
end)

-- Close UI when pressing ESC
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsControlJustReleased(0, 200) and IsPauseMenuActive() then -- ESC key
            SetNuiFocus(false, false)
            SendNUIMessage({
                type = "closeUI"
            })
        end
    end
end)

-- Register key mapping for commands
RegisterKeyMapping('courierjob', 'Start a courier job', 'keyboard', '')
RegisterKeyMapping('cancelcourier', 'Cancel current courier job', 'keyboard', '')
RegisterKeyMapping('couriermenu', 'Open courier job menu', 'keyboard', 'F7')

function IsPlayerNearCheckpoint(checkpointCoords, radius)
    if not checkpointCoords then return false end
    
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    -- Convert checkpoint coords to vec3 if not already
    local checkpoint = vec3(checkpointCoords.x + 0.0, checkpointCoords.y + 0.0, checkpointCoords.z + 0.0)
    local distance = #(playerCoords - checkpoint)
    
    return distance <= (radius or 5.0)
end

-- Marker render thread
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        for _, markerData in pairs(activeMarkers) do
            -- Only draw markers within 100.0 units of the player
            if #(playerCoords - markerData.coords) < 100.0 then
                DrawMarker(
                    markerData.type,
                    markerData.coords.x,
                    markerData.coords.y,
                    markerData.coords.z - 1.0,
                    0.0, 0.0, 0.0, -- Direction
                    0.0, 0.0, 0.0, -- Rotation
                    markerData.scale.x,
                    markerData.scale.y,
                    markerData.scale.z,
                    markerData.color.r,
                    markerData.color.g,
                    markerData.color.b,
                    markerData.color.a,
                    false, -- Bob up and down
                    false, -- Face camera
                    2, -- p19
                    false, -- Rotate
                    nil, -- TextureDict
                    nil, -- TextureName
                    false -- DrawOnEnts
                )
            end
        end
    end
end)

-- Register notification event
RegisterNetEvent('bloggrs:showNotification')
AddEventHandler('bloggrs:showNotification', function(message, type)
    ShowNotification(message, type)
end)

-- Vehicle spawned event handler
RegisterNetEvent('bloggrs:courier:vehicleSpawned')
AddEventHandler('bloggrs:courier:vehicleSpawned', function(netId)
    -- Request and load the vehicle model first
    local vehicleHash = GetHashKey(Config.CourierVehicle)
    
    RequestModel(vehicleHash)
    print("^3[DEBUG] Requesting vehicle model: " .. Config.CourierVehicle .. "^7")
    
    -- Wait for the model to load with a timeout
    local timeout = 0
    while not HasModelLoaded(vehicleHash) and timeout < 100 do
        Citizen.Wait(10)
        timeout = timeout + 1
    end
    
    if not HasModelLoaded(vehicleHash) then
        print("^1[ERROR] Vehicle model failed to load on client^7")
        ShowNotification("Failed to load vehicle model", "error")
        return
    end
    
    -- Get the vehicle entity from network ID
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not vehicle or vehicle == 0 then
        print("^1[ERROR] Failed to get spawned vehicle from network ID^7")
        ShowNotification("Failed to get spawned vehicle", "error")
        SetModelAsNoLongerNeeded(vehicleHash)
        return
    end
    
    print("^2[DEBUG] Got vehicle entity: " .. tostring(vehicle) .. "^7")
    
    -- Ensure it's a mission entity
    SetEntityAsMissionEntity(vehicle, true, true)
    
    -- Set player into vehicle
    local playerPed = PlayerPedId()
    TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
    
    -- Release the model
    SetModelAsNoLongerNeeded(vehicleHash)
    
    ShowNotification(Config.Messages.VehicleSpawned, "success")
end)
