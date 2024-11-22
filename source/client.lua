local wardrobeId = "ND_AppearanceShops:wardrobe"
local wardrobeSelectedId = ("%s_selected"):format(wardrobeId)
local wardrobe = json.decode(GetResourceKvpString(wardrobeId)) or {}
local currentOpenWardrobe
local fivemAppearance = exports["fivem-appearance"]

local function inputOutfitName()
    local input = lib.inputDialog("Save current outfit", {"Outfit name:"})
    local name = input?[1]
    if name and name ~= "" then
        return name
    end
end

local function saveWardrobe(name)
    if not name then return end
    local appearance = fivemAppearance:getPedAppearance(cache.ped)
    appearance.hair = nil
    appearance.headOverlays = nil
    appearance.tattoos = nil
    appearance.faceFeatures = nil
    appearance.headBlend = nil
    wardrobe[#wardrobe+1] = {
        name = name,
        appearance = appearance
    }
    SetResourceKvp(wardrobeId, json.encode(wardrobe))
    return true
end

local function getWardrobe()
    local options = {
        {
            title = "Save current outfit",
            icon = "fa-solid fa-floppy-disk",
            onSelect = function()
                saveWardrobe(inputOutfitName())
            end
        }
    }
    for i=1, #wardrobe do
        local info = wardrobe[i]
        options[#options+1] = {
            title = info.name,
            arrow = true,
            onSelect = function()
                currentOpenWardrobe = i
                lib.showContext(wardrobeSelectedId)
            end
        }
    end
    return options
end

local function openWardrobe(menu)
    lib.registerContext({
        id = wardrobeId,
        menu = menu,
        title = "Outfits",
        options = getWardrobe()
    })
    lib.showContext(wardrobeId)
end

local function startChange(coords, options, i)
    local ped = cache.ped
    local oldAppearance = fivemAppearance:getPedAppearance(ped)
    SetEntityCoords(ped, coords.x, coords.y, coords.z-1.0)
    SetEntityHeading(ped, coords.w)
    Wait(250)
    fivemAppearance:startPlayerCustomization(function(appearance)
        if not appearance then return end

        ped = PlayerPedId()
        local clothing = fivemAppearance:getPedAppearance(ped)

        if not lib.callback.await("ND_AppearanceShops:clothingPurchase", false, i, clothing) then
            fivemAppearance:setPlayerModel(oldAppearance.model)
            ped = PlayerPedId()
            fivemAppearance:setPedTattoos(ped, oldAppearance.tattoos)
            fivemAppearance:setPedAppearance(ped, oldAppearance.appearance)
                -- Retrieve appearance data
                local components = fivemAppearance:getPedComponents(ped)
                local props = fivemAppearance:getPedProps(ped)
                local tattoos = fivemAppearance:getPedTattoos(ped)
                local faceFeatures = fivemAppearance:getPedFaceFeatures(ped)
                local headOverlays = fivemAppearance:getPedHeadOverlays(ped)
                local hair = fivemAppearance:getPedHair(ped)
            
                -- Package the data into a table
                local clothingData = {
                    components = components,
                    props = props,
                    tattoos = tattoos,
                    faceFeatures = faceFeatures,
                    headOverlays = headOverlays,
                    hair = hair
                }
            
                -- Serialize the data into JSON format
                local clothingDataJson = json.encode(clothingData)
                -- Send the data to the server to save
                TriggerServerEvent('fivemAppearance:saveCharacterOutfit', clothingDataJson)
        end
    end, options)
end

local function getStoreNumber(store)
    for i=1, #Config do
        if store == Config[i] then
            return i
        end
    end

    local number = #Config+1
    Config[number] = store
    return number
end

local function createClothingStore(info)
    local storeNumber = getStoreNumber(info)
    for i=1, #info.locations do
        local location = info.locations[i]
        local options = {
            {
                name = "nd_core:appearanceShops",
                icon = "fa-solid fa-bag-shopping",
                label = info.text,
                distance = 2.0,
                onSelect = function(data)
                    startChange(location.change, info.appearance, storeNumber)
                end
            }
        }
        if info.appearance?.components then
            options[#options+1] = {
                name = "nd_core:appearanceOutfit",
                icon = "fa-solid fa-shirt",
                label = "View outfits",
                distance = 2.0,
                onSelect = function(data)
                    openWardrobe()
                end
            }
        end
        NDCore.createAiPed({
            resource = GetInvokingResource(),
            model = location.model,
            coords = location.worker,
            distance = 25.0,
            blip = info.blip,
            options = options,
            anim = {
                dict = "anim@amb@casino@valet_scenario@pose_d@",
                clip = "base_a_m_y_vinewood_01"
            }
        })
    end
end

lib.registerContext({
    id = wardrobeSelectedId,
    title = "Outfits",
    menu = wardrobeId,
    options = {
        {
            title = "Wear",
            icon = "fa-solid fa-shirt",
            onSelect = function()
                local selected = wardrobe[currentOpenWardrobe]
                if not selected then return end
                if GetHashKey(selected.appearance.model) ~= GetEntityModel(cache.ped) then
                    return lib.notify({
                        title = "Incorrect player model",
                        description = "This saved outfit is not for the current player model",
                        type = "error"
                    })
                end
                fivemAppearance:setPedAppearance(cache.ped, selected.appearance)
                TriggerServerEvent("ND_AppearanceShops:updateAppearance", fivemAppearance:getPedAppearance(cache.ped))
                -- Get the player's ped (character)
                local ped = PlayerPedId()
            
                -- Retrieve appearance data
                local components = fivemAppearance:getPedComponents(ped)
                local props = fivemAppearance:getPedProps(ped)
                local tattoos = fivemAppearance:getPedTattoos(ped)
                local faceFeatures = fivemAppearance:getPedFaceFeatures(ped)
                local headOverlays = fivemAppearance:getPedHeadOverlays(ped)
                local hair = fivemAppearance:getPedHair(ped)
            
                -- Package the data into a table
                local clothingData = {
                    components = components,
                    props = props,
                    tattoos = tattoos,
                    faceFeatures = faceFeatures,
                    headOverlays = headOverlays,
                    hair = hair
                }
            
                -- Serialize the data into JSON format
                local clothingDataJson = json.encode(clothingData)
                -- Send the data to the server to save
                TriggerServerEvent('ND_AppearanceShops:saveCharacterOutfit', source, clothingData)
            end
        },
        {
            title = "Edit name",
            icon = "fa-solid fa-pen-to-square",
            onSelect = function()
                local selected = wardrobe[currentOpenWardrobe]
                if not selected then return end
                local name = inputOutfitName()
                if not name then return end
                selected.name = name
            end
        },
        {
            title = "Remove",
            icon = "fa-solid fa-trash-can",
            onSelect = function()
                local selected = wardrobe[currentOpenWardrobe]
                if not selected then return end
                local alert = lib.alertDialog({
                    header = "Remove outfit?",
                    content = ("Are you sure you'd like to remove %s?"):format(selected.name),
                    centered = true,
                    cancel = true
                })
                if alert ~= "confirm" then return end
                table.remove(wardrobe, currentOpenWardrobe)
            end
        }
    }
})

for i=1, #Config do
    createClothingStore(Config[i])
end

AddEventHandler("onResourceStop", function(resource)
    if resource ~= cache.resource then return end
    SetResourceKvp(wardrobeId, json.encode(wardrobe))
end)

-- Client-side event to apply the clothing data
RegisterNetEvent('fivemAppearance:applyCharacterOutfit')
AddEventHandler('fivemAppearance:applyCharacterOutfit', function(clothingDataJson)
    -- Decode the received JSON data
    local clothingData = json.decode(clothingDataJson)

    if not clothingData then
        print("Error: Failed to decode clothing data.")
        return
    end

    -- Get the player's ped (character)
    local ped = PlayerPedId()

    -- Apply the clothing data to the player's character
    fivemAppearance:setPedComponents(ped, clothingData.components)
    fivemAppearance:setPedProps(ped, clothingData.props)
    fivemAppearance:setPedTattoos(ped, clothingData.tattoos)
    fivemAppearance:setPedFaceFeatures(ped, clothingData.faceFeatures)
    fivemAppearance:setPedHeadOverlays(ped, clothingData.headOverlays)
    fivemAppearance:setPedHair(ped, clothingData.hair)

    print("Clothing data applied to player.")
end)

-- Listen for the ND:characterLoaded event (local client event)
RegisterNetEvent("ND:characterLoaded")
AddEventHandler("ND:characterLoaded", function(character)
    if character then
        -- Debug output
        print("Character Loaded:", character.metadata, character.lastname)
    -- Trigger the server to get the saved character outfit
    TriggerServerEvent('ND_AppearanceShops:getCharacterOutfit')
        -- Call the openWardrobe export from ND_AppearanceShops
        exports["ND_AppearanceShops"]:openWardrobe()
    else
        print("Character data not received!")
    end
end)

-- Listen for the server event to load character outfit
RegisterNetEvent('ND_AppearanceShops:loadCharacterOutfit')
AddEventHandler('ND_AppearanceShops:loadCharacterOutfit', function(clothingData)
    -- Check if the clothing data is valid (it should be a JSON string)
    if clothingData then
        -- Deserialize the clothing data from JSON
        local clothing = json.decode(clothingData)

        -- Check if the clothing data is valid
        if clothing then
            -- Get the player's ped
            local ped = PlayerPedId()

            -- Apply the saved appearance data (clothing, props, tattoos, etc.)
            fivemAppearance:setPedAppearance(ped, clothing)
            print("Clothing data applied to player")
        else
            print("Error: Failed to decode clothing data.")
        end
    else
        print("No clothing data received from the server.")
    end
end)

exports("openWardrobe", openWardrobe)
exports("createClothingStore", createClothingStore)
