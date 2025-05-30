-- client.lua

RegisterNetEvent('bloggrs:spawnPlayer')
AddEventHandler('bloggrs:spawnPlayer', function(pos, skin)
    DoScreenFadeOut(500)
    Wait(500)
    SetEntityCoords(PlayerPedId(), pos.x, pos.y, pos.z)
    SetEntityHeading(PlayerPedId(), pos.w)
    if skin and skin.model then
        loadModel(skin.model)
        SetPlayerModel(PlayerId(), GetHashKey(skin.model))
        SetPedDefaultComponentVariation(PlayerPedId())
    end
    Wait(500)
    DoScreenFadeIn(500)
end)

-- Save position automatically every 30s
CreateThread(function()
    while true do
        Wait(30000)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        local pos = {
            x = coords.x,
            y = coords.y,
            z = coords.z,
            w = heading
        }
        TriggerServerEvent('bloggrs:updatePosition', pos)
    end
end)

function loadModel(model)
    local hash = GetHashKey(model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Wait(10)
    end
end
