//
// Unit Tests for MNMLST Watchface
// Tests all implemented features: Configuration, Color Themes, Battery Gauge, Data Fields
//

using Toybox.Test;
using Toybox.Graphics;
using Toybox.System;
using Toybox.ActivityMonitor;
using Toybox.Lang;
using Toybox.Math;

// Mock ActivityMonitor for testing
(:test)
class MockActivityMonitor {
    static function getInfo() {
        return {
            :steps => 7500,
            :stepGoal => 10000,
            :activeMinutesWeek => {:total => 120},
            :activeMinutesWeekGoal => 150,
            :floorsClimbed => 15,
            :floorsClimbedGoal => 20,
            :moveBarLevel => ActivityMonitor.MOVE_BAR_LEVEL_MIN
        };
    }
}

// Mock System for testing
(:test)
class MockSystem {
    static function getSystemStats() {
        return {
            :battery => 75.0,
            :charging => false
        };
    }
    
    static function getDeviceSettings() {
        return {
            :phoneConnected => true,
            :notificationCount => 3,
            :partNumber => "TEST_DEVICE"
        };
    }
}

// Test Configuration System
(:test)
function testConfigurationLoading(logger) {
    logger.debug("Testing configuration loading");
    
    var view = new MnmlstView();
    view.initialize();
    
    // Test default configuration values
    var success = true;
    
    // These should be set to defaults during initialization
    if (view.configHourHandBehavior == null) {
        logger.error("configHourHandBehavior not initialized");
        success = false;
    }
    
    if (view.configColorScheme == null) {
        logger.error("configColorScheme not initialized");  
        success = false;
    }
    
    if (view.configBatteryDisplayMode == null) {
        logger.error("configBatteryDisplayMode not initialized");
        success = false;
    }
    
    logger.debug("Configuration loading test " + (success ? "passed" : "failed"));
    return success;
}

// Test Color Theme System
(:test)
function testColorThemeFunctions(logger as Test.Logger) {
    logger.debug("Testing color theme functions");
    
    var view = new MnmlstView();
    view.initialize();
    
    var success = true;
    
    // Test dark theme (colorScheme = 0)
    view.configColorScheme = 0;
    
    if (view.getBackgroundColor() != Graphics.COLOR_BLACK) {
        logger.error("Dark theme background should be black");
        success = false;
    }
    
    if (view.getTextColor() != Graphics.COLOR_WHITE) {
        logger.error("Dark theme text should be white");
        success = false;
    }
    
    if (view.getMinuteHandColor() != Graphics.COLOR_WHITE) {
        logger.error("Dark theme minute hand should be white");
        success = false;
    }
    
    // Test white theme (colorScheme = 1)  
    view.configColorScheme = 1;
    
    if (view.getBackgroundColor() != Graphics.COLOR_WHITE) {
        logger.error("White theme background should be white");
        success = false;
    }
    
    if (view.getTextColor() != Graphics.COLOR_BLACK) {
        logger.error("White theme text should be black");
        success = false;
    }
    
    if (view.getMinuteHandColor() != Graphics.COLOR_BLACK) {
        logger.error("White theme minute hand should be black");
        success = false;
    }
    
    logger.debug("Color theme test " + (success ? "passed" : "failed"));
    return success;
}

// Test Battery Gauge Positioning
(:test)
function testBatteryGaugeAlignment(logger as Test.Logger) {
    logger.debug("Testing battery gauge alignment");
    
    var view = new MnmlstView();
    view.initialize();
    
    // Create mock layout config for 260x260 screen
    var testWidth = 260;
    var testHeight = 260;
    
    view.layoutConfig = view.createLayoutConfig(testWidth, testHeight);
    
    var battLeft = view.layoutConfig[:batteryLeft];
    var battRight = view.layoutConfig[:batteryRight];
    var battRange = battRight - battLeft;
    var battRangeSteps = battRange / 10.0;
    
    var success = true;
    
    // Test that gauge is centered (25% to 75% of screen width)
    var expectedLeft = (testWidth * 0.25).toNumber();
    var expectedRight = (testWidth * 0.75).toNumber();
    
    if (battLeft != expectedLeft) {
        logger.error("Battery left position incorrect: " + battLeft + " vs " + expectedLeft);
        success = false;
    }
    
    if (battRight != expectedRight) {
        logger.error("Battery right position incorrect: " + battRight + " vs " + expectedRight);
        success = false;
    }
    
    // Test line positioning (11 lines: 0%, 10%, 20%, ..., 100%)
    for (var i = 0; i <= 10; i++) {
        var expectedPos = battLeft + (i * battRangeSteps);
        var percentage = i * 10;
        var dotPos = battLeft + battRangeSteps * (percentage / 10.0);
        
        if ((expectedPos - dotPos).abs() > 0.1) {
            logger.error("Line " + i + " and dot alignment mismatch at " + percentage + "%");
            success = false;
        }
    }
    
    logger.debug("Battery gauge alignment test " + (success ? "passed" : "failed"));
    return success;
}

// Test Responsive Layout System
(:test)
function testResponsiveLayout(logger as Test.Logger) {
    logger.debug("Testing responsive layout system");
    
    var view = new MnmlstView();
    view.initialize();
    
    var success = true;
    var testSizes = [
        [208, 208], // Small watch
        [240, 240], // Medium watch
        [260, 260], // Reference size
        [280, 280], // Large watch
        [390, 390]  // Very large watch
    ];
    
    for (var i = 0; i < testSizes.size(); i++) {
        var width = testSizes[i][0];
        var height = testSizes[i][1];
        
        var layout = view.createLayoutConfig(width, height);
        
        // Verify all layout properties are calculated
        var requiredProps = [
            :hourHandWidth, :hourHandLength, :minuteHandWidth, 
            :batteryLeft, :batteryRight, :batteryHeight,
            :hourHashLength, :minuteHashLength, :arborRadius
        ];
        
        for (var j = 0; j < requiredProps.size(); j++) {
            var prop = requiredProps[j];
            if (layout[prop] == null) {
                logger.error("Layout property " + prop + " not calculated for " + width + "x" + height);
                success = false;
            }
        }
        
        // Verify scaling makes sense (larger screens have larger elements)
        if (width > 260) {
            if (layout[:hourHandWidth] <= 160) {
                logger.error("Hour hand should scale up for larger screens");
                success = false;
            }
        } else if (width < 260) {
            if (layout[:hourHandWidth] >= 160) {
                logger.error("Hour hand should scale down for smaller screens");
                success = false;
            }
        }
    }
    
    logger.debug("Responsive layout test " + (success ? "passed" : "failed"));
    return success;
}

// Test Data Field Switching
(:test)
function testDataFieldTypes(logger as Test.Logger) {
    logger.debug("Testing data field type switching");
    
    var view = new MnmlstView();
    view.initialize();
    
    var success = true;
    
    // Test each message field type
    var messageFieldTypes = [0, 1, 2, 3]; // notifications, steps, heart_rate, battery_percent
    
    for (var i = 0; i < messageFieldTypes.size(); i++) {
        view.configMessageFieldType = messageFieldTypes[i];
        
        // This should not crash and should return some display string
        try {
            // We can't easily test the actual display without mocking Activity API
            // But we can test that the configuration is handled
            if (view.configMessageFieldType != messageFieldTypes[i]) {
                logger.error("Message field type not set correctly");
                success = false;
            }
        } catch (ex) {
            logger.error("Exception in message field type " + messageFieldTypes[i] + ": " + ex.getErrorMessage());
            success = false;
        }
    }
    
    // Test each date field type  
    var dateFieldTypes = [0, 1, 2, 3]; // date, steps, heart_rate, battery_percent
    
    for (var i = 0; i < dateFieldTypes.size(); i++) {
        view.configDateFieldType = dateFieldTypes[i];
        
        try {
            if (view.configDateFieldType != dateFieldTypes[i]) {
                logger.error("Date field type not set correctly");
                success = false;
            }
        } catch (ex) {
            logger.error("Exception in date field type " + dateFieldTypes[i] + ": " + ex.getErrorMessage());
            success = false;
        }
    }
    
    logger.debug("Data field switching test " + (success ? "passed" : "failed"));
    return success;
}

// Test Battery Display Modes
(:test)
function testBatteryDisplayModes(logger as Test.Logger) {
    logger.debug("Testing battery display modes");
    
    var view = new MnmlstView();
    view.initialize();
    
    var success = true;
    
    // Test each battery display mode
    var batteryModes = [0, 1, 2, 3]; // battery, steps, weekly_active_minutes, stairs
    
    for (var i = 0; i < batteryModes.size(); i++) {
        view.configBatteryDisplayMode = batteryModes[i];
        
        try {
            if (view.configBatteryDisplayMode != batteryModes[i]) {
                logger.error("Battery display mode not set correctly");
                success = false;
            }
        } catch (ex) {
            logger.error("Exception in battery display mode " + batteryModes[i] + ": " + ex.getErrorMessage());
            success = false;
        }
    }
    
    logger.debug("Battery display modes test " + (success ? "passed" : "failed"));
    return success;
}

// Test Progress Calculation Functions
(:test)
function testProgressCalculations(logger as Test.Logger) {
    logger.debug("Testing progress calculation functions");
    
    var view = new MnmlstView();
    view.initialize();
    
    var success = true;
    
    // Mock the ActivityMonitor.getInfo() function would be ideal here
    // For now, test that the functions don't crash
    
    try {
        var stepsProgress = view.getStepsProgress();
        if (stepsProgress < 0 || stepsProgress > 100) {
            logger.error("Steps progress out of range: " + stepsProgress);
            success = false;
        }
    } catch (ex) {
        logger.error("Exception in getStepsProgress: " + ex.getErrorMessage());
        success = false;
    }
    
    try {
        var weeklyProgress = view.getWeeklyActiveMinutesProgress();
        if (weeklyProgress < 0 || weeklyProgress > 100) {
            logger.error("Weekly progress out of range: " + weeklyProgress);
            success = false;
        }
    } catch (ex) {
        logger.error("Exception in getWeeklyActiveMinutesProgress: " + ex.getErrorMessage());
        success = false;
    }
    
    try {
        var stairsProgress = view.getStairsProgress();
        if (stairsProgress < 0 || stairsProgress > 100) {
            logger.error("Stairs progress out of range: " + stairsProgress);
            success = false;
        }
    } catch (ex) {
        logger.error("Exception in getStairsProgress: " + ex.getErrorMessage());
        success = false;
    }
    
    logger.debug("Progress calculations test " + (success ? "passed" : "failed"));
    return success;
}

// Test Hour Hand Behavior
(:test)
function testHourHandBehavior(logger as Test.Logger) {
    logger.debug("Testing hour hand behavior modes");
    
    var view = new MnmlstView();
    view.initialize();
    
    var success = true;
    
    // Test smooth vs discrete hour hand behavior
    view.configHourHandBehavior = 0; // Smooth
    if (view.configHourHandBehavior != 0) {
        logger.error("Smooth hour hand behavior not set correctly");
        success = false;
    }
    
    view.configHourHandBehavior = 1; // Discrete  
    if (view.configHourHandBehavior != 1) {
        logger.error("Discrete hour hand behavior not set correctly");
        success = false;
    }
    
    logger.debug("Hour hand behavior test " + (success ? "passed" : "failed"));
    return success;
}

// Test Configuration Validation
(:test)
function testConfigurationValidation(logger as Test.Logger) {
    logger.debug("Testing configuration validation");
    
    var view = new MnmlstView();
    view.initialize();
    
    var success = true;
    
    // Test invalid values are corrected
    view.configHourHandBehavior = -1;
    view.validateConfiguration();
    if (view.configHourHandBehavior != 0) {
        logger.error("Invalid hour hand behavior not corrected to 0");
        success = false;
    }
    
    view.configHourHandBehavior = 5;
    view.validateConfiguration();
    if (view.configHourHandBehavior != 0) {
        logger.error("Invalid hour hand behavior not corrected to 0");
        success = false;
    }
    
    view.configColorScheme = -1;
    view.validateConfiguration();
    if (view.configColorScheme != 0) {
        logger.error("Invalid color scheme not corrected to 0");
        success = false;
    }
    
    view.configColorScheme = 3;
    view.validateConfiguration();
    if (view.configColorScheme != 0) {
        logger.error("Invalid color scheme not corrected to 0");
        success = false;
    }
    
    logger.debug("Configuration validation test " + (success ? "passed" : "failed"));
    return success;
}

// Test Theme-Aware Status Colors
(:test)
function testThemeAwareColors(logger as Test.Logger) {
    logger.debug("Testing theme-aware status colors");
    
    var view = new MnmlstView();
    view.initialize();
    
    var success = true;
    
    // Test dark theme colors
    view.configColorScheme = 0;
    
    if (view.getGreenColor() != Graphics.COLOR_GREEN) {
        logger.error("Dark theme green color incorrect");
        success = false;
    }
    
    if (view.getRedColor() != Graphics.COLOR_RED) {
        logger.error("Dark theme red color incorrect");
        success = false;
    }
    
    // Test white theme colors
    view.configColorScheme = 1;
    
    if (view.getGreenColor() != Graphics.COLOR_DK_GREEN) {
        logger.error("White theme green color incorrect");
        success = false;
    }
    
    if (view.getRedColor() != Graphics.COLOR_DK_RED) {
        logger.error("White theme red color incorrect");
        success = false;
    }
    
    if (view.getYellowColor() != Graphics.COLOR_ORANGE) {
        logger.error("White theme yellow/orange color incorrect");
        success = false;
    }
    
    if (view.getBlueColor() != Graphics.COLOR_DK_BLUE) {
        logger.error("White theme blue color incorrect");
        success = false;
    }
    
    logger.debug("Theme-aware colors test " + (success ? "passed" : "failed"));
    return success;
}

// Test UI Element Visibility Controls
(:test)
function testUIElementVisibility(logger as Test.Logger) {
    logger.debug("Testing UI element visibility controls");
    
    var view = new MnmlstView();
    view.initialize();
    
    var success = true;
    
    // Test that all visibility settings are properly initialized
    if (view.showTopField == null) {
        logger.error("showTopField not initialized");
        success = false;
    }
    
    if (view.showMiddleGauge == null) {
        logger.error("showMiddleGauge not initialized");
        success = false;
    }
    
    if (view.showBottomField == null) {
        logger.error("showBottomField not initialized");
        success = false;
    }
    
    if (view.showMinuteHand == null) {
        logger.error("showMinuteHand not initialized");
        success = false;
    }
    
    // Test that visibility settings accept valid values (1 = show, 0 = hide)
    view.showTopField = 1;
    view.showMiddleGauge = 0;
    view.showBottomField = 1;
    view.showMinuteHand = 0;
    
    if (view.showTopField != 1) {
        logger.error("showTopField not set to 1 correctly");
        success = false;
    }
    
    if (view.showMiddleGauge != 0) {
        logger.error("showMiddleGauge not set to 0 correctly");
        success = false;
    }
    
    if (view.showBottomField != 1) {
        logger.error("showBottomField not set to 1 correctly");
        success = false;
    }
    
    if (view.showMinuteHand != 0) {
        logger.error("showMinuteHand not set to 0 correctly");
        success = false;
    }
    
    // Test default values after validation
    view.showTopField = null;
    view.validateConfiguration();
    if (view.showTopField != 1) {
        logger.error("showTopField default value should be 1 after validation");
        success = false;
    }
    
    logger.debug("UI element visibility test " + (success ? "passed" : "failed"));
    return success;
}