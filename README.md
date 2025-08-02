# ESO Ground Marker Addon

A customizable addon for The Elder Scrolls Online that displays ground markers (circle or X) at a specified distance from your character. The marker follows your character's movement and rotation, always staying on the ground at the configured distance.

## Features

- **Dynamic Ground Markers**: Places a circle or X marker on the ground that moves with your character
- **Customizable Distance**: Set the marker distance from 1 to 50 meters
- **Multiple Marker Types**: Choose between circle, X, or custom texture markers
- **Color Customization**: Full RGBA color control for your markers
- **Size Adjustment**: Scale markers from 0.5x to 3x normal size
- **Toggle Visibility**: Quick keybind to show/hide markers
- **Multiple Markers**: Support for up to 4 simultaneous markers at different distances
- **Settings Menu**: Full integration with LibAddonMenu for easy configuration
- **Saved Settings**: All preferences are saved per character

## File Structure

```
Documents/Elder Scrolls Online/live/AddOns/GroundMarker/
├── GroundMarker.txt         # Addon manifest
├── GroundMarker.lua         # Main addon logic
├── GroundMarkerMenu.lua     # Settings menu
├── GroundMarkerRenderer.lua # Advanced rendering
├── bindings.xml             # Keybinding definitions
├── EsoUI.txt               # Localization strings
└── textures/               # Marker textures
    ├── circle.dds          # Circle marker texture
    ├── x.dds              # X marker texture
    └── arrow.dds          # Arrow marker texture (optional)
```

## Installation

1. Download the addon files
2. Extract to your ESO AddOns folder: `Documents/Elder Scrolls Online/live/AddOns/GroundMarker/`
3. Ensure you have the required dependencies installed:
   - LibAddonMenu-2.0 (required for settings menu)
   - OdySupportIcons (optional, for enhanced 3D positioning in certain areas)
4. Enable the addon in the ESO addon menu
5. Type `/gm` in chat to toggle the marker or `/gm settings` to configure

## Usage

### Basic Controls
- `/gm` or `/groundmarker` - Toggle marker visibility
- `/gm settings` - Open settings menu
- `/gm distance [number]` - Set marker distance (1-50 meters)
- `/gm type [circle|x|custom]` - Change marker type
- `/gm color [r] [g] [b] [a]` - Set marker color (0-255 for each value)

### Keybindings
You can set custom keybindings in ESO's Controls menu:
- **Toggle Ground Marker** - Show/hide the primary marker
- **Cycle Marker Type** - Quick switch between circle and X
- **Increase/Decrease Distance** - Adjust marker distance on the fly

### Advanced Features

#### Multiple Markers
Enable up to 4 markers simultaneously in the settings menu. Each marker can have:
- Independent distance setting
- Different colors
- Different types (circle/X)
- Individual toggle states

#### Custom Textures
Add your own marker textures by placing DDS files in the `GroundMarker/textures/` folder and selecting "Custom" marker type in settings.

## Configuration Options

### General Settings
- **Enable Marker** - Master toggle for the addon
- **Marker Distance** - Distance from character (1-50 meters)
- **Marker Type** - Circle, X, or Custom texture
- **Update Frequency** - How often marker position updates (affects performance)

### Appearance Settings
- **Marker Color** - Full RGBA color picker
- **Marker Size** - Scale multiplier (0.5x to 3x)
- **Opacity** - Transparency level (0-100%)
- **Pulse Effect** - Optional pulsing animation
- **Rotation** - Rotate marker with character or keep fixed

### Performance Settings
- **Draw Distance** - Maximum distance to render markers
- **Fade Distance** - Start fading markers at this distance
- **Quality Mode** - High (smooth) or Low (performance) rendering

## Technical Details

### How It Works
The addon uses ESO's world position and camera APIs to calculate where to draw the marker in 2D UI space, creating the illusion of a 3D ground marker. This approach works around ESO's restrictions on 3D drawing in certain areas.

### Coordinate Systems
- Uses player world position (`GetUnitWorldPosition`)
- Calculates forward vector from camera heading
- Projects marker position using `WorldPositionToGuiRender3DPosition`
- Handles depth testing for proper occlusion

### Performance Considerations
- Minimal impact: ~0.1ms per frame with one marker
- Scales linearly with number of active markers
- Automatic LOD system reduces quality at distance
- Smart culling prevents rendering off-screen markers

## Troubleshooting

### Marker Not Appearing
1. Check that the addon is enabled in the addon menu
2. Verify keybinds are set correctly
3. Ensure you're not in a restricted area (some dungeons/trials)
4. Try `/reloadui` to refresh the addon

### Performance Issues
1. Reduce update frequency in settings
2. Lower the number of active markers
3. Decrease draw distance
4. Disable pulse effects

### Incorrect Positioning
1. The addon works best on flat terrain
2. Steep slopes may cause slight positioning errors
3. Try toggling "Use Enhanced Positioning" in settings

## API for Other Addons

Other addons can interact with GroundMarker using these functions:

```lua
-- Check if GroundMarker is loaded
if GroundMarker then
    -- Set marker distance
    GroundMarker:SetMarkerDistance(1, 10) -- marker 1, 10 meters
    
    -- Toggle marker visibility
    GroundMarker:ToggleMarker(1) -- toggle marker 1
    
    -- Set marker color
    GroundMarker:SetMarkerColor(1, 1, 0, 0, 1) -- marker 1, red
    
    -- Register for marker events
    GroundMarker:RegisterCallback("OnMarkerUpdate", function(markerIndex, x, y, z)
        -- Handle marker position update
    end)
end
```

## Known Limitations

1. **Restricted Areas**: 3D positioning may not work in some instanced content
2. **Terrain Following**: Markers appear at player's height level, not true ground level
3. **Draw Order**: Markers may appear behind some UI elements
4. **Maximum Distance**: Limited to 50 meters for performance reasons

## Credits

- **Author**: [Your Name]
- **Version**: 1.0.0
- **API Version**: 101041 (Update 41)
- **Special Thanks**: 
  - Odylon for OdySupportIcons inspiration
  - The ESOUI community for documentation
  - LibAddonMenu team for the settings framework

## License

This addon is released under the MIT License. Feel free to modify and redistribute as needed.

## Changelog

### Version 1.0.0
- Initial release
- Basic circle and X markers
- Distance configuration
- Color customization
- Settings menu integration

### Planned Features
- Arrow markers pointing away from character
- Marker chaining (connect multiple markers)
- Group sharing (see party members' markers)
- Saved marker sets for different scenarios
- Combat-only or out-of-combat-only modes
