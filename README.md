# FourTwenty Zone Management System

A comprehensive zone management system for FiveM servers that allows for creating, managing, and interacting with 3D zones in-game. Created by the FourTwenty Development Team.

[Join our Discord](https://discord.gg/fourtwenty) for support and updates!

## Features

- **In-Game Zone Editor**
  - Visual zone creation with real-time preview
  - NoClip mode for easy positioning
  - Area and perimeter calculations
  - Height adjustments
  - Multiple points support

- **Zone Management**
  - Persistent zone storage
  - Automatic backups
  - Server synchronization
  - Zone validation
  - Performance optimized with caching

- **Advanced Zone Features**
  - Point-in-zone checking
  - Entity detection within zones
  - Nearest zone calculations
  - Zone radius searching
  - Player tracking in zones

## Installation

1. Create a new folder called `fourtwenty_zones` in your FiveM resources directory
2. Copy all files into the folder
3. Add `ensure fourtwenty_zones` to your server.cfg
4. Start/restart your server

## Usage 

### In-Game Commands

- `/createzone` - Start the zone creation process
  - Left Click: Place point
  - Backspace: Remove last point
  - E: Save zone (requires at least 3 points)
  - ESC: Cancel creation
  - Mouse Wheel: Adjust NoClip speed
  - LSHIFT/LCTRL: Fast/Slow NoClip movement

### Server Commands

- `/reloadzones` - Reload zones from storage (Admin only)
- `/exportzones` - Export current zones to a file (Admin only)

### Exports (Client)

```lua
-- Zone Checks
exports.fourtwenty_zones:IsPointInZone(point, zone)
exports.fourtwenty_zones:IsPlayerInAnyZone(playerId)

-- Zone Retrieval
exports.fourtwenty_zones:GetZones()
exports.fourtwenty_zones:GetZoneById(zoneId)
exports.fourtwenty_zones:GetZonesByName(name)
exports.fourtwenty_zones:GetNearestZone(point)
exports.fourtwenty_zones:GetZonesInRadius(point, radius)

-- Entity Functions
exports.fourtwenty_zones:GetEntitiesInZone(zoneId, entityType) -- entityType: 'peds', 'vehicles', 'objects'
exports.fourtwenty_zones:GetPlayersInZone(zoneId)

-- Zone Management
exports.fourtwenty_zones:SaveZone(points, name)
exports.fourtwenty_zones:DeleteZone(zoneId)
exports.fourtwenty_zones:UpdateZone(zoneId, zone)
exports.fourtwenty_zones:ClearZones()
exports.fourtwenty_zones:GetZoneCount()
```

### Exports (Server)

```lua
exports.fourtwenty_zones:GetZones()
exports.fourtwenty_zones:GetZoneById(id)
exports.fourtwenty_zones:SaveZones(zones)
exports.fourtwenty_zones:ReloadZones()
```

### Example Usage

```lua
-- Check if a player is in any zone
local isInZone, zoneId, zoneName = exports.fourtwenty_zones:IsPlayerInAnyZone(PlayerId())
if isInZone then
    print(('Player is in zone %s (%s)'):format(zoneId, zoneName))
end

-- Get all vehicles in a zone
local vehicles = exports.fourtwenty_zones:GetEntitiesInZone(zoneId, 'vehicles')
for _, vehicle in ipairs(vehicles) do
    -- Do something with vehicle
end

-- Find nearest zone to player
local ped = PlayerPedId()
local pos = GetEntityCoords(ped)
local nearestId, nearestZone, distance = exports.fourtwenty_zones:GetNearestZone(pos)
```

## Data Structure

### Zone Object
```lua
{
    points = { -- Array of vector3 points
        {x = 0, y = 0, z = 0},
        -- more points...
    },
    baseZ = 0.0, -- Lowest Z coordinate
    height = 20.0, -- Zone height
    name = "Zone_1", -- Zone identifier
    bounds = { -- Bounding box for quick checks
        minX = 0.0,
        minY = 0.0,
        maxX = 0.0,
        maxY = 0.0
    }
}
```

## File Structure

```
fourtwenty_zones/
├── client/
│   ├── editor.lua      # Zone editor functionality
│   ├── manager.lua     # Zone management system
│   └── visualization.lua # Zone visualization
├── server/
│   └── main.lua        # Server-side functionality
├── shared/
│   └── config.lua      # Shared configuration
├── html/
│   ├── index.html      # Editor UI
│   ├── style.css       # UI styling
│   └── script.js       # UI functionality
├── backups/            # Zone backups
├── exports/            # Zone exports
├── fxmanifest.lua      # Resource manifest
└── zones.json          # Zone storage
```

## Configuration

Edit `shared/config.lua` to customize:
- Colors for visualization
- Marker properties
- Zone properties
- Placement settings
- NoClip speeds
- Cache timeout

## Performance

- Uses bounding box checks for quick point-in-zone testing
- Implements caching for player position checks
- Optimized polygon intersection algorithm
- Periodic cache cleanup

## Requirements

- FiveM Server Build 5848 or newer
- OneSync enabled

## Support

Need help? Join our Discord server at [discord.gg/fourtwenty](https://discord.gg/fourtwenty)!

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Credits

Created by the FourTwenty Development Team. For more resources, visit our [Discord](https://discord.gg/fourtwenty).
