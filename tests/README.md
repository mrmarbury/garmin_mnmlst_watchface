# MNMLST Watchface Test Suite

This directory contains comprehensive unit and integration tests for the MNMLST Garmin Connect IQ watchface project.

## Test Structure

### Test Files

- **`MnmlstAppTest.mc`** - Unit tests for the main MnmlstApp class
  - App initialization
  - Initial view creation
  - Lifecycle methods (onStart, onStop)
  - Temperature variable handling

- **`CoordinateTest.mc`** - Unit tests for coordinate generation algorithms
  - Hand coordinate generation (minute hand)
  - Hour hand coordinate generation (triangular)
  - Coordinate rotation at different angles
  - Bounding box calculations
  - Edge case handling

- **`RenderingTest.mc`** - Integration tests for watchface rendering
  - Watchface initialization
  - Layout setup (onLayout)
  - Basic drawing operations
  - Individual element rendering (hash marks, battery, hands, arbor, date)
  - Full watchface rendering
  - Sleep mode handling

- **`MockObjects.mc`** - Mock objects for testing without hardware dependencies
  - MockDc - Mock drawing context for testing rendering
  - MockDeviceSettings - Mock device settings (Bluetooth, notifications)
  - MockSystemStats - Mock system statistics (battery, memory)
  - MockActivityInfo - Mock activity data (move bar, steps)
  - MockClockTime - Mock time for testing time-dependent features

- **`TestRunner.mc`** - Test runner to execute all test suites
  - Runs all tests in sequence
  - Tracks pass/fail statistics
  - Provides comprehensive test results

## Running Tests

### Prerequisites

1. Garmin Connect IQ SDK installed
2. MonkeyC compiler available
3. Supported device simulator or hardware

### Command Line Testing

```bash
# Run tests on simulator
connectiq test --device fenix7

# Run tests on multiple devices
connectiq test --device fenix7,vivoactive4,forerunner955

# Run specific test file
connectiq test --device fenix7 --test tests/MnmlstAppTest.mc
```

### Build Configuration

The `monkey.jungle` file has been updated to include test configurations:

```
project.sourcePath = source;tests
project.testSourcePath = tests
```

## Test Coverage

### Functional Areas Covered

1. **Application Lifecycle**
   - App initialization and startup
   - View creation and management
   - State management

2. **Mathematical Operations**
   - Coordinate transformations
   - Trigonometric calculations for watch hands
   - Geometric operations (bounding boxes)

3. **Rendering System**
   - Drawing context operations
   - Individual UI element rendering
   - Color and style management
   - Performance optimizations

4. **User Interface Elements**
   - Watch hands (hour and minute)
   - Hash marks and tick indicators
   - Battery level indicator
   - Date display
   - Center arbor with move reminder
   - Notification count

5. **System Integration**
   - Sleep mode handling
   - Device capability detection
   - Error handling and recovery

### Test Types

- **Unit Tests** - Test individual functions and methods in isolation
- **Integration Tests** - Test component interactions and full rendering pipeline
- **Mock Testing** - Test behavior with simulated system dependencies
- **Edge Case Testing** - Test boundary conditions and error scenarios

## Test Results Interpretation

### Success Criteria

- All coordinate generation produces valid polygons
- Rendering operations complete without errors
- UI elements are drawn in correct positions
- Color changes reflect system state correctly
- Sleep mode transitions work properly

### Common Issues

1. **Coordinate Validation Failures**
   - Check angle calculations (radians vs degrees)
   - Verify coordinate transformations
   - Ensure polygon vertices are valid

2. **Rendering Issues**
   - Verify drawing context setup
   - Check color and style settings
   - Ensure proper buffer management

3. **System Integration Problems**
   - Mock object configuration
   - API compatibility issues
   - Device-specific behaviors

## Extending Tests

### Adding New Tests

1. Create test functions with `(:test)` annotation
2. Follow naming convention: `test<FunctionName>`
3. Include comprehensive error checking
4. Add meaningful debug messages
5. Update TestRunner.mc to include new tests

### Mock Object Usage

```monkey-c
// Example: Testing with mock drawing context
var mockDc = new MockObjects.MockDc(240, 240);
view.onUpdate(mockDc);

// Verify specific drawing operations occurred
if (!mockDc.hasDrawnType("fillPolygon")) {
    logger.debug("Failed: Watch hands not drawn");
    return false;
}
```

### Best Practices

- Test one concept per test function
- Use descriptive test names
- Include both positive and negative test cases
- Mock external dependencies
- Verify both successful operations and error conditions
- Keep tests independent and repeatable

## Continuous Integration

These tests can be integrated into CI/CD pipelines:

1. **Build Verification** - Run basic tests on each commit
2. **Device Compatibility** - Test on multiple device types
3. **Performance Regression** - Monitor rendering performance
4. **Code Coverage** - Track test coverage metrics

## Troubleshooting

### Common Test Failures

1. **"Cannot resolve type" errors** - Check import statements and type annotations
2. **Null reference exceptions** - Verify mock object initialization
3. **Coordinate calculation errors** - Check mathematical operations and angle conversions
4. **Rendering verification failures** - Ensure mock drawing context is properly configured

### Debug Strategies

- Use logger.debug() extensively for troubleshooting
- Check test execution order dependencies
- Verify mock object state between tests
- Review actual vs expected coordinate values
- Test individual components before integration tests

This test suite provides comprehensive coverage of the MNMLST watchface functionality and helps ensure code quality and reliability during development and refactoring.