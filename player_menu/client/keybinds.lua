-- Additional keybinds can be added here

-- Register key mapping for inventory
RegisterCommand('+openInventory', function()
    ToggleInventoryMenu()
end, false)

RegisterCommand('-openInventory', function()
end, false)

RegisterKeyMapping('+openInventory', 'Open Inventory', 'keyboard', 'I')

-- Disable default inventory key
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        DisableControlAction(0, 37, true) -- Disable TAB key
        DisableControlAction(0, 199, true) -- Disable P key
    end
end)
