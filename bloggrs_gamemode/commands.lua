-- commands.lua

RegisterCommand('setskin', function(source, args)
    local src = source
    if not args[1] then
        TriggerClientEvent('chat:addMessage', src, { args = { '[Bloggrs]', 'Usage: /setskin modelname' }})
        return
    end

    local modelName = args[1]
    local cost = 500 -- Base cost

    -- More expensive if it's custom
    if string.find(modelName, "mp_") then
        cost = 2500
    end

    local user_id = getUserID(src)
    if not user_id then return end

    -- Check money
    MySQL.Async.fetchScalar('SELECT cash FROM bloggrs_players WHERE user_id = @user_id', {
        ['@user_id'] = user_id
    }, function(cash)
        if cash and tonumber(cash) >= cost then
            -- Deduct money
            MySQL.Async.execute('UPDATE bloggrs_players SET cash = cash - @cost WHERE user_id = @user_id', {
                ['@cost'] = cost,
                ['@user_id'] = user_id
            })

            -- Apply model
            TriggerClientEvent('chat:addMessage', src, { args = { '[Bloggrs]', 'Skin changed for $' .. cost }})
            TriggerClientEvent('bloggrs:spawnPlayer', src, GetEntityCoords(PlayerPedId()), { model = modelName })

            -- Save skin
            TriggerServerEvent('bloggrs:updateSkin', { model = modelName })
        else
            TriggerClientEvent('chat:addMessage', src, { args = { '[Bloggrs]', 'Not enough cash. Need $' .. cost }})
        end
    end)
end)
