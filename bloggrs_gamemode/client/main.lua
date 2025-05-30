-- client/main.lua

local isFirstSpawn = true

-- Handle player spawn
RegisterNetEvent('bloggrs:spawnPlayer')
AddEventHandler('bloggrs:spawnPlayer', function(pos, skin)
    print("[DEBUG] Received spawn request with position: " .. json.encode(pos))
    
    -- Request model
    local model = skin.model or "mp_m_freemode_01"
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(500)
    end

    -- Set player model
    SetPlayerModel(PlayerId(), model)
    SetModelAsNoLongerNeeded(model)
    
    -- Get player ped after model change
    local ped = PlayerPedId()
    
    -- Set invincible during spawn
    SetEntityInvincible(ped, true)
    
    -- Teleport to position
    SetEntityCoords(ped, pos.x, pos.y, pos.z, false, false, false, true)
    SetEntityHeading(ped, pos.w)
    
    -- Freeze player briefly to prevent falling through ground
    FreezeEntityPosition(ped, true)
    Wait(1000)
    FreezeEntityPosition(ped, false)
    
    -- Remove invincibility
    SetEntityInvincible(ped, false)
    
    -- Clear any leftover tasks
    ClearPedTasksImmediately(ped)
    
    -- Trigger any additional spawn setup (like loading animations, etc)
    TriggerEvent('bloggrs:onPlayerSpawned')
    
    print("[DEBUG] Player spawn complete")
end)

-- Handle post-spawn setup
RegisterNetEvent('bloggrs:onPlayerSpawned')
AddEventHandler('bloggrs:onPlayerSpawned', function()
    -- Set default walking style
    RequestAnimSet("move_m@casual@a")
    while not HasAnimSetLoaded("move_m@casual@a") do
        Wait(100)
    end
    SetPedMovementClipset(PlayerPedId(), "move_m@casual@a", 0.5)

    -- Additional spawn setup can go here
    -- For example, setting health, armor, etc.
    local ped = PlayerPedId()
    SetEntityHealth(ped, 200) -- Full health
    SetPedArmour(ped, 0)     -- No armor by default
    
    -- Enable player control
    SetPlayerControl(PlayerId(), true, 0)
    
    -- Fade in from black
    DoScreenFadeIn(500)
end)

-- Initialize resource
Citizen.CreateThread(function()
    -- Wait for game to load
    while not NetworkIsSessionStarted() do
        Wait(500)
    end
    
    -- Initial setup
    exports.spawnmanager:setAutoSpawn(false)
    DisplayRadar(true)
    
    print("[DEBUG] Client initialized")
end) 