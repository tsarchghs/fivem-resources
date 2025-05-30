-- client.lua
local uiShown = false  -- Tracks if the HUD is currently displayed

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)  -- Check login status every second
        -- Check if the player is logged in via the bloggrs_auth export
        if not uiShown and exports['bloggrs_auth']:IsPlayerLoggedIn() then
            -- Show the HUD UI
            SendNUIMessage({ action = 'showUI' })
            -- Make sure the UI does NOT capture mouse/keyboard (so gameplay isn't blocked)
            SetNuiFocus(false, false)
            uiShown = true
        end

        -- If HUD is shown (player is logged in), request updates
        if uiShown then
            -- Ask the server for the latest money and time
            TriggerServerEvent('bloggrs:GetMoney')
            TriggerServerEvent('bloggrs:GetTime')
            -- Update every 5 seconds (5000 ms)
            Citizen.Wait(5000)
        end
    end
end)

-- Receive updated money from server and send to NUI
RegisterNetEvent('bloggrs:UpdateMoney')
AddEventHandler('bloggrs:UpdateMoney', function(cash, bank)
    -- Send new cash/bank values to the HTML via NUI
    SendNUIMessage({
        action = 'updateMoney',
        cash = cash,
        bank = bank
    })
end)

-- Receive updated time from server and send to NUI
RegisterNetEvent('bloggrs:UpdateTime')
AddEventHandler('bloggrs:UpdateTime', function(timeStr)
    -- Send new time string to the HTML via NUI
    SendNUIMessage({
        action = 'updateTime',
        time = timeStr
    })
end)
