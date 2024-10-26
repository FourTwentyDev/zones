-- Initialize ZoneManager
ZoneManager = {
    zones = {},
    cachedChecks = {},
    cacheTimeout = Config.Cache.timeout or 500
}

-- Local helper functions
local function IsPointInPolygon(x, y, polygon)
    local inside = false
    local j = #polygon
    
    for i = 1, #polygon do
        if ((polygon[i].y > y) ~= (polygon[j].y > y)) and
           (x < (polygon[j].x - polygon[i].x) * (y - polygon[i].y) / 
           (polygon[j].y - polygon[i].y) + polygon[i].x) then
            inside = not inside
        end
        j = i
    end
    
    return inside
end

function ZoneManager.IsPointInZone(point, zone)
    if not point or not zone then return false end
    
    -- Quick bounding box check
    if point.x < zone.bounds.minX or point.x > zone.bounds.maxX or
       point.y < zone.bounds.minY or point.y > zone.bounds.maxY then
        return false
    end
    
    -- Height check
    if point.z < zone.baseZ or point.z > zone.baseZ + zone.height then
        return false
    end
    
    return IsPointInPolygon(point.x, point.y, zone.points)
end

-- Core zone management functions
function ZoneManager.SaveZone(points, name)
    -- Find lowest point as base Z coordinate
    local baseZ = points[1].z
    for i = 2, #points do
        baseZ = math.min(baseZ, points[i].z)
    end
    
    -- Calculate bounding box for quick intersection tests
    local minX, minY = points[1].x, points[1].y
    local maxX, maxY = points[1].x, points[1].y
    
    for i = 2, #points do
        minX = math.min(minX, points[i].x)
        minY = math.min(minY, points[i].y)
        maxX = math.max(maxX, points[i].x)
        maxY = math.max(maxY, points[i].y)
    end
    
    -- Create optimized zone structure
    local zone = {
        name = name,
        points = points,
        bounds = {
            maxX = maxX,
            minY = minY, 
            minX = minX,
            maxY = maxY
        },
        height = Config.Zone.height,
        baseZ = baseZ
    }
    
    -- Add zone to manager and generate ID
    local zoneId = #ZoneManager.zones + 1
    ZoneManager.zones[zoneId] = zone
    
    -- Save to server
    ZoneManager.SaveZonesToServer()
    
    return zoneId, zone
end

function ZoneManager.DeleteZone(zoneId)
    if ZoneManager.zones[zoneId] then
        ZoneManager.zones[zoneId] = nil
        ZoneManager.SaveZonesToServer()
        return true
    end
    return false
end

function ZoneManager.UpdateZone(zoneId, zone)
    if ZoneManager.zones[zoneId] then
        ZoneManager.zones[zoneId] = zone
        ZoneManager.SaveZonesToServer()
        return true
    end
    return false
end

function ZoneManager.ClearZones()
    ZoneManager.zones = {}
    ZoneManager.SaveZonesToServer()
end

function ZoneManager.GetZoneCount()
    return #ZoneManager.zones
end

-- Player and entity checking functions
function ZoneManager.IsPlayerInAnyZone(playerId)
    local now = GetGameTimer()
    local cache = ZoneManager.cachedChecks[playerId]
    
    -- Check cache
    if cache and (now - cache.timestamp) < ZoneManager.cacheTimeout then
        return cache.result, cache.zoneId, cache.name
    end
    
    local ped = GetPlayerPed(playerId)
    local pos = GetEntityCoords(ped)
    
    for zoneId, zone in pairs(ZoneManager.zones) do
        if ZoneManager.IsPointInZone(pos, zone) then
            -- Update cache
            ZoneManager.cachedChecks[playerId] = {
                timestamp = now,
                result = true,
                zoneId = zoneId,
                name = zone.name
            }
            return true, zoneId, zone.name
        end
    end
    
    -- Update cache for negative result
    ZoneManager.cachedChecks[playerId] = {
        timestamp = now,
        result = false,
        zoneId = nil,
        name = nil
    }
    return false, nil, nil
end

function ZoneManager.GetPlayersInZone(zoneId)
    local players = {}
    local zone = ZoneManager.zones[zoneId]
    if not zone then return players end
    
    for _, playerId in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(playerId)
        local pos = GetEntityCoords(ped)
        if ZoneManager.IsPointInZone(pos, zone) then
            table.insert(players, playerId)
        end
    end
    
    return players
end

function ZoneManager.GetEntitiesInZone(zoneId, entityType)
    local zone = ZoneManager.zones[zoneId]
    if not zone then return {} end
    
    local entities = {}
    local entityList = {}
    
    if entityType == 'peds' or not entityType then
        entityList = GetGamePool('CPed')
    elseif entityType == 'vehicles' then
        entityList = GetGamePool('CVehicle')
    elseif entityType == 'objects' then
        entityList = GetGamePool('CObject')
    end
    
    for _, entity in ipairs(entityList) do
        local pos = GetEntityCoords(entity)
        if ZoneManager.IsPointInZone(pos, zone) then
            table.insert(entities, entity)
        end
    end
    
    return entities
end

-- Zone finding and utility functions
function ZoneManager.GetNearestZone(point)
    local nearestDist = math.huge
    local nearestZone = nil
    local nearestId = nil
    
    for id, zone in pairs(ZoneManager.zones) do
        local centerX = (zone.bounds.minX + zone.bounds.maxX) / 2
        local centerY = (zone.bounds.minY + zone.bounds.maxY) / 2
        local dist = #(vector2(point.x, point.y) - vector2(centerX, centerY))
        
        if dist < nearestDist then
            nearestDist = dist
            nearestZone = zone
            nearestId = id
        end
    end
    
    return nearestId, nearestZone, nearestDist
end

function ZoneManager.GetZonesByName(name)
    local matchingZones = {}
    for id, zone in pairs(ZoneManager.zones) do
        if zone.name == name then
            matchingZones[id] = zone
        end
    end
    return matchingZones
end

function ZoneManager.GetZonesInRadius(point, radius)
    local zonesInRadius = {}
    for id, zone in pairs(ZoneManager.zones) do
        local centerX = (zone.bounds.minX + zone.bounds.maxX) / 2
        local centerY = (zone.bounds.minY + zone.bounds.maxY) / 2
        local dist = #(vector2(point.x, point.y) - vector2(centerX, centerY))
        
        if dist <= radius then
            zonesInRadius[id] = zone
        end
    end
    return zonesInRadius
end

-- Server communication functions
function ZoneManager.SaveZonesToServer()
    TriggerServerEvent('zones:save', ZoneManager.zones)
end

function ZoneManager.RequestZonesFromServer()
    TriggerServerEvent('zones:request')
end

-- Cache management
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(10000) -- Every 10 seconds
        local now = GetGameTimer()
        for playerId, cache in pairs(ZoneManager.cachedChecks) do
            if (now - cache.timestamp) > ZoneManager.cacheTimeout * 2 then
                ZoneManager.cachedChecks[playerId] = nil
            end
        end
    end
end)

-- Event handlers
RegisterNetEvent('zones:receive')
AddEventHandler('zones:receive', function(zones)
    if zones then
        ZoneManager.zones = zones
        print(("Loaded %s zones from server"):format(#zones))
    end
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    ZoneManager.RequestZonesFromServer()
end)

-- Export functions
exports('IsPointInZone', function(point, zone) return ZoneManager.IsPointInZone(point, zone) end)
exports('IsPlayerInAnyZone', function(playerId) return ZoneManager.IsPlayerInAnyZone(playerId) end)
exports('GetZones', function() return ZoneManager.zones end)
exports('GetZoneById', function(id) return ZoneManager.zones[id] end)
exports('GetZonesByName', function(name) return ZoneManager.GetZonesByName(name) end)
exports('GetNearestZone', function(point) return ZoneManager.GetNearestZone(point) end)
exports('GetEntitiesInZone', function(zoneId, entityType) return ZoneManager.GetEntitiesInZone(zoneId, entityType) end)
exports('GetPlayersInZone', function(zoneId) return ZoneManager.GetPlayersInZone(zoneId) end)
exports('GetZonesInRadius', function(point, radius) return ZoneManager.GetZonesInRadius(point, radius) end)
exports('SaveZone', function(points, name) return ZoneManager.SaveZone(points, name) end)
exports('DeleteZone', function(zoneId) return ZoneManager.DeleteZone(zoneId) end)
exports('UpdateZone', function(zoneId, zone) return ZoneManager.UpdateZone(zoneId, zone) end)
exports('ClearZones', function() ZoneManager.ClearZones() end)
exports('GetZoneCount', function() return ZoneManager.GetZoneCount() end)