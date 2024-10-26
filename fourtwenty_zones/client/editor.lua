local isEditing = false
local currentPoints = {}
local tempPoint = nil
local noclipActive = false

-- Helper function to convert rotation to direction vector
local function RotationToDirection(rotation)
    local z = math.rad(rotation.z)
    local x = math.rad(rotation.x)
    local num = math.abs(math.cos(x))
    return vector3(
        -math.sin(z) * num,
        math.cos(z) * num,
        math.sin(x)
    )
end

-- Get coordinates where player is looking
local function GetCrosshairCoords()
    local camRot = GetGameplayCamRot(2)
    local camPos = GetGameplayCamCoord()
    local forward = RotationToDirection(camRot)
    local endCoords = camPos + forward * Config.Placement.rayLength
    
    -- First ray for distance
    local ray = StartExpensiveSynchronousShapeTestLosProbe(
        camPos.x, camPos.y, camPos.z,
        endCoords.x, endCoords.y, endCoords.z,
        1 + 16, PlayerPedId(), 7
    )
    local _, hit, hitCoords, _, _ = GetShapeTestResult(ray)
    
    if hit then
        -- Second ray down for ground position
        local groundRay = StartExpensiveSynchronousShapeTestLosProbe(
            hitCoords.x, hitCoords.y, hitCoords.z + 100.0,
            hitCoords.x, hitCoords.y, hitCoords.z - 200.0,
            1, PlayerPedId(), 7
        )
        local _, groundHit, groundCoords = GetShapeTestResult(groundRay)
        
        if groundHit then
            return true, groundCoords, hitCoords
        end
    end
    
    return false, vector3(0,0,0), vector3(0,0,0)
end

-- NoClip functionality
local function ToggleNoclip()
    noclipActive = not noclipActive
    local ped = PlayerPedId()
    
    SetEntityInvincible(ped, noclipActive)
    SetEntityVisible(ped, not noclipActive, false)
    FreezeEntityPosition(ped, noclipActive)
    SetEntityCollision(ped, not noclipActive, not noclipActive)
    
    SendNUIMessage({
        type = "updateNoclip",
        active = noclipActive,
        speed = Config.Noclip.speeds[Config.Noclip.currentSpeedIndex].name
    })
end

-- Handle noclip movement
local function HandleNoclipMovement()
    if not noclipActive then return end
    
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local baseSpeed = Config.Noclip.speeds[Config.Noclip.currentSpeedIndex].speed
    
    -- Speed modifiers
    local speedMultiplier = 1.0
    if IsControlPressed(0, 21) then -- LSHIFT
        speedMultiplier = 2.0
    elseif IsControlPressed(0, 36) then -- LCTRL
        speedMultiplier = 0.5
    end
    
    -- Get camera rotation and movement vectors
    local cameraRot = GetGameplayCamRot(2)
    local forward = RotationToDirection(cameraRot)
    local right = vector3(
        math.cos(math.rad(cameraRot.z)),
        math.sin(math.rad(cameraRot.z)),
        0.0
    )
    
    -- Calculate new position based on input
    local newPos = pos
    
    -- Forward/Backward
    if IsControlPressed(0, 32) then -- W
        newPos = newPos + forward * baseSpeed * speedMultiplier
    elseif IsControlPressed(0, 33) then -- S
        newPos = newPos - forward * baseSpeed * speedMultiplier
    end
    
    -- Left/Right
    if IsControlPressed(0, 34) then -- A
        newPos = newPos - right * baseSpeed * speedMultiplier
    elseif IsControlPressed(0, 35) then -- D
        newPos = newPos + right * baseSpeed * speedMultiplier
    end
    
    -- Up/Down
    if IsControlPressed(0, 22) then -- SPACE
        newPos = newPos + vector3(0, 0, baseSpeed * speedMultiplier)
    elseif IsControlPressed(0, 73) then -- X
        newPos = newPos - vector3(0, 0, baseSpeed * speedMultiplier)
    end
    
    -- Handle speed changes
    if IsControlJustPressed(0, 15) then -- Scroll Up
        Config.Noclip.currentSpeedIndex = math.min(#Config.Noclip.speeds, Config.Noclip.currentSpeedIndex + 1)
        SendNUIMessage({
            type = "updateNoclip",
            active = noclipActive,
            speed = Config.Noclip.speeds[Config.Noclip.currentSpeedIndex].name
        })
    elseif IsControlJustPressed(0, 14) then -- Scroll Down
        Config.Noclip.currentSpeedIndex = math.max(1, Config.Noclip.currentSpeedIndex - 1)
        SendNUIMessage({
            type = "updateNoclip",
            active = noclipActive,
            speed = Config.Noclip.speeds[Config.Noclip.currentSpeedIndex].name
        })
    end
    
    -- Update entity position and rotation
    SetEntityCoordsNoOffset(ped, newPos.x, newPos.y, newPos.z, true, true, true)
    SetEntityRotation(ped, 0.0, 0.0, cameraRot.z, 2, true)
end

-- Draw placement guide
local function DrawPlacementGuide(hitCoords, groundCoords)
    DrawLine(
        groundCoords.x, groundCoords.y, groundCoords.z,
        groundCoords.x, groundCoords.y, groundCoords.z + Config.Placement.guideHeight,
        Config.Colors.guide.r, Config.Colors.guide.g, Config.Colors.guide.b, Config.Colors.guide.a
    )
    
    DrawMarker(25,
        groundCoords.x, groundCoords.y, groundCoords.z + 0.02,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        2.0, 2.0, 2.0,
        Config.Colors.guide.r, Config.Colors.guide.g, Config.Colors.guide.b, Config.Colors.guide.a,
        false, false, 2, false, nil, nil, false
    )
    
    -- Draw cross for better orientation
    local crossSize = 1.0
    DrawLine(
        groundCoords.x - crossSize, groundCoords.y, groundCoords.z + 0.01,
        groundCoords.x + crossSize, groundCoords.y, groundCoords.z + 0.01,
        Config.Colors.guide.r, Config.Colors.guide.g, Config.Colors.guide.b, Config.Colors.guide.a
    )
    DrawLine(
        groundCoords.x, groundCoords.y - crossSize, groundCoords.z + 0.01,
        groundCoords.x, groundCoords.y + crossSize, groundCoords.z + 0.01,
        Config.Colors.guide.r, Config.Colors.guide.g, Config.Colors.guide.b, Config.Colors.guide.a
    )
end

-- Draw zone preview
local function DrawZoneArea()
    if #currentPoints < 3 then return end
    
    -- Find lowest point as base
    local baseZ = currentPoints[1].z
    for i = 2, #currentPoints do
        if currentPoints[i].z < baseZ then
            baseZ = currentPoints[i].z
        end
    end
    
    -- Draw zone fill lines
    for height = 0, Config.Zone.height, Config.Zone.fillSpacing do
        for i = 1, #currentPoints do
            local current = currentPoints[i]
            local next = currentPoints[i + 1] or currentPoints[1]
            
            for j = 0, 1, 0.1 do
                local x1 = current.x + (next.x - current.x) * j
                local y1 = current.y + (next.y - current.y) * j
                local x2 = current.x + (next.x - current.x) * (j + 0.05)
                local y2 = current.y + (next.y - current.y) * (j + 0.05)
                
                DrawLine(
                    x1, y1, baseZ + height,
                    x2, y2, baseZ + height,
                    Config.Colors.fill.r, Config.Colors.fill.g, Config.Colors.fill.b, Config.Colors.fill.a
                )
            end
        end
    end
    
    -- Draw zone outline
    for height = 0, Config.Zone.height, Config.Zone.spacing do
        for i = 1, #currentPoints do
            local current = currentPoints[i]
            local next = currentPoints[i + 1] or currentPoints[1]
            
            DrawLine(
                current.x, current.y, baseZ + height,
                next.x, next.y, baseZ + height,
                Config.Colors.zone.r, Config.Colors.zone.g, Config.Colors.zone.b, Config.Colors.zone.a
            )
        end
    end
    
    -- Draw vertical lines at corners
    for i = 1, #currentPoints do
        local current = currentPoints[i]
        DrawLine(
            current.x, current.y, baseZ,
            current.x, current.y, baseZ + Config.Zone.height,
            Config.Colors.zone.r, Config.Colors.zone.g, Config.Colors.zone.b, Config.Colors.zone.a
        )
    end
end

-- Draw zone markers
local function DrawZoneMarkers()
    local gameTime = GetGameTimer() / 1000
    
    -- Draw existing points and lines
    for i, point in ipairs(currentPoints) do
        local heightOffset = 0
        if Config.Markers.bobbing then
            heightOffset = math.sin(gameTime * 2 + i) * 0.3
        end
        
        -- Draw marker
        DrawMarker(1, 
            point.x, point.y, point.z - 1.0 + heightOffset,
            0.0, 0.0, 0.0,
            0.0, gameTime * 100, 0.0,
            Config.Markers.size, Config.Markers.size, Config.Markers.size,
            Config.Colors.marker.r, Config.Colors.marker.g, Config.Colors.marker.b, Config.Colors.marker.a,
            false, true, 2, true, nil, nil, false
        )
        
        -- Draw connections
        if #currentPoints > 1 then
            local nextPoint = currentPoints[i + 1] or currentPoints[1]
            DrawLine(
                point.x, point.y, point.z,
                nextPoint.x, nextPoint.y, nextPoint.z,
                Config.Colors.line.r, Config.Colors.line.g, Config.Colors.line.b, Config.Colors.line.a
            )
        end
    end
    
    -- Draw temporary point
    if tempPoint then
        DrawMarker(1,
            tempPoint.x, tempPoint.y, tempPoint.z - 1.0,
            0.0, 0.0, 0.0,
            0.0, gameTime * 100, 0.0,
            Config.Markers.size, Config.Markers.size, Config.Markers.size,
            Config.Colors.temp.r, Config.Colors.temp.g, Config.Colors.temp.b, Config.Colors.temp.a,
            false, true, 2, true, nil, nil, false
        )
        
        -- Draw connection to last point
        if #currentPoints > 0 then
            local lastPoint = currentPoints[#currentPoints]
            DrawLine(
                lastPoint.x, lastPoint.y, lastPoint.z,
                tempPoint.x, tempPoint.y, tempPoint.z,
                Config.Colors.temp.r, Config.Colors.temp.g, Config.Colors.temp.b, Config.Colors.temp.a
            )
        end
    end
    
    -- Draw zone preview if enough points
    if #currentPoints >= 3 then
        DrawZoneArea()
    end
end

-- Calculate zone information
local function CalculateZoneInfo()
    if #currentPoints < 3 then return 0, 0 end
    
    -- Calculate area using Shoelace formula
    local area = 0
    for i = 1, #currentPoints do
        local j = (i % #currentPoints) + 1
        area = area + (currentPoints[i].x * currentPoints[j].y) - (currentPoints[j].x * currentPoints[i].y)
    end
    area = math.abs(area) / 2
    
    -- Calculate perimeter
    local perimeter = 0
    for i = 1, #currentPoints do
        local next = currentPoints[i + 1] or currentPoints[1]
        local dx = next.x - currentPoints[i].x
        local dy = next.y - currentPoints[i].y
        perimeter = perimeter + math.sqrt(dx * dx + dy * dy)
    end
    
    return math.floor(area), math.floor(perimeter)
end

-- Start the zone editor
-- Start the zone editor
RegisterCommand('createzone', function()
    if isEditing then return end
    
    isEditing = true
    currentPoints = {}
    
    if not noclipActive then
        ToggleNoclip()
    end
    
    SendNUIMessage({
        type = "showUI",
        data = {
            points = 0,
            area = 0,
            perimeter = 0
        }
    })
    
    Citizen.CreateThread(function()
        while isEditing do
            Citizen.Wait(0)
            HandleNoclipMovement()
            
            local hit, groundCoords, hitCoords = GetCrosshairCoords()
            if hit then
                tempPoint = groundCoords
                DrawPlacementGuide(hitCoords, groundCoords)
                
                -- Place point
                if IsControlJustPressed(0, 24) then -- Left Click
                    table.insert(currentPoints, groundCoords)
                    PlaySoundFrontend(-1, "PICK_UP", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                    
                    local area, perimeter = CalculateZoneInfo()
                    SendNUIMessage({
                        type = "updateZoneInfo",
                        data = {
                            points = #currentPoints,
                            area = area,
                            perimeter = perimeter
                        }
                    })
                end
                
                -- Remove point
                if IsControlJustPressed(0, 194) and #currentPoints > 0 then -- Backspace
                    table.remove(currentPoints)
                    PlaySoundFrontend(-1, "CANCEL", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                    
                    local area, perimeter = CalculateZoneInfo()
                    SendNUIMessage({
                        type = "updateZoneInfo",
                        data = {
                            points = #currentPoints,
                            area = area,
                            perimeter = perimeter
                        }
                    })
                end
            end
            
            -- Draw zone preview
            DrawZoneMarkers()
            
            -- Confirm zone creation
            if IsControlJustPressed(0, 38) and #currentPoints >= 3 then -- E
                local zoneName = "Zone_" .. #ZoneManager.zones + 1
                local zoneId, zone = ZoneManager.SaveZone(currentPoints, zoneName)
                TriggerEvent('notify', 'Zone ' .. zoneId .. ' created and saved!')
                
                isEditing = false
                if noclipActive then ToggleNoclip() end
                SendNUIMessage({
                    type = "hideUI"
                })
                return
            end
            
            -- Cancel zone creation
            if IsControlJustPressed(0, 200) then -- ESC
                isEditing = false
                if noclipActive then ToggleNoclip() end
                SendNUIMessage({
                    type = "hideUI"
                })
                return
            end
            
            -- Handle speed adjustments for noclip
            if IsControlJustPressed(0, 15) then -- Mouse Wheel Up
                Config.Noclip.currentSpeedIndex = math.min(#Config.Noclip.speeds, Config.Noclip.currentSpeedIndex + 1)
                SendNUIMessage({
                    type = "updateNoclip",
                    active = true,
                    speed = Config.Noclip.speeds[Config.Noclip.currentSpeedIndex].name
                })
            elseif IsControlJustPressed(0, 14) then -- Mouse Wheel Down
                Config.Noclip.currentSpeedIndex = math.max(1, Config.Noclip.currentSpeedIndex - 1)
                SendNUIMessage({
                    type = "updateNoclip",
                    active = true,
                    speed = Config.Noclip.speeds[Config.Noclip.currentSpeedIndex].name
                })
            end
        end
    end)
end, false)

-- Export zone editing functions
exports('StartZoneEditor', function()
    if not isEditing then
        RegisterCommand('createzone', nil, false)
    end
end)

exports('IsEditing', function()
    return isEditing
end)

exports('GetCurrentPoints', function()
    return currentPoints
end)

-- Clean up when resource stops
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- Disable noclip if active
    if noclipActive then
        local ped = PlayerPedId()
        SetEntityInvincible(ped, false)
        SetEntityVisible(ped, true, false)
        FreezeEntityPosition(ped, false)
        SetEntityCollision(ped, true, true)
    end
    
    -- Hide UI
    SendNUIMessage({
        type = "hideUI"
    })
end)