local savedZones = {}
local savePath = GetResourcePath(GetCurrentResourceName())..'/zones.json'

-- Load zones from file
local function LoadZones()
    if not LoadResourceFile(GetCurrentResourceName(), "zones.json") then
        SaveResourceFile(GetCurrentResourceName(), "zones.json", "[]", -1)
    end
    
    local fileContent = LoadResourceFile(GetCurrentResourceName(), "zones.json")
    if fileContent then
        local success, zones = pcall(json.decode, fileContent)
        if success and zones then
            savedZones = zones
            print(("Loaded %s zones from file"):format(#zones))
            return true
        else
            print("Error decoding zones file")
            return false
        end
    end
    return false
end

-- Save zones to file
local function SaveZones()
    if not savedZones then return false end
    
    local success, encoded = pcall(json.encode, savedZones, {indent = true, pretty = true})
    if success then
        local saved = SaveResourceFile(GetCurrentResourceName(), "zones.json", encoded, -1)
        if saved then
            print(("Saved %s zones to file"):format(#savedZones))
            return true
        end
    end
    print("Error saving zones to file")
    return false
end

-- Backup zones periodically
local function BackupZones()
    local timestamp = os.date("%Y-%m-%d_%H-%M-%S")
    local backupPath = "backups/zones_" .. timestamp .. ".json"
    
    local success, encoded = pcall(json.encode, savedZones)
    if success then
        SaveResourceFile(GetCurrentResourceName(), backupPath, encoded, -1)
        print(("Created backup: %s"):format(backupPath))
    end
end

-- Check if zone is valid
local function IsZoneValid(zone)
    if not zone or type(zone) ~= "table" then return false end
    if not zone.points or #zone.points < 3 then return false end
    if not zone.baseZ or not zone.height then return false end
    if not zone.bounds then return false end
    
    for _, point in ipairs(zone.points) do
        if not point.x or not point.y or not point.z then
            return false
        end
    end
    
    return true
end

-- Validate zones
local function ValidateZones(zones)
    if type(zones) ~= "table" then return false end
    
    for id, zone in pairs(zones) do
        if not IsZoneValid(zone) then
            print(("Invalid zone found at index %s"):format(id))
            return false
        end
    end
    
    return true
end

-- Server events
RegisterNetEvent('zones:save')
AddEventHandler('zones:save', function(zones)
    -- Validate source if needed
    -- local source = source
    -- if not IsPlayerAceAllowed(source, "zone.admin") then return end
    
    if not ValidateZones(zones) then
        print("Zone validation failed")
        return
    end
    
    savedZones = zones
    SaveZones()
    
    -- Create backup every hour
    if os.time() % 3600 < 10 then
        BackupZones()
    end
    
    -- Broadcast to all clients
    TriggerClientEvent('zones:receive', -1, savedZones)
end)

RegisterNetEvent('zones:request')
AddEventHandler('zones:request', function()
    local source = source
    TriggerClientEvent('zones:receive', source, savedZones)
end)

-- Admin commands
RegisterCommand('reloadzones', function(source, args, rawCommand)
    -- Check if source is console or has admin rights
    if source ~= 0 and not IsPlayerAceAllowed(source, "zone.admin") then
        return
    end
    
    if LoadZones() then
        TriggerClientEvent('zones:receive', -1, savedZones)
        print("Zones reloaded successfully")
    else
        print("Failed to reload zones")
    end
end, true)

RegisterCommand('exportzones', function(source, args, rawCommand)
    -- Check if source is console or has admin rights
    if source ~= 0 and not IsPlayerAceAllowed(source, "zone.admin") then
        return
    end
    
    local timestamp = os.date("%Y-%m-%d_%H-%M-%S")
    local exportPath = "exports/zones_" .. timestamp .. ".json"
    
    local success, encoded = pcall(json.encode, savedZones)
    if success then
        SaveResourceFile(GetCurrentResourceName(), exportPath, encoded, -1)
        print(("Exported zones to: %s"):format(exportPath))
    else
        print("Failed to export zones")
    end
end, true)

-- Server exports
exports('GetZones', function()
    return savedZones
end)

exports('GetZoneById', function(id)
    return savedZones[id]
end)

exports('SaveZones', function(zones)
    if not ValidateZones(zones) then
        return false
    end
    savedZones = zones
    return SaveZones()
end)

exports('ReloadZones', function()
    return LoadZones()
end)

-- Initialize on resource start
AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    
    -- Create necessary directories
    local resourcePath = GetResourcePath(resourceName)
    local backupPath = resourcePath .. '/backups'
    local exportPath = resourcePath .. '/exports'
    
    if not LoadResourceFile(resourceName, "backups/.gitkeep") then
        os.execute('mkdir "' .. backupPath .. '"')
        SaveResourceFile(resourceName, "backups/.gitkeep", "", -1)
    end
    
    if not LoadResourceFile(resourceName, "exports/.gitkeep") then
        os.execute('mkdir "' .. exportPath .. '"')
        SaveResourceFile(resourceName, "exports/.gitkeep", "", -1)
    end
    
    -- Load zones
    LoadZones()
end)

-- Backup zones before resource stops
AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    
    BackupZones()
    SaveZones()
end)