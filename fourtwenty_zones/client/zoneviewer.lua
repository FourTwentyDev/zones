--[[
    Zone Management System
    Complete class including:
    - All zone display functionality
    - All zone management commands
    - Helper functions
    - Chat message handling
]]

ZoneDisplay = {
    active = false,
    displayThread = nil
}

-- Helper functions for zone management
local function findZone(nameOrId)
    -- Try to convert to number for ID lookup
    local zoneId = tonumber(nameOrId)
    if zoneId then
        return zoneId, ZoneManager.zones[zoneId]
    end
    
    -- Search by name (case insensitive)
    for id, zone in pairs(ZoneManager.zones) do
        if zone.name:lower() == nameOrId:lower() then
            return id, zone
        end
    end
    
    return nil, nil
end

-- Validates zone names to only allow letters and underscores
local function isValidZoneName(name)
    return name:match("^[%a_]+$") ~= nil
end

-- Toggle zone visibility
function ZoneDisplay.Toggle()
    ZoneDisplay.active = not ZoneDisplay.active
    
    if ZoneDisplay.active then
        ZoneDisplay.StartDisplayThread()
        TriggerEvent('chat:addMessage', {
            color = {0, 255, 0},
            args = {'ZONES', 'Zone Display: Enabled'}
        })
    else
        if ZoneDisplay.displayThread then
            ZoneDisplay.displayThread = nil
        end
        TriggerEvent('chat:addMessage', {
            color = {255, 223, 0},
            args = {'ZONES', 'Zone Display: Disabled'}
        })
    end
end

-- Main display thread for rendering all zones
function ZoneDisplay.StartDisplayThread()
    -- Kill existing thread if any
    if ZoneDisplay.displayThread then
        ZoneDisplay.displayThread = nil
        Wait(100)
    end
    
    ZoneDisplay.displayThread = Citizen.CreateThread(function()
        while ZoneDisplay.active do
            Citizen.Wait(0)
            for zoneId, zone in pairs(ZoneManager.zones) do
                ZoneDisplay.DrawZoneFill(zone)
                ZoneDisplay.DrawZoneOutline(zone)
                ZoneDisplay.DrawVerticalLines(zone)
                ZoneDisplay.DrawZoneName(zone)
            end
        end
    end)
end

-- Draw fill lines for zone
function ZoneDisplay.DrawZoneFill(zone)
    for height = 0, zone.height, Config.Zone.fillSpacing do
        for i = 1, #zone.points do
            local current = zone.points[i]
            local next = zone.points[i + 1] or zone.points[1]
            
            for j = 0, 1, 0.1 do
                local x1 = current.x + (next.x - current.x) * j
                local y1 = current.y + (next.y - current.y) * j
                local x2 = current.x + (next.x - current.x) * (j + 0.05)
                local y2 = current.y + (next.y - current.y) * (j + 0.05)
                
                DrawLine(
                    x1, y1, zone.baseZ + height,
                    x2, y2, zone.baseZ + height,
                    Config.Colors.fill.r, Config.Colors.fill.g, Config.Colors.fill.b, Config.Colors.fill.a
                )
            end
        end
    end
end

-- Draw zone outline
function ZoneDisplay.DrawZoneOutline(zone)
    for height = 0, zone.height, Config.Zone.spacing do
        for i = 1, #zone.points do
            local current = zone.points[i]
            local next = zone.points[i + 1] or zone.points[1]
            
            DrawLine(
                current.x, current.y, zone.baseZ + height,
                next.x, next.y, zone.baseZ + height,
                Config.Colors.zone.r, Config.Colors.zone.g, Config.Colors.zone.b, Config.Colors.zone.a
            )
        end
    end
end

-- Draw vertical lines at corners
function ZoneDisplay.DrawVerticalLines(zone)
    for i = 1, #zone.points do
        local current = zone.points[i]
        DrawLine(
            current.x, current.y, zone.baseZ,
            current.x, current.y, zone.baseZ + zone.height,
            Config.Colors.zone.r, Config.Colors.zone.g, Config.Colors.zone.b, Config.Colors.zone.a
        )
    end
end

-- Draw zone name with distance-based scaling
function ZoneDisplay.DrawZoneName(zone)
    -- Calculate center position
    local centerX = (zone.bounds.minX + zone.bounds.maxX) / 2
    local centerY = (zone.bounds.minY + zone.bounds.maxY) / 2
    local centerZ = zone.baseZ + zone.height + 1.0
    
    -- Calculate distance-based scale
    local playerPos = GetEntityCoords(PlayerPedId())
    local dist = #(playerPos - vector3(centerX, centerY, centerZ))
    local scale = math.max(0.4, math.min(1.0, 20.0 / dist))
    
    -- Draw the text
    ZoneDisplay.DrawText3D(centerX, centerY, centerZ, zone.name, scale)
end

-- Helper function to draw 3D text
function ZoneDisplay.DrawText3D(x, y, z, text, scale)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        -- Set text properties
        SetTextScale(scale, scale)
        SetTextFont(0)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        
        -- Add and draw text
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

-- ZONE MANAGEMENT COMMANDS

-- Command to list all available zones
RegisterCommand('zones', function()
    local count = 0
    
    -- Header message
    TriggerEvent('chat:addMessage', {
        color = {255, 223, 0},
        args = {'ZONES', 'Available zones:'}
    })
    
    -- List each zone
    for id, zone in pairs(ZoneManager.zones) do
        TriggerEvent('chat:addMessage', {
            color = {255, 255, 255},
            args = {'ZONES', ('[%d] %s'):format(id, zone.name)}
        })
        count = count + 1
    end
    
    -- Total count
    TriggerEvent('chat:addMessage', {
        color = {255, 223, 0},
        args = {'ZONES', ('Total zones: %d'):format(count)}
    })
end, false)

-- Command to delete a zone by ID or name
RegisterCommand('deletezone', function(source, args)
    -- Check for required arguments
    if #args < 1 then
        TriggerEvent('chat:addMessage', {
            color = {255, 0, 0},
            args = {'ZONES', 'Usage: /deletezone [id|name]'}
        })
        return
    end
    
    -- Find zone by ID or name
    local zoneId, zone = findZone(args[1])
    if not zone then
        TriggerEvent('chat:addMessage', {
            color = {255, 0, 0},
            args = {'ZONES', 'Zone not found'}
        })
        return
    end
    
    -- Attempt to delete the zone
    if ZoneManager.DeleteZone(zoneId) then
        TriggerEvent('chat:addMessage', {
            color = {0, 255, 0},
            args = {'ZONES', ('Deleted zone %s (%d)'):format(zone.name, zoneId)}
        })
    else
        TriggerEvent('chat:addMessage', {
            color = {255, 0, 0},
            args = {'ZONES', 'Failed to delete zone'}
        })
    end
end, false)

-- Command to rename a zone
RegisterCommand('renamezone', function(source, args)
    -- Check for required arguments
    if #args < 2 then
        TriggerEvent('chat:addMessage', {
            color = {255, 0, 0},
            args = {'ZONES', 'Usage: /renamezone [id|name] [new_name]'}
        })
        return
    end
    
    -- Find zone by ID or name
    local zoneId, zone = findZone(args[1])
    if not zone then
        TriggerEvent('chat:addMessage', {
            color = {255, 0, 0},
            args = {'ZONES', 'Zone not found'}
        })
        return
    end
    
    -- Validate new name
    local newName = args[2]
    if not isValidZoneName(newName) then
        TriggerEvent('chat:addMessage', {
            color = {255, 0, 0},
            args = {'ZONES', 'Invalid zone name. Use only letters and underscores'}
        })
        return
    end
    
    -- Check for name conflicts
    for id, existingZone in pairs(ZoneManager.zones) do
        if id ~= zoneId and existingZone.name:lower() == newName:lower() then
            TriggerEvent('chat:addMessage', {
                color = {255, 0, 0},
                args = {'ZONES', 'A zone with this name already exists'}
            })
            return
        end
    end
    
    -- Perform the rename
    local oldName = zone.name
    zone.name = newName
    
    if ZoneManager.UpdateZone(zoneId, zone) then
        TriggerEvent('chat:addMessage', {
            color = {0, 255, 0},
            args = {'ZONES', ('Renamed zone %s to %s'):format(oldName, newName)}
        })
    else
        TriggerEvent('chat:addMessage', {
            color = {255, 0, 0},
            args = {'ZONES', 'Failed to rename zone'}
        })
    end
end, false)


-- Command to toggle zone display
RegisterCommand('togglezones', function()
    ZoneDisplay.Toggle()
end, false)

-- Register keybind for toggling zones
RegisterKeyMapping('togglezones', 'Toggle Zone Display', 'keyboard', 'O')

-- Clean up on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- Disable zone display if active
    if ZoneDisplay.active then
        ZoneDisplay.active = false
        ZoneDisplay.displayThread = nil
    end
end)

-- Export functions for external use
exports('ToggleZoneDisplay', function() ZoneDisplay.Toggle() end)
exports('IsZoneDisplayActive', function() return ZoneDisplay.active end)
exports('UpdateZoneColors', function(colors) ZoneDisplay.UpdateColors(colors) end)

-- Optional: Function to change display colors at runtime
function ZoneDisplay.UpdateColors(colors)
    if type(colors) == "table" then
        if colors.fill then Config.Colors.fill = colors.fill end
        if colors.zone then Config.Colors.zone = colors.zone end
    end
end

--[[
    Available Commands:
    /zones - List all zones
    /deletezone [id|name] - Delete a zone
    /renamezone [id|name] [new_name] - Rename a zone
    /editzone [id|name] - Edit an existing zone
    /togglezones - Toggle zone display (or press O)
]]