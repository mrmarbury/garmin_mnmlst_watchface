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
- **1.6.0** - Added responsive UI system implementation details and learnings
- **1.7.0** - Added comprehensive configuration system and simulator testing solutions

## Responsive UI System Implementation

### Phase 1: Responsive Layout Foundation (COMPLETED)

Successfully implemented a comprehensive responsive scaling system to ensure consistent UI appearance across all 63+ supported Garmin devices with screen sizes ranging from 218x218 to 416x416 pixels.

#### Key Components Implemented

**1. Screen Density Calculator**
```monkey-c
// Reference resolution: 260x260 (common mid-range device size)
function calculateScaleFactor(width, height) {
  var referenceSize = 260.0;
  var avgDimension = (width + height) / 2.0;
  return avgDimension / referenceSize;
}
```

**2. Layout Configuration System**
```monkey-c
function createLayoutConfig(width, height) {
  scaleFactor = calculateScaleFactor(width, height);
  
  return {
    // Hour hand configuration
    :hourHandWidth => (160 * scaleFactor).toNumber(),
    :hourHandLength => (151.6 * scaleFactor).toNumber(), // Replaces width/1.714
    
    // Hash marks configuration
    :hourHashLength => (15 * scaleFactor).toNumber(),
    :minuteHashLength => (5 * scaleFactor).toNumber(),
    
    // Battery gauge configuration
    :batteryRadius => (5 * scaleFactor).toNumber(),
    :batteryOffset => (5 * scaleFactor).toNumber(),
    
    // Notification positioning multiplier
    :msgCountMultiplier => (4.6 * scaleFactor)
  };
}
```

**3. Hardcoded Values Replaced**
All hardcoded pixel values replaced with proportional calculations:
- `width / 1.714` → `151.6 * scaleFactor` (hour hand positioning)
- `160` → `160 * scaleFactor` (hour hand width)
- `15`, `5` → scaled hash mark lengths
- `4.6` → `4.6 * scaleFactor` (notification positioning multiplier)
- `5` → scaled battery gauge radius and offset

#### Build and Test Process

**SDK Path Configuration**
```bash
export PATH="/Users/bsu/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-8.2.3-2025-08-11-cac5b3b21/bin:$PATH"
```

**Build Commands**
```bash
# Standard build
monkeyc -d fenix7 -f monkey.jungle -o bin/mnmlst.prg -y "/Users/bsu/Library/Mobile Documents/com~apple~CloudDocs/developer_key"

# Multi-device testing
connectiq test --device fenix7,vivoactive4,venu2

# Build verification across screen sizes
monkeyc -d vivoactive3 -f monkey.jungle -o bin/mnmlst_va3.prg -y "path/to/developer_key"    # 240x240
monkeyc -d epix2pro51mm -f monkey.jungle -o bin/mnmlst_epix.prg -y "path/to/developer_key"  # 416x416
monkeyc -d fenix5s -f monkey.jungle -o bin/mnmlst_f5s.prg -y "path/to/developer_key"        # 218x218
```

#### Verification Results
- ✅ **Build Success**: All 63+ supported devices compile successfully
- ✅ **Unit Tests**: All existing tests continue to pass
- ✅ **Cross-Device Compatibility**: Verified builds for small (218x218), medium (240x240, 260x260), and large (416x416) screens
- ✅ **Responsive Scaling**: UI elements now scale proportionally across all screen sizes

#### Key Learnings

1. **MonkeyC Dictionary Access**: Use `dictionary[:key]` syntax for accessing layout configuration values
2. **Type Conversion**: Always use `.toNumber()` when converting scaled Float values to Number type for pixel coordinates
3. **Global Variable Management**: Responsive values should be calculated once in `onLayout()` and stored for use throughout rendering
4. **Reference Resolution Strategy**: Using 260x260 as reference provides good scaling for the full range of supported devices
5. **Build System**: Connect IQ requires developer key for all builds, even for testing compilation

#### Next Steps Ready for Implementation
Phase 2 tasks now ready with responsive foundation in place:
- Hour hand triangle scaling optimization
- Battery gauge responsive positioning
- Notification positioning system refinement
- Hash mark adaptive sizing verification

## Garmin Connect IQ Configuration System Implementation

### Overview (COMPLETED)

Successfully implemented a comprehensive user configuration system allowing watchface customization through Garmin Connect IQ settings. The system supports 8 configurable properties with organized settings groups and robust error handling.

### Configuration Architecture

**Property Definition Structure**
```xml
<!-- resources/properties/properties.xml -->
<property id="hourHandBehavior" type="number">0</property>
<property id="batteryDisplayMode" type="number">0</property>
<property id="messageFieldType" type="number">0</property>
<property id="dateFieldType" type="number">0</property>
<property id="colorScheme" type="number">0</property>
<property id="calorieGoalOverall" type="number">2400</property>
<property id="stepGoal" type="number">10000</property>
<property id="activeMinutesGoal" type="number">30</property>
```

**Settings UI Structure**
```xml
<!-- resources/settings/settings.xml -->
<group id="@Strings.handBehaviorGroup" title="@Strings.handBehaviorGroup">
    <setting propertyKey="@Properties.hourHandBehavior" title="@Strings.hourHandBehaviorTitle">
        <settingConfig type="list">
            <listEntry value="0">@Strings.hourHandSmooth</listEntry>
            <listEntry value="1">@Strings.hourHandHourly</listEntry>
        </settingConfig>
    </setting>
</group>
```

### Key Features Implemented

**1. Hour Hand Behavior Configuration**
- **Smooth Movement** (0): Continuous hour hand movement including minutes
- **Discrete Hourly** (1): Hour hand jumps discretely on hour changes
```monkeyc
if (configHourHandBehavior == 1) {
    hourHandAngle = (clockTime.hour % 12) * 60; // Ignore minutes
} else {
    hourHandAngle = (clockTime.hour % 12) * 60 + clockTime.min; // Include minutes
}
```

**2. Battery Display Modes (Redesigned)**
- **Battery Level** (0): Multi-colored gauge showing battery percentage
- **Steps Progress** (1): Single green gauge showing daily steps vs goal
- **Weekly Active Minutes** (2): Single green gauge showing weekly active minutes vs goal  
- **Stairs Progress** (3): Single green gauge showing daily floors climbed vs goal

**3. Configurable Data Fields**
- **Top Field Options**: Date, Steps, Heart Rate, Battery %
- **Bottom Field Options**: Notifications, Steps, Heart Rate, Battery %
```monkeyc
function drawNotificationCount(dc, posX, posY) {
    if (configMessageFieldType == 1) {
        // Display step count
        var info = ActivityMonitor.getInfo();
        displayStr = info.steps.toString();
    } else if (configMessageFieldType == 2) {
        // Display heart rate
        var info = Activity.getActivityInfo();
        displayStr = info.currentHeartRate.toString() + " bpm";
    }
    // ... handle other field types
}
```

**4. Goal Configuration**
- Customizable calorie goals (overall: 1000-5000, active: 200-2000)
- Step goal configuration (1000-50000)
- Active minutes goal (10-120)

### Property Loading System

**Robust Error Handling Implementation**
```monkeyc
function loadConfiguration() {
    try {
        // Explicit null checking for each property
        configBatteryDisplayMode = Properties.getValue("batteryDisplayMode");
        if (configBatteryDisplayMode == null) { configBatteryDisplayMode = 0; }
        
        System.println("Config loaded - Battery: " + configBatteryDisplayMode);
    } catch (ex) {
        System.println("Properties failed, using defaults: " + ex.getErrorMessage());
        loadDefaultConfiguration();
    }
    validateConfiguration();
}
```

**Configuration Validation**
```monkeyc
function validateConfiguration() {
    if (configBatteryDisplayMode < 0 || configBatteryDisplayMode > 3) {
        configBatteryDisplayMode = 0;
    }
    // Validate all configuration values within expected ranges
}
```

### Simulator Testing Solutions

**Critical Discovery**: Garmin Connect IQ simulator has known issues with property loading and settings editing that can prevent configuration testing.

**Implemented Solutions**:

1. **Automatic Simulator Detection**
```monkeyc
var deviceSettings = System.getDeviceSettings();
if (deviceSettings.partNumber != null && deviceSettings.partNumber.toString().find("SIMULATOR") != null) {
    System.println("SIMULATOR DETECTED - Using test configuration");
    configBatteryDisplayMode = 1; // Test steps progress
    configHourHandBehavior = 1;   // Test hourly jump
    return;
}
```

2. **Manual Testing Override (Development)**
- Temporary hardcoded test values for simulator
- Immediate visual feedback for configuration changes
- Console debug output for verification

3. **Production Property Loading**
- Robust null checking and exception handling
- Fallback to sensible defaults
- Value validation and range checking

### Common Simulator Issues & Solutions

**Problem**: Settings changes in simulator don't take effect
**Solutions**: 
- Use Eclipse Connect IQ plugin App Settings Editor
- Run simulator directly from command line
- Implement manual test overrides for development
- Reset simulator data and try different environments

**Problem**: Properties.xml defaults not loading
**Root Cause**: Properties XML only provides defaults when properties don't exist
**Solution**: Explicit null checking with fallback values in code

### Battery Bar Redesign Architecture

**Unified Gauge System**
```monkeyc
function drawBatteryGauge(targetDc, width, height) {
    var percentage, useMultiColor;
    
    if (configBatteryDisplayMode == 0) {
        percentage = (System.getSystemStats().battery + 0.5).toNumber();
        useMultiColor = true; // Red/Yellow/Green/Blue colors
    } else if (configBatteryDisplayMode == 1) {
        percentage = getStepsProgress();
        useMultiColor = false; // Single green color
    }
    // ... handle other modes
    
    drawGaugeWithData(targetDc, width, height, percentage, useMultiColor);
}
```

**Activity Data Integration**
```monkeyc
function getWeeklyActiveMinutesProgress() {
    var info = ActivityMonitor.getInfo();
    if (info has :activeMinutesWeek && info.activeMinutesWeek != null && 
        info has :activeMinutesWeekGoal && info.activeMinutesWeekGoal != null) {
        var current = info.activeMinutesWeek.total;
        var goal = info.activeMinutesWeekGoal;
        return goal > 0 ? Math.min((current.toFloat() / goal.toFloat() * 100).toNumber(), 100) : 0;
    }
    return 0;
}
```

### Performance Considerations

**Configuration Loading Optimization**:
- All properties loaded once in `onLayout()` and cached
- Zero configuration overhead during `onUpdate()` rendering
- Validation performed only at configuration load time

**Device Capability Handling**:
- Proper `has` checks for device-specific features (floors climbed)
- Graceful fallback for unsupported features
- Cross-device compatibility maintained

### Testing Results

- ✅ **Build Success**: 100% success across all device types and screen sizes
- ✅ **Simulator Testing**: Manual override system provides immediate feedback
- ✅ **Property Validation**: All configuration values properly validated
- ✅ **Error Handling**: Robust fallbacks prevent crashes from property access failures
- ✅ **Activity Data**: Successfully integrates ActivityMonitor API for fitness metrics

### Key Learnings

1. **Simulator Limitations**: Connect IQ simulator has significant property/settings limitations requiring workarounds
2. **Property Loading Patterns**: Always use explicit null checking rather than ternary operators for MonkeyC properties
3. **Device Compatibility**: Use `has` checks for optional device features like floors climbed
4. **Development Workflow**: Implement manual test overrides for reliable simulator testing
5. **Activity Data Access**: ActivityMonitor and Activity APIs require careful null checking and capability detection

### Configuration Options Available to Users

**Hand Behavior**: Smooth continuous movement vs discrete hourly jumps
**Battery Display**: Battery level, daily steps progress, weekly active minutes, floors climbed progress  
**Data Fields**: Customizable top/bottom fields showing date, notifications, steps, heart rate, or battery percentage
**Goals**: Configurable calorie, step, and activity minute targets
**Color Scheme**: Dark theme foundation with white theme support ready

## UI Element Visibility System Implementation (COMPLETED - v2.0.0)

### Overview
Successfully implemented comprehensive individual visibility controls allowing users to hide/show any of the 4 main UI elements: top field, middle gauge, bottom field, and minute hand including arbor.

### Implementation Architecture

**Property Configuration System**
```xml
<!-- resources/properties/properties.xml -->
<property id="showTopField" type="number">1</property>      <!-- 1=show, 0=hide -->
<property id="showMiddleGauge" type="number">1</property>    <!-- 1=show, 0=hide -->
<property id="showBottomField" type="number">1</property>    <!-- 1=show, 0=hide -->
<property id="showMinuteHand" type="number">1</property>     <!-- 1=show, 0=hide -->
```

**Settings UI Implementation**
```xml
<!-- resources/settings/settings.xml -->
<group id="@Strings.visibilityGroup" title="@Strings.visibilityGroup">
    <setting propertyKey="@Properties.showTopField" title="@Strings.showTopFieldTitle">
        <settingConfig type="list">
            <listEntry value="1">@Strings.optionShow</listEntry>
            <listEntry value="0">@Strings.optionHide</listEntry>
        </settingConfig>
    </setting>
    <!-- Additional visibility settings... -->
</group>
```

**Conditional Rendering Logic**
```monkeyc
// Top field (date/custom data) visibility
if (showTopField == 1) {
    if (null != dateBuffer) {
        dc.drawBitmap(0, height * layoutConfig[:dateOffsetRatio], dateBuffer);
    } else {
        drawDateString(dc, width / 2, height * layoutConfig[:dateOffsetRatio]);
    }
}

// Middle gauge visibility
if (showMiddleGauge == 1) {
    drawBattery(targetDc, width, height);
}

// Bottom field visibility
if (showBottomField == 1) {
    drawNotificationCount(dc, width / 2, height * layoutConfig[:notificationOffsetRatio]);
}

// Minute hand and arbor visibility
if (showMinuteHand == 1) {
    // Draw minute hand polygon
    targetDc.fillPolygon(generateHandCoordinates(...));
    drawArbor(targetDc);  // Arbor only shown when minute hand is visible
}
```

### Key Technical Solutions

**Numeric Boolean Values**: Used numeric values (1/0) instead of boolean types for Garmin Connect IQ compatibility with settings lists.

**Configuration Validation**:
```monkeyc
// Visibility properties validation (1=show, 0=hide)
if (showTopField < 0 || showTopField > 1) { showTopField = 1; }
if (showMiddleGauge < 0 || showMiddleGauge > 1) { showMiddleGauge = 1; }
if (showBottomField < 0 || showBottomField > 1) { showBottomField = 1; }
if (showMinuteHand < 0 || showMinuteHand > 1) { showMinuteHand = 1; }
```

**String Resources**: Added comprehensive localization support for all new UI elements with clear, descriptive labels.

### Build Challenges & Solutions

**Problem**: Initial boolean settings configuration caused build error "List entries are only valid for setting type 'list'"
**Solution**: Changed from `type="boolean"` to `type="list"` with numeric values (1/0)

**Problem**: String parsing error "For input string: 'true'" when using string boolean values  
**Solution**: Switched to numeric values (1=show, 0=hide) throughout the entire codebase

### Version Release Process

**v2.0.0 Release**: First major version incorporating all visibility features
- Universal build process using `monkeyc -r -e` for Connect IQ Store compatibility
- Successfully compiled for all 114 supported devices
- Comprehensive validation and testing completed

## Automatic Settings Reload Implementation (COMPLETED - v2.0.1)

### Overview
Implemented automatic watchface reload when users change settings, eliminating the need for manual refresh.

### Implementation

**App Class Enhancement**
```monkeyc
// source/MnmlstApp.mc
function onSettingsChanged() {
    // Get the current view and reload its configuration
    var view = WatchUi.getCurrentView()[0];
    if (view != null && view has :loadConfiguration) {
        view.loadConfiguration();
    }
    WatchUi.requestUpdate();
}
```

**Testing Implementation**
```monkeyc
// tests/MnmlstAppTest.mc  
(:test)
function testSettingsReload(logger as Test.Logger) {
    var app = new Mnmlst();
    var success = true;
    
    try {
        app.onSettingsChanged(); // Test method existence and execution
        
        if (!(app has :onSettingsChanged)) {
            logger.debug("Failed: onSettingsChanged method not found");
            success = false;
        }
    } catch (ex) {
        logger.debug("Failed: onSettingsChanged threw exception: " + ex.getErrorMessage());
        success = false;
    }
    
    return success;
}
```

### User Experience Impact
- **Instant Feedback**: Settings changes now immediately visible without manual refresh
- **Seamless Integration**: Works with all existing settings (visibility, colors, data fields, etc.)
- **Reliable Operation**: Proper error handling prevents crashes during settings updates

## Enhanced Visibility Improvements Implementation (COMPLETED - v2.0.2/2.0.3)

### Overview
Implemented comprehensive visibility improvements to enhance readability across all lighting conditions and device sizes.

### Technical Solutions Implemented

**1. Thick Segment Lines (Hash Marks)**
```monkeyc
function drawHashMarks(dc, one, two, length) {
    // Set pen width to 2 pixels for thicker segment lines
    dc.setPenWidth(2);
    
    // Draw all segment lines with proper thickness
    for (var i = Math.PI; i <= one * Math.PI; i += Math.PI) {
        dc.drawLine(sX, sY, eX, eY); // Now drawn with 2px thickness
    }
    
    // Reset pen width to default for other drawing operations
    dc.setPenWidth(1);
}
```

**2. Thick Battery Gauge Lines**
```monkeyc
function drawGaugeWithData(targetDc, width, height, percentage, useMultiColor) {
    // Set pen width to 2 pixels for thicker battery gauge lines
    targetDc.setPenWidth(2);
    
    // Draw exactly 11 gauge lines (0%, 10%, 20%, ..., 100%)
    for (var i = 0; i <= 10; i++) {
        targetDc.drawLine(xPos, battBaseHeight, xPos, battBaseHeight + layoutConfig[:batteryBarHeight]);
    }
    
    // Reset pen width to default
    targetDc.setPenWidth(1);
}
```

**3. Double Diameter Center Arbor**
```monkeyc
// Layout configuration - doubled from 7px to 14px radius
:arborRadius => (14 * scaleFactor).toNumber(),

// Fixed responsive usage in drawArbor()
function drawArbor(targetDc) {
    var arborRadius = layoutConfig[:arborRadius]; // Now uses responsive value
    targetDc.fillCircle(width / 2, height / 2, arborRadius);
    targetDc.drawCircle(width / 2, height / 2, arborRadius);
}
```

**4. Perfect Battery Indicator Alignment**
```monkeyc
// Fixed: Indicator circle now perfectly centered with gauge lines
targetDc.fillCircle(
    battLeft + battRangeSteps * (percentage / 10.0),
    battBaseHeight + (layoutConfig[:batteryBarHeight] / 2), // Perfectly centered
    layoutConfig[:batteryRadius]
);
```

### Initial Implementation Issues & Solutions

**Problem**: Multi-line offset approach created visual artifacts and uneven thickness
**Initial Attempt**:
```monkeyc
// PROBLEMATIC: Multiple offset lines created artifacts
function drawThickLine(dc, x1, y1, x2, y2) {
    dc.drawLine(x1, y1, x2, y2);
    dc.drawLine(x1 + perpX, y1 + perpY, x2 + perpX, y2 + perpY);
    dc.drawLine(x1 - perpX, y1 - perpY, x2 - perpX, y2 - perpY);
}
```

**Solution**: Used proper MonkeyC Graphics API
```monkeyc
// CORRECT: Clean, uniform thickness with built-in API
dc.setPenWidth(2);
dc.drawLine(x1, y1, x2, y2);
dc.setPenWidth(1);
```

**Key Benefits of Final Solution**:
- **Clean Implementation**: Uses official MonkeyC API instead of workarounds
- **Consistent Thickness**: No artifacts or uneven lines at different angles
- **Better Performance**: Single draw call instead of three
- **Cross-Device Compatibility**: `setPenWidth()` works uniformly across all Garmin devices

### Code Quality Improvements

**Removed Dead Code**: Eliminated unused `batteryOffset` configuration property after alignment fix
**Fixed Hardcoded Values**: Replaced hardcoded arbor radius with proper responsive layout usage
**Enhanced Responsive Scaling**: All visibility improvements scale properly across device sizes

### Release Progression

**v2.0.2**: Added automatic settings reload functionality
**v2.0.3**: Complete visibility improvements with proper API usage and battery indicator alignment

## Critical Build Management Rules

### **NEVER DELETE RELEASE BUILDS IN BIN/ DIRECTORY**

**MANDATORY RULE**: Release `.iq` files in the `bin/` directory must NEVER be deleted. These are:
- Historical version artifacts 
- Potential rollback candidates
- Distribution-ready packages that took significant time to build
- Universal builds supporting 114+ devices

**Correct Build Management Process**:
```bash
# Clean only intermediate build files, never release .iq files
rm -rf bin/gen/ bin/mir/ bin/internal-mir/ bin/external-mir/

# When building new releases, create new filenames
monkeyc -r -e -f monkey.jungle -o bin/MNMLST_v2.0.4_Release.iq -y "developer_key"

# Keep all release builds: MNMLST_v2.0.0_*.iq, MNMLST_v2.0.1_*.iq, etc.
```

**Build Artifacts to Preserve**:
- `MNMLST_v*.*.*.iq` - All release builds
- `*Release*.iq` - Any release-tagged builds
- `*Final*.iq` - Any final builds

**Build Artifacts Safe to Clean**:
- `test_*.prg` - Test builds
- `bin/gen/` - Generated intermediate files
- `bin/mir/` - MonkeyC intermediate representation files
- Unnamed `.prg` files from testing

### Build Process Documentation

**Standard Release Build Process**:
1. **Run Tests**: `connectiq test --device fenix7`
2. **Clean Intermediates**: Remove only non-release build files
3. **Update Version**: Increment version in `manifest.xml`
4. **Build Release**: `monkeyc -r -e -f monkey.jungle -o bin/MNMLST_v{VERSION}_Release.iq -y "developer_key"`
5. **Validate**: `connectiq validate bin/MNMLST_v{VERSION}_Release.iq`
6. **Preserve**: Never delete the resulting `.iq` file

**Universal Build Notes**:
- `-e` flag creates application packages compatible with Connect IQ Store
- Builds for all 114 supported devices in single `.iq` file
- Build time: ~2-3 minutes for complete universal build
- File size: ~6-7MB for complete universal package

### Test Infrastructure Evolution

**Test File Corrections Implemented**:
- Fixed `Logger` type annotations in all test files (`logger as Test.Logger`)
- Added comprehensive test for automatic settings reload functionality
- Simplified RenderingTest.mc to remove incompatible MockObjects usage
- Added visibility controls testing

**Testing Commands for Release Process**:
```bash
# Pre-release test execution
export PATH="/Users/bsu/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-8.2.3-2025-08-11-cac5b3b21/bin:$PATH"
connectiq test --device fenix7

# Multi-device validation
connectiq test --device fenix7,vivoactive4,epix2
```

### Connect IQ Store Compatibility

**Manifest Version Requirements**: Updated from `version="1"` to `version="3"` for modern Connect IQ app compliance

**Device Support**: All 63 devices from original manifest plus expanded compatibility through universal builds

**Package Format**: Using `-e` flag ensures proper Connect IQ Store application package format

---

*This document should be updated as the project evolves and new best practices are discovered.*