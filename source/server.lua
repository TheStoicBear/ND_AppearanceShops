lib.callback.register("ND_AppearanceShops:clothingPurchase", function(src, store, clothing)
    local store = Config[store]
    local player = NDCore.getPlayer(src)
    if not store or not player then return end

    local price = store.price
    if not price then return true end
    
    -- Check if player has enough money
    if not player.deductMoney("bank", price, store.blip.label) then
        player.notify({
            title = store.blip.label,
            description = ("Payment of $%d failed!"):format(price),
            position = "bottom",
            type = "error"
        })
        return
    end

    -- Update player's clothing metadata
    if clothing and type(clothing) == "table" then
        player.setMetadata("clothing", clothing)
    end

    -- Notify player about successful purchase
    player.notify({
        title = store.blip.label,
        description = ("Payment of $%d confirmed!"):format(price),
        position = "bottom",
        type = "success"
    })

    -- Call an event to save the clothing for the player
    TriggerEvent("ND_AppearanceShops:saveCharacterOutfit", src, clothing)

    return true
end)

-- Event to update player appearance (client-side)
RegisterNetEvent("ND_AppearanceShops:updateAppearance", function(clothing)
    local src = source
    local player = NDCore.getPlayer(src)
    if not player then return end

    -- Update player's clothing metadata
    if clothing and type(clothing) == "table" then
        player.setMetadata("clothing", clothing)
    end
end)

-- Server-side event to save the player's clothing data
RegisterNetEvent('ND_AppearanceShops:saveCharacterOutfit')
AddEventHandler('ND_AppearanceShops:saveCharacterOutfit', function(src, clothingData)
    local src = source
    local player = NDCore.getPlayer(src)  -- Retrieve player object

    -- Log the raw received data
    print("Received clothingData:", clothingData)
    print("Type of clothingData:", type(clothingData))
    if not player then
        print("Error: Player not found for source " .. src)
        return
    end

    -- Ensure clothing data is valid
    if not clothingData or type(clothingData) ~= "table" then
        print("Error: Invalid clothing data")
        return
    end
    
    -- Debugging output
    print("Saving Clothing Data for " .. player.firstname .. " " .. player.lastname)

    -- Convert clothing data to JSON string for saving
    local clothingDataJson = json.encode(clothingData)
    print("Clothing Data :", clothingData)
    print("Clothing Data JSON:", clothingDataJson)
    
    -- Save clothing data to the database
    local characterId = player.id
    MySQL.Async.execute('UPDATE nd_characters SET clothing = @clothing WHERE charid = @charid', {
        ['@clothing'] = clothingDataJson,
        ['@charid'] = characterId
    }, function(rowsChanged)
        if rowsChanged > 0 then
            print("Clothing data saved successfully for " .. player.firstname .. " " .. player.lastname)
        else
            print("Failed to save clothing data for " .. player.firstname .. " " .. player.lastname)
        end
    end)
end)

-- Server-side event to send clothing data to the client
RegisterNetEvent('ND_AppearanceShops:getCharacterOutfit')
AddEventHandler('ND_AppearanceShops:getCharacterOutfit', function()
    local src = source
    local player = NDCore.getPlayer(src)  -- Retrieve player object

    if not player then
        print("Error: Player not found for source " .. src)
        return
    end

    -- Retrieve clothing data from the database
    MySQL.Async.fetchScalar('SELECT clothing FROM nd_characters WHERE charid = @charid', {
        ['@charid'] = player.id
    }, function(clothingDataJson)
        if clothingDataJson then
            -- Send clothing data to the client to apply
            TriggerClientEvent('ND_AppearanceShops:applyCharacterOutfit', src, clothingDataJson)
        else
            print("No clothing data found for player " .. player.firstname .. " " .. player.lastname)
        end
    end)
end)
