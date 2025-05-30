Config = {}

-- Database configuration
Config.PlayerTable = 'bloggrs_players'
Config.InventoryTable = 'bloggrs_inventory'

-- Player settings
Config.StartingCash = 1000
Config.StartingBank = 5000

-- Inventory settings
Config.MaxInventoryWeight = 30.0
Config.MaxInventorySlots = 30

-- Default inventory items for new players
Config.DefaultItems = {
    {item = "water", count = 5},
    {item = "sandwich", count = 3},
    {item = "weed", count = 300},
    {item = "phone", count = 1},
    {item = "bandage", count = 2}
}

-- Money settings
Config.MoneyTypes = {
    cash = "Cash",
    bank = "Bank"
}

-- Item use effects
Config.ItemEffects = {
    water = function(source)
        -- Add thirst restoration logic here
        TriggerClientEvent('bloggrs:notification', source, "You drank some water. Refreshing!", "success")
    end,
    sandwich = function(source)
        -- Add hunger restoration logic here
        TriggerClientEvent('bloggrs:notification', source, "You ate a sandwich. Delicious!", "success")
    end,
    weed = function(source)
        -- Add weed effect logic here
        TriggerClientEvent('bloggrs:notification', source, "You smoked some weed. Feeling high!", "success")
        -- Add screen effects on client
        TriggerClientEvent('bloggrs:weedEffect', source)
    end,
    phone = function(source)
        -- Open phone UI
        TriggerClientEvent('bloggrs:notification', source, "You used your phone.", "info")
        TriggerClientEvent('bloggrs:openPhone', source)
    end,
    bandage = function(source)
        -- Add healing logic here
        TriggerClientEvent('bloggrs:notification', source, "You used a bandage. Feeling better!", "success")
    end
}
