-- Draw zone markers and connections
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

-- Draw zone area visualization
local function DrawZoneArea()
    local baseZ = currentPoints[1].z
    for i = 2, #currentPoints do
        baseZ = math.min(baseZ, currentPoints[i].z)
    end
    
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

-- Draw placement guide
local function DrawPlacementGuide(hitCoords, groundCoords)
    DrawLine(
        groundCoords.x, groundCoords.y, groundCoords.z,
        groundCoords.x, groundCoords.y, groundCoords.z + Config.Placement.guideHeight,
        Config.Colors.guide.r, Config.Colors.guide.g, Config.Colors.guide.b, Config.Colors.guide.a
    )
    
    -- Draw ground marker
    DrawMarker(25,
        groundCoords.x, groundCoords.y, groundCoords.z + 0.02,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        2.0, 2.0, 2.0,
        Config.Colors.guide.r, Config.Colors.guide.g, Config.Colors.guide.b, Config.Colors.guide.a,
        false, false, 2, false, nil, nil, false
    )
end