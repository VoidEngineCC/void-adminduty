local QBCore = exports['qb-core']:GetCoreObject()
local isAdminOnDuty = false
local previousAppearance = nil
local adminDutyPlayers = {} -- Track all admins on duty

-- Function to set admin model
local function SetAdminModel()
    local playerPed = PlayerPedId()
    
    -- Save current appearance if illenium-appearance is available
    if exports['illenium-appearance'] then
        previousAppearance = exports['illenium-appearance']:getPedAppearance(playerPed)
        print("Saved appearance with illenium-appearance")
    else
        -- Fallback: save the model hash
        previousAppearance = GetEntityModel(playerPed)
        print("Saved model hash as fallback")
    end
    
    -- Set admin model (using s_m_m_chemsec_01 as example admin model)
    local modelHash = GetHashKey('s_m_m_chemsec_01')
    RequestModel(modelHash)
    
    while not HasModelLoaded(modelHash) do
        Wait(500)
        RequestModel(modelHash)
    end
    
    SetPlayerModel(PlayerId(), modelHash)
    SetPedDefaultComponentVariation(PlayerPedId())
    
    -- Wait a moment for the model to fully load
    Wait(500)
    
    -- Set minimal clothing
    SetPedComponentVariation(PlayerPedId(), 0, 0, 0, 2)  -- Head
    SetPedComponentVariation(PlayerPedId(), 1, 0, 0, 2)  -- Mask
    SetPedComponentVariation(PlayerPedId(), 2, 0, 0, 2)  -- Hair
    SetPedComponentVariation(PlayerPedId(), 3, 0, 0, 2)  -- Torso
    SetPedComponentVariation(PlayerPedId(), 4, 0, 0, 2)  -- Legs
    SetPedComponentVariation(PlayerPedId(), 6, 0, 0, 2)  -- Shoes
    SetPedComponentVariation(PlayerPedId(), 8, 0, 0, 2)  -- Undershirt
    SetPedComponentVariation(PlayerPedId(), 11, 0, 0, 2) -- Top
    
    SetModelAsNoLongerNeeded(modelHash)
    
    -- Add yourself to admin duty players list (server will send the actual data)
    local playerId = GetPlayerServerId(PlayerId())
    adminDutyPlayers[playerId] = {
        onDuty = true,
        name = GetPlayerName(PlayerId()),
        title = "Staff",
        color = {255, 255, 255, 255}
    }
    
    print("Admin model set successfully")
end

-- Function to restore previous appearance
local function RestorePreviousAppearance()
    if not previousAppearance then 
        print("No previous appearance to restore")
        return 
    end
    
    if exports['illenium-appearance'] and type(previousAppearance) == 'table' then
        -- Use illenium-appearance to restore the full appearance
        exports['illenium-appearance']:setPlayerAppearance(previousAppearance)
        print("Restored appearance with illenium-appearance")
    else
        -- Fallback: reset to default model (mp_m_freemode_01)
        local model = GetHashKey('mp_m_freemode_01')
        RequestModel(model)
        while not HasModelLoaded(model) do
            Wait(500)
            RequestModel(model)
        end
        SetPlayerModel(PlayerId(), model)
        SetModelAsNoLongerNeeded(model)
        
        -- Wait for model to load
        Wait(500)
        
        -- Set some default clothing
        local playerPed = PlayerPedId()
        SetPedComponentVariation(playerPed, 0, 0, 0, 2)  -- Head
        SetPedComponentVariation(playerPed, 2, 0, 0, 2)  -- Hair
        SetPedComponentVariation(playerPed, 3, 0, 0, 2)  -- Torso
        SetPedComponentVariation(playerPed, 4, 0, 0, 2)  -- Legs
        SetPedComponentVariation(playerPed, 6, 0, 0, 2)  -- Shoes
        SetPedComponentVariation(playerPed, 8, 15, 0, 2)  -- Undershirt
        SetPedComponentVariation(playerPed, 11, 15, 0, 2) -- Top
        print("Restored default model as fallback")
    end
    
    -- Remove yourself from admin duty players list
    local playerId = GetPlayerServerId(PlayerId())
    adminDutyPlayers[playerId] = nil
end

-- Function to draw floating text above admins
local function DrawFloatingAdminText()
    for playerId, adminData in pairs(adminDutyPlayers) do
        if adminData.onDuty then
            local player = GetPlayerFromServerId(playerId)
            if player ~= -1 then
                local ped = GetPlayerPed(player)
                local playerCoords = GetEntityCoords(ped)
                
                -- Position text above the player's head
                local titleCoords = vector3(playerCoords.x, playerCoords.y, playerCoords.z + 1.0)
                local nameCoords = vector3(playerCoords.x, playerCoords.y, playerCoords.z + 2.0) -- REMOVED
                
                -- Check if the player is on screen and within distance
                if #(GetEntityCoords(PlayerPedId()) - playerCoords) < 50.0 and HasEntityClearLosToEntity(PlayerPedId(), ped, 17) then
                    -- Draw the title text
                    SetDrawOrigin(titleCoords.x, titleCoords.y, titleCoords.z, 0)
                    SetTextScale(0.30, 0.30)
                    SetTextFont(4)
                    SetTextProportional(true)
                    SetTextColour(adminData.color[1], adminData.color[2], adminData.color[3], adminData.color[4])
                    SetTextDropshadow(0, 0, 0, 0, 255)
                    SetTextEdge(2, 0, 0, 0, 150)
                    SetTextDropShadow()
                    SetTextOutline()
                    SetTextEntry("STRING")
                    SetTextCentre(true)
                    AddTextComponentString(adminData.name.."[" .. adminData.title .. "]")
                    DrawText(0.0, 0.0)
                    ClearDrawOrigin()
                end
            end
        end
    end
end

-- Toggle admin duty
local function ToggleAdminDuty()
    -- Request server to check permissions
    QBCore.Functions.TriggerCallback('qb-admin:duty:checkPermission', function(hasPermission)
        if not hasPermission then
            QBCore.Functions.Notify('No permission to use admin duty.', 'error')
            return
        end
        
        if isAdminOnDuty then
            -- Go off duty
            isAdminOnDuty = false
            RestorePreviousAppearance()
            QBCore.Functions.Notify('Admin duty disabled.', 'success')
            
            -- Notify server
            TriggerServerEvent('qb-admin:duty:offduty')
        else
            -- Go on duty
            isAdminOnDuty = true
            SetAdminModel()
            QBCore.Functions.Notify('Admin duty enabled.', 'success')
            
            -- Notify server
            TriggerServerEvent('qb-admin:duty:onduty')
        end
    end)
end

-- Sync admin duty status with other players
RegisterNetEvent('qb-admin:duty:syncPlayer')
AddEventHandler('qb-admin:duty:syncPlayer', function(playerId, adminData)
    adminDutyPlayers[playerId] = adminData
    if adminData then
        print("Synced admin duty for player " .. playerId .. ": " .. adminData.name)
    else
        print("Removed admin duty for player " .. playerId)
        adminDutyPlayers[playerId] = nil
    end
end)

-- Sync all admin duty players when joining
RegisterNetEvent('qb-admin:duty:syncAll')
AddEventHandler('qb-admin:duty:syncAll', function(players)
    adminDutyPlayers = players or {}
    print("Synced all admin duty players: " .. #players .. " players on duty")
end)

-- Command registration
RegisterCommand('duty', function()
    ToggleAdminDuty()
end, false)

-- Debug command to check permissions
RegisterCommand('checkadmin', function()
    QBCore.Functions.TriggerCallback('qb-admin:duty:checkPermission', function(hasPermission)
        print("Admin permission result: " .. tostring(hasPermission))
        print("illenium-appearance export available: " .. tostring(exports['illenium-appearance'] ~= nil))
        QBCore.Functions.Notify('Admin check: ' .. tostring(hasPermission), hasPermission and 'success' or 'error')
    end)
end, false)

-- Draw floating text in a loop
Citizen.CreateThread(function()
    while true do
        Wait(0)
        DrawFloatingAdminText()
    end
end)

-- Event handlers
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    isAdminOnDuty = false
    previousAppearance = nil
    adminDutyPlayers = {}
    
    -- Request sync with all admin duty players
    TriggerServerEvent('qb-admin:duty:requestSync')
    print("Player loaded, admin duty reset")
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    if isAdminOnDuty then
        RestorePreviousAppearance()
    end
end)

-- Add this to ensure appearance is restored if script restarts
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName and isAdminOnDuty then
        RestorePreviousAppearance()
    end
end)

print("qb-admin-duty client script loaded successfully")