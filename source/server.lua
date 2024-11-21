lib.callback.register("ND_AppearanceShops:clothingPurchase", function(src, store, clothing)
    local store = Config[store]
    local player = NDCore.getPlayer(src)
    if not store or not player then return end

    local price = store.price
    if not price then return true end
    if not player.deductMoney("bank", price, store.blip.label) then
        player.notify({
            title = store.blip.label,
            description = ("Payment of $%d failed!"):format(price),
            position = "bottom",
            type = "error"
        })
        return
    end

    if clothing and type(clothing) == "table" then
        player.setMetadata("clothing", clothing)
    end
    player.notify({
        title = store.blip.label,
        description = ("Payment of $%d confirmed!"):format(price),
        position = "bottom",
        type = "success"
    })
    return true
end)

RegisterNetEvent("ND_AppearanceShops:updateAppearance", function(clothing)
    local src = source
    local player = NDCore.getPlayer(src)
    if not player then return end

    if clothing and type(clothing) == "table" then
        player.setMetadata("clothing", clothing)
    end
end)

-- Server-side event to save the player's clothing data
RegisterNetEvent('fivemAppearance:saveCharacterOutfit')
AddEventHandler('fivemAppearance:saveCharacterOutfit', function(clothingDataJson)
    local src = source
    local character = NDCore.getPlayer(src)  -- Ensure this correctly retrieves the player

    if not character then
        print("Error: Player not found for source " .. src)
        return
    end

    -- Decode the JSON data to get the clothing data
    local clothingData = json.decode(clothingDataJson)
    
    -- Check if clothing data is valid
    if not clothingData then
        print("Error: Failed to decode clothing data for player " .. character.firstname .. " " .. character.lastname)
        return
    end
    
    -- Debug print the clothing data
    print("Saving Clothing Data for " .. character.firstname .. " " .. character.lastname)
    print("Clothing Data: " .. clothingDataJson)

    -- Assuming you have a character ID or identifier to save the clothing data
    local characterId = character.id
    print(characterId)
    -- Re-encode the clothing data to ensure it's in JSON format
    local clothingDataJson = json.encode(clothingData)

    -- Example of inserting/updating the clothing data in the database
    MySQL.Async.execute('UPDATE nd_characters SET clothing = @clothing WHERE charid = @charid', {
        ['@clothing'] = clothingDataJson,
        ['@charid'] = characterId
    }, function(rowsChanged)
        if rowsChanged > 0 then
            print("Clothing data saved successfully for " .. character.firstname .. " " .. character.lastname)
        else
            print("Failed to save clothing data for " .. character.firstname .. " " .. character.lastname)
        end
    end)
end)

-- Server-side event to send clothing data to the client
RegisterNetEvent('fivemAppearance:getCharacterOutfit')
AddEventHandler('fivemAppearance:getCharacterOutfit', function()
    local src = source
    local character = NDCore.getPlayer(src)  -- Ensure this correctly retrieves the player

    if not character then
        print("Error: Player not found for source " .. src)
        return
    end

    -- Retrieve clothing data from the database
    MySQL.Async.fetchScalar('SELECT clothing FROM nd_characters WHERE charid = @charid', {
        ['@charid'] = character.id
    }, function(clothingDataJson)
        if clothingDataJson then
            -- Send the clothing data back to the client
            TriggerClientEvent('fivemAppearance:applyCharacterOutfit', src, clothingDataJson)
        else
            print("No clothing data found for player " .. character.firstname .. " " .. character.lastname)
        end
    end)
end)
