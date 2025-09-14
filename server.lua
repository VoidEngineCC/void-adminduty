QBCore = exports['qb-core']:GetCoreObject()

local adminDutyPlayers = {} -- Track all admins on duty server-wide

-- License to name and title mapping
local licenseToName = {
    ['license:'] = 'VoidEngineCC'
}

local licenseToTitle = {
    ['license:'] = 'Project Leader'
}

-- Title colors
local titleColors = {
    ['Project Leader'] = {187, 43, 43, 255},    
    ['Lead Developer'] = {22, 219, 209, 255},      
    ['Developer'] = {107, 6, 248, 255},         
    ['Server Manager'] = {255, 217, 0, 255},    
    ['Administrator'] = {255, 0, 0, 255},        
    ['Moderator'] = {16, 0, 255, 255},       
    ['Trial Staff'] = {255, 255, 255, 255},      
    ['Default'] = {255, 255, 255, 255}       
}

-- Check if player has admin permissions
QBCore.Functions.CreateCallback('qb-admin:duty:checkPermission', function(source, cb)
    local player = source
    local Player = QBCore.Functions.GetPlayer(player)
    local hasPermission = false
    
    if Player then
        local license = QBCore.Functions.GetIdentifier(player, 'license')
        
        -- Check if license is in admin list
        if license and licenseToName[license] then
            hasPermission = true
            print("Player has license-based permission: " .. license)
        end
        
        -- Fallback to ACE permissions
        if not hasPermission and (IsPlayerAceAllowed(player, "command") or 
           IsPlayerAceAllowed(player, "admin") or 
           IsPlayerAceAllowed(player, "moderator") or 
           IsPlayerAceAllowed(player, "god")) then
            hasPermission = true
            print("Player has ACE permission")
        end
    end
    
    cb(hasPermission)
end)

-- Event for when admin goes on duty
RegisterServerEvent('qb-admin:duty:onduty')
AddEventHandler('qb-admin:duty:onduty', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        local license = QBCore.Functions.GetIdentifier(src, 'license')
        local name = licenseToName[license] or GetPlayerName(src)
        local title = licenseToTitle[license] or 'Staff'
        local color = titleColors[title] or titleColors['Staff']
        
        -- Add player to admin duty list with custom data
        adminDutyPlayers[src] = {
            onDuty = true,
            name = name,
            title = title,
            color = color
        }
        
        -- Sync with all players
        TriggerClientEvent('qb-admin:duty:syncPlayer', -1, src, adminDutyPlayers[src])
        
        print(GetPlayerName(src) .. " (" .. name .. ") has gone on admin duty as " .. title)
    end
end)

-- Event for when admin goes off duty
RegisterServerEvent('qb-admin:duty:offduty')
AddEventHandler('qb-admin:duty:offduty', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        -- Remove player from admin duty list
        adminDutyPlayers[src] = nil
        
        -- Sync with all players
        TriggerClientEvent('qb-admin:duty:syncPlayer', -1, src, false)
        
        print(GetPlayerName(src) .. " has gone off admin duty.")
    end
end)

-- Handle sync requests
RegisterServerEvent('qb-admin:duty:requestSync')
AddEventHandler('qb-admin:duty:requestSync', function()
    local src = source
    TriggerClientEvent('qb-admin:duty:syncAll', src, adminDutyPlayers)
    print("Sent admin duty sync to player " .. src)
end)

-- Clean up when player disconnects
AddEventHandler('playerDropped', function(reason)
    local src = source
    if adminDutyPlayers[src] then
        adminDutyPlayers[src] = nil
        TriggerClientEvent('qb-admin:duty:syncPlayer', -1, src, false)
        print("Player " .. src .. " disconnected, removed from admin duty list")
    end
end)


print("qb-admin-duty server script loaded successfully")
