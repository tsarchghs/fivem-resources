Items = {
    ["water"] = {
        label = "Water Bottle",
        weight = 0.5,
        description = "Stay hydrated with fresh water",
        canUse = true,
        useTime = 3000,
        category = "consumable"
    },
    ["sandwich"] = {
        label = "Sandwich",
        weight = 0.7,
        description = "A delicious sandwich to satisfy your hunger",
        canUse = true,
        useTime = 5000,
        category = "food"
    },
    ["weed"] = {
        label = "Weed",
        weight = 0.1,
        description = "High quality cannabis",
        canUse = true,
        useTime = 4000,
        category = "drugs"
    },
    ["phone"] = {
        label = "Phone",
        weight = 0.3,
        description = "A smartphone to stay connected",
        canUse = true,
        useTime = 1000,
        category = "electronics"
    },
    ["lockpick"] = {
        label = "Lockpick",
        weight = 0.2,
        description = "Used to pick locks",
        canUse = true,
        useTime = 10000,
        category = "tools"
    },
    ["bandage"] = {
        label = "Bandage",
        weight = 0.1,
        description = "Used to treat minor wounds",
        canUse = true,
        useTime = 3000,
        category = "medical"
    },
    ["cash"] = {
        label = "Cash",
        weight = 0.0,
        description = "Money in your pocket",
        canUse = false,
        category = "money"
    }
}

-- Get item data by name
function GetItemData(itemName)
    return Items[itemName]
end

-- Get item label by name
function GetItemLabel(itemName)
    local item = Items[itemName]
    if item then
        return item.label
    end
    return itemName
end

-- Get all items in a specific category
function GetItemsByCategory(category)
    local categoryItems = {}
    
    for k, v in pairs(Items) do
        if v.category == category then
            categoryItems[k] = v
        end
    end
    
    return categoryItems
end
