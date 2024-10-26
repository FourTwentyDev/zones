Config = {}

Config.Colors = {
    marker = {r = 0, g = 255, b = 0, a = 255},      -- Green for points
    line = {r = 255, g = 100, b = 0, a = 255},      -- Orange for lines
    temp = {r = 255, g = 0, b = 0, a = 255},        -- Red for temporary markers
    zone = {r = 0, g = 150, b = 255, a = 150},      -- Light blue for preview
    guide = {r = 255, g = 255, b = 255, a = 200},   -- White for guide lines
    fill = {r = 0, g = 150, b = 255, a = 50}        -- Transparent blue for zone fill
}

Config.Markers = {
    size = 1.5,           -- Size of markers
    bobbing = true,       -- Up and down movement
    rotating = true       -- Rotation for better visibility
}

Config.Zone = {
    height = 20,          -- Height of zone visualization
    spacing = 2,          -- Space between height lines
    gridSize = 5,         -- Space between grid lines
    fillSpacing = 0.5     -- Space between fill lines
}

Config.Placement = {
    rayLength = 1000.0,    -- Length of placement ray
    guideHeight = 30.0,    -- Height of guide line
    snapToGround = true    -- Whether markers should snap to ground
}

Config.Noclip = {
    speeds = {
        { speed = 0.1, name = "Very Slow" },
        { speed = 0.5, name = "Slow" },
        { speed = 1.0, name = "Normal" },
        { speed = 2.0, name = "Fast" },
        { speed = 5.0, name = "Very Fast" }
    },
    currentSpeedIndex = 3  -- Starts with "Normal" speed
}

Config.Cache = {
    timeout = 500  -- Cache timeout in ms
}