# CLAUDE.md - Garmin Connect IQ MonkeyC Development Guide

## Project Overview

This document provides guidelines and best practices for developing Garmin Connect IQ applications using MonkeyC. It serves as a reference for AI assistants and developers working on this project.

### MNMLST Watchface Project

This project is a **minimalist analog watchface** for Garmin Connect IQ devices, inspired by the original Pebble MNMLST watchface by MicroByte.

#### Current Project Structure
```
garmin_mnmlst_watchface/
├── manifest.xml                    # App configuration (40+ supported devices)
├── monkey.jungle                   # Build configuration
├── resources/
│   ├── bitmaps.xml                # Bitmap resource definitions
│   ├── settings.xml               # App settings and strings
│   ├── images/                    # Icons and graphics
│   └── resource/                  # Fonts and resources
│       ├── OpenSans-Regular.ttf
│       ├── blackdiamonds-bold.ttf
│       └── fonts/blackdiamond.fnt
└── source/
    ├── MnmlstApp.mc              # Main application class
    ├── MnmlstView.mc             # Watchface view implementation
    └── Colors/
        ├── DarkColors.mc         # Dark theme color definitions
        ├── DefaultColors.mc      # Default color scheme
        └── LightColors.mc        # Light theme colors
```

#### Key Features Implemented
- **Triangular hour hand** - Orange when BT connected, gray when disconnected
- **Thin minute hand** - White line indicating current minute
- **Battery indicator** - Colored dot on scale (green/yellow/red/blue for charging)
- **Date display** - Shows day of month at bottom
- **Move reminder** - Center arbor turns red when movement needed
- **Notification count** - Shows unread notification count
- **Tick marks** - White hour marks, light gray minute marks
- **Sleep mode optimization** - Reduces updates when watch sleeps
- **Buffered rendering** - Uses offscreen buffers for performance

#### Technical Implementation Notes
- Uses `Graphics.createBufferedBitmap()` for performance optimization
- Implements partial updates via `onPartialUpdate()` for battery efficiency
- Custom polygon generation for watch hands with mathematical transformations
- Supports 40+ Garmin device models (Fenix, Epix, Venu, MARQ, Forerunner series)
- Requires permissions: Background, Communications, Sensor, SensorHistory, UserProfile
- Screen shape detection for proper rendering on round/rectangular displays

#### Test Suite
This project includes a comprehensive test suite in the `tests/` directory:
- **Unit tests** for coordinate generation algorithms
- **Integration tests** for watchface rendering
- **Mock objects** for testing without hardware dependencies
- **Test runner** for executing all tests and reporting results

**IMPORTANT: Always run tests before and after making changes**

## MonkeyC Language Basics

MonkeyC is Garmin's proprietary language for Connect IQ development, similar to Java/C with some unique characteristics:

- **Object-oriented** with classes and modules
- **Strongly typed** with optional type annotations
- **Memory-constrained** environment requiring careful resource management
- **Event-driven** architecture for UI and sensor interactions

## Project Structure

```
project-root/
├── manifest.xml           # App configuration and permissions
├── resources/
│   ├── drawables/        # Images and icons
│   ├── fonts/            # Custom fonts
│   ├── layouts/          # XML layout files
│   ├── menus/            # Menu definitions
│   ├── settings/         # Settings and properties
│   └── strings/          # Localization files
├── source/
│   ├── AppNameApp.mc     # Main application class
│   ├── AppNameView.mc    # Main view class
│   ├── AppNameDelegate.mc # Input delegate
│   └── modules/          # Additional modules
└── tests/                # Unit tests

```

### Watchface-Specific Patterns

For watchface applications, the typical structure includes:

```monkey-c
// Main application class extending AppBase
class MnmlstApp extends Application.AppBase {
    function getInitialView() {
        return [new MnmlstView(), new MnmlstDelegate()];
    }
}

// Watchface view extending WatchFace
class MnmlstView extends WatchUi.WatchFace {
    function onUpdate(dc) {
        // Main drawing logic
    }
    
    function onPartialUpdate(dc) {
        // Efficient updates for second hand, etc.
    }
}

// Input delegate for watchface interactions
class MnmlstDelegate extends WatchUi.WatchFaceDelegate {
    function onPowerBudgetExceeded(powerInfo) {
        // Handle power budget issues
    }
}
```

## Code Best Practices

### 1. Memory Management

```monkey-c
// GOOD: Release resources when done
function onHide() {
    myBitmap = null;
    myTimer.stop();
    myTimer = null;
}

// BAD: Keeping unnecessary references
var globalBitmap; // Avoid unless absolutely necessary
```

### 2. Type Annotations

Always use type annotations for better code clarity and error detection:

```monkey-c
// GOOD: Clear type annotations
function calculatePace(distance as Float, time as Number) as Float {
    return distance / time;
}

// Specify return types and parameter types
var speed as Float = 0.0;
var heartRate as Number or Null = null;
```

### 3. Resource Loading

Load resources efficiently:

```monkey-c
// GOOD: Load once and cache
class MyView extends WatchUi.View {
    private var _icon as BitmapResource?;
    
    function initialize() {
        View.initialize();
        _icon = WatchUi.loadResource(Rez.Drawables.Icon);
    }
}

// BAD: Loading in onUpdate
function onUpdate(dc) {
    var icon = WatchUi.loadResource(Rez.Drawables.Icon); // Don't do this
}
```

### 4. Error Handling

```monkey-c
function readSensorData() as Number? {
    try {
        var info = Activity.getActivityInfo();
        if (info != null && info.currentHeartRate != null) {
            return info.currentHeartRate;
        }
    } catch (ex) {
        System.println("Error reading sensor: " + ex.getErrorMessage());
    }
    return null;
}
```

### 5. Constants and Enumerations

```monkey-c
module Constants {
    const UPDATE_INTERVAL = 1000; // milliseconds
    const MAX_RETRIES = 3;
    
    enum State {
        STATE_IDLE = 0,
        STATE_RUNNING = 1,
        STATE_PAUSED = 2
    }
}
```

## UI Development Best Practices

### 1. Custom Drawing

```monkey-c
function onUpdate(dc as Graphics.Dc) as Void {
    // Clear the screen
    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
    dc.clear();
    
    // Use anti-aliasing for text
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    dc.drawText(
        dc.getWidth() / 2,
        dc.getHeight() / 2,
        Graphics.FONT_MEDIUM,
        "Hello World",
        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
    );
}
```

### 2. Layout Management

Use XML layouts for complex UIs:

```xml
<!-- resources/layouts/main_layout.xml -->
<layout id="MainLayout">
    <label x="center" y="30" font="Graphics.FONT_MEDIUM" 
           justification="Graphics.TEXT_JUSTIFY_CENTER" 
           text="@Strings.AppName" />
    <bitmap x="center" y="center" resource="@Drawables.Icon" />
</layout>
```

### 3. Input Handling

```monkey-c
class MyDelegate extends WatchUi.BehaviorDelegate {
    function onSelect() as Boolean {
        // Handle select button
        return true; // Event consumed
    }
    
    function onBack() as Boolean {
        // Handle back button
        if (canGoBack()) {
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
            return true;
        }
        return false; // Let system handle
    }
}
```

## Performance Optimization

### 1. Minimize onUpdate Calls

```monkey-c
class MyView extends WatchUi.View {
    private var _needsFullRedraw as Boolean = true;
    
    function onUpdate(dc as Graphics.Dc) as Void {
        if (_needsFullRedraw) {
            drawFullScreen(dc);
            _needsFullRedraw = false;
        } else {
            drawPartialUpdate(dc);
        }
    }
}
```

### Watchface Performance Patterns

Watchfaces require special attention to performance and battery life:

```monkey-c
// Use buffered bitmaps for complex backgrounds
function onLayout(dc) {
    if (Toybox.Graphics has :createBufferedBitmap) {
        offscreenBuffer = Graphics.createBufferedBitmap({
            :width => dc.getWidth(),
            :height => dc.getHeight(),
            :palette => [Graphics.COLOR_BLACK, Graphics.COLOR_WHITE, /* ... */]
        }).get();
    }
}

// Implement efficient partial updates
function onPartialUpdate(dc) {
    // Only redraw changed elements
    if (partialUpdatesAllowed) {
        drawSecondHand(dc);
    } else {
        // Fall back to full update
        onUpdate(dc);
    }
}

// Handle power budget constraints
function onPowerBudgetExceeded(powerInfo) {
    partialUpdatesAllowed = false;
    System.println("Power budget exceeded - disabling partial updates");
}
```

### 2. Use Appropriate Data Structures

```monkey-c
// For small, fixed-size collections
var array = new [10];

// For dynamic collections
var list = [];

// For key-value pairs
var dict = {};
```

### 3. Timer Management

```monkey-c
class MyApp extends Application.AppBase {
    private var _timer as Timer.Timer?;
    
    function onStart(state) {
        _timer = new Timer.Timer();
        _timer.start(method(:timerCallback), 1000, true);
    }
    
    function onStop(state) {
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
    }
}
```

## Testing Guidelines

### 1. Unit Test Structure

```monkey-c
// tests/MyModuleTest.mc
(:test)
function testCalculation(logger as Logger) as Boolean {
    var result = MyModule.calculate(10, 20);
    logger.debug("Result: " + result);
    return result == 30;
}

(:test)
function testErrorHandling(logger as Logger) as Boolean {
    try {
        MyModule.riskyOperation();
        return false; // Should have thrown
    } catch (ex) {
        return true;
    }
}
```

### 2. Mock Objects

```monkey-c
(:test)
class MockSensor {
    function getHeartRate() as Number {
        return 120; // Predictable test value
    }
}
```

### 3. Integration Testing

Test on multiple device configurations:

```bash
# Run simulator tests
connectiq test --device fenix7

# Test on multiple devices
connectiq test --device fenix7,vivoactive4,forerunner955
```

## Code Formatting Standards

### 1. Naming Conventions

```monkey-c
// Classes: PascalCase
class MyCustomView extends WatchUi.View {}

// Functions: camelCase
function calculateDistance() {}

// Constants: UPPER_SNAKE_CASE
const MAX_SPEED = 100;

// Private members: underscore prefix
private var _internalState;

// Modules: PascalCase
module DataProcessor {}
```

### 2. Indentation and Spacing

- Use 4 spaces for indentation (no tabs)
- Add blank lines between functions
- Keep line length under 100 characters

```monkey-c
class ExampleClass {
    private var _data as Array<Number>;
    
    function initialize() {
        _data = [];
    }
    
    function processData(input as Number) as Void {
        if (input > 0) {
            _data.add(input);
        }
    }
}
```

### 3. Comments

```monkey-c
//! Main application class
//! Handles app lifecycle and initialization
class MyApp extends Application.AppBase {
    
    //! Initialize the application
    //! @param state Previous app state (may be null)
    function onStart(state as Dictionary or Null) as Void {
        // Load user preferences
        var prefs = Application.getApp().getProperty("userPrefs");
        
        /* Multi-line comment for complex logic
           This section handles migration of old settings
           to the new format introduced in v2.0 */
    }
}
```

## Device Compatibility

### 1. Check Capabilities

```monkey-c
function initializeSensors() as Void {
    if (Toybox has :SensorHistory) {
        // Use sensor history
        var history = SensorHistory.getHeartRateHistory({});
    }
    
    if (System.getDeviceSettings().phoneConnected) {
        // Phone-dependent features
    }
}
```

### 2. Screen Size Adaptation

```monkey-c
function getScaledFont(dc as Graphics.Dc) as Graphics.FontType {
    var width = dc.getWidth();
    if (width > 360) {
        return Graphics.FONT_LARGE;
    } else if (width > 240) {
        return Graphics.FONT_MEDIUM;
    } else {
        return Graphics.FONT_SMALL;
    }
}
```

## Manifest Configuration

```xml
<!-- manifest.xml example -->
<iq:manifest xmlns:iq="http://www.garmin.com/xml/connectiq" version="3">
    <iq:application 
        entry="MyApp" 
        id="unique-app-id" 
        launcherIcon="@Drawables.LauncherIcon" 
        name="@Strings.AppName" 
        type="watch-app"
        minApiLevel="3.0.0">
        
        <iq:products>
            <iq:product id="fenix7"/>
            <iq:product id="vivoactive4"/>
        </iq:products>
        
        <iq:permissions>
            <iq:uses-permission id="Positioning"/>
            <iq:uses-permission id="SensorHistory"/>
        </iq:permissions>
    </iq:application>
</iq:manifest>
```

## Build and Deployment

### 1. Debug Build

```bash
# Compile for debugging
monkeyc -d fenix7 -f monkey.jungle -o output.prg -y developer_key

# Run in simulator with debug output
connectiq run --device fenix7
```

### 2. Release Build

```bash
# Compile for release
monkeyc -r -f monkey.jungle -o output.iq -y developer_key

# Validate before submission
connectiq validate output.iq
```

### 3. Common Build Issues

- **Memory overflow**: Reduce resource size, optimize data structures
- **API compatibility**: Check minApiLevel in manifest
- **Missing permissions**: Add required permissions to manifest

## Debugging Tips

1. **Use System.println() liberally during development**
```monkey-c
System.println("Debug: value = " + value);
```

2. **Check for null values**
```monkey-c
if (info != null && info.currentSpeed != null) {
    speed = info.currentSpeed;
}
```

3. **Monitor memory usage**
```monkey-c
System.println("Memory: " + System.getSystemStats().usedMemory);
```

## Common Pitfalls to Avoid

1. **Don't create objects in onUpdate()** - Creates garbage and impacts performance
2. **Don't use floating-point math unnecessarily** - Integer math is faster
3. **Don't ignore device capabilities** - Always check before using features
4. **Don't hardcode screen positions** - Use relative positioning
5. **Don't forget to stop timers** - Memory leaks and battery drain

## Resources and References

- [Connect IQ SDK Documentation](https://developer.garmin.com/connect-iq/api-docs/)
- [MonkeyC Language Reference](https://developer.garmin.com/connect-iq/monkey-c/)
- [Connect IQ Forums](https://forums.garmin.com/developer/connect-iq/)
- [Sample Projects](https://github.com/garmin/connectiq-apps)

## MNMLST Project Specific Notes

### Development Workflow

**CRITICAL: Always run tests when making changes to this project**

#### Task Management with TODO.md

**MANDATORY: Use TODO.md for all work items**

1. **Check TODO.md first** - Before starting any work, always check `TODO.md` for existing tasks
2. **Add new tasks** - If given a new task, add it to the top of `TODO.md` and plan it accordingly
3. **Work sequentially** - Take the first unchecked task from `TODO.md` and follow this process:
   - **Plan** - Break down the task into specific steps
   - **Execute** - Implement the changes
   - **Verify** - Check that implementation meets requirements
   - **Test** - Run the test suite to ensure no regressions
   - **Review** - Validate code quality and adherence to best practices
   - **Mark complete** - Check off the task in `TODO.md` as `[x]`
4. **Wait for consent** - NEVER start the next task without explicit user approval
5. **Mark completion** - Always mark completed tasks as done in `TODO.md`

#### Testing Protocol

Before making any changes:
```bash
# Run the test suite to ensure current functionality works
connectiq test --device fenix7
```

After making changes:
```bash
# Run tests again to verify no regressions
connectiq test --device fenix7

# Test on multiple devices for compatibility
connectiq test --device fenix7,vivoactive4,forerunner955
```

For MonkeyC projects, testing replaces traditional linting/typechecking workflows since the Connect IQ compiler provides comprehensive validation during the test process.

### Key Implementation Details

#### Hand Drawing Algorithm
The watchface uses mathematical transformations to draw watch hands:

```monkey-c
// Generate triangular hour hand coordinates
function generateHourCoordinates(centerPoint, angle, handLength, tailLength, width) {
    var coords = [
        [-(width / 2), -handLength],  // Top left
        [width / 2, -handLength],     // Top right  
        [0, tailLength]               // Bottom center
    ];
    
    // Apply rotation transformation
    var cos = Math.cos(angle);
    var sin = Math.sin(angle);
    
    for (var i = 0; i < 3; i += 1) {
        var x = coords[i][0] * cos - coords[i][1] * sin;
        var y = coords[i][0] * sin + coords[i][1] * cos;
        result[i] = [centerPoint[0] + x, centerPoint[1] + y];
    }
}
```

#### Smart Visual Indicators
- **Bluetooth status**: Hour hand color (orange=connected, gray=disconnected)
- **Battery state**: Colored dots (green=good, yellow=low, red=critical, blue=charging)
- **Move reminder**: Center arbor turns red when ActivityMonitor detects inactivity
- **Notifications**: Count displayed at configurable position

#### Device Adaptation
- **Screen shape detection**: Handles round vs rectangular displays
- **Size scaling**: Adjusts hand proportions based on screen width
- **Font scaling**: Uses device-appropriate font sizes
- **Performance scaling**: Reduces complexity on lower-end devices

### Maintenance Notes
- Color themes defined in separate modules (DarkColors, LightColors, DefaultColors)
- Custom BlackDiamond font used for hour markers
- Extensive device compatibility (40+ models supported)
- Buffered rendering optimized for each device's capabilities

### Testing Commands for This Project

```bash
# Basic test run (recommended for most changes)
connectiq test --device fenix7

# Multi-device compatibility testing
connectiq test --device fenix7,vivoactive4,forerunner955,epix2

# Run specific test file
connectiq test --device fenix7 --test tests/CoordinateTest.mc

# Build and validate without running tests
connectiq build --device fenix7
connectiq validate output.iq
```

**Note**: The Connect IQ SDK's test framework provides the equivalent of linting and type checking for MonkeyC code. Always ensure tests pass before committing changes.

## Version History

- **1.0.0** - Initial guidelines
- **1.1.0** - Added testing section and performance tips
- **1.2.0** - Updated for Connect IQ 4.x compatibility
- **1.3.0** - Added MNMLST project analysis and watchface-specific patterns
- **1.4.0** - Added comprehensive test suite and mandatory testing workflow
- **1.5.0** - Added mandatory TODO.md task management workflow

---

*This document should be updated as the project evolves and new best practices are discovered.*