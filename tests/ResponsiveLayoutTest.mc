//
// Copyright 2024 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

using Toybox.Test;
using Toybox.Math;

// Test suite for responsive layout scaling calculations
(:test)
class ResponsiveLayoutTest {

    // Helper function for absolute value since Math.abs has issues in MonkeyC
    function abs(value) {
        return value < 0 ? -value : value;
    }

    (:test)
    function testCalculateScaleFactor(logger) {
        logger.debug("Testing calculateScaleFactor");
        
        var view = new MnmlstView();
        
        // Test reference resolution (260x260) - should return 1.0
        var factor260 = view.calculateScaleFactor(260, 260);
        if (abs(factor260 - 1.0) > 0.001) {
            logger.debug("Failed: Reference resolution should give scale factor 1.0, got " + factor260);
            return false;
        }
        
        // Test smaller screen (218x218 - Fenix 5S) - should be < 1.0
        var factor218 = view.calculateScaleFactor(218, 218);
        if (factor218 >= 1.0) {
            logger.debug("Failed: Smaller screen should have scale factor < 1.0, got " + factor218);
            return false;
        }
        
        // Test larger screen (416x416 - Epix 2 Pro) - should be > 1.0
        var factor416 = view.calculateScaleFactor(416, 416);
        if (factor416 <= 1.0) {
            logger.debug("Failed: Larger screen should have scale factor > 1.0, got " + factor416);
            return false;
        }
        
        // Test non-square screen (240x240 - VivoActive 3)
        var factor240 = view.calculateScaleFactor(240, 240);
        var expected240 = 240.0 / 260.0;  // Should be ~0.923
        if (abs(factor240 - expected240) > 0.001) {
            logger.debug("Failed: 240x240 scale factor incorrect. Expected " + expected240 + ", got " + factor240);
            return false;
        }
        
        logger.debug("Passed: calculateScaleFactor works correctly");
        return true;
    }

    (:test)
    function testLayoutConfigurationScaling(logger) {
        logger.debug("Testing layout configuration scaling");
        
        var view = new MnmlstView();
        
        // Test small screen configuration (218x218)
        var smallConfig = view.createLayoutConfig(218, 218);
        var smallScale = 218.0 / 260.0;  // ~0.838
        
        // Verify hour hand width scales correctly
        var expectedHourHandWidth = (160 * smallScale).toNumber();
        if (smallConfig[:hourHandWidth] != expectedHourHandWidth) {
            logger.debug("Failed: Hour hand width scaling incorrect for small screen");
            return false;
        }
        
        // Test large screen configuration (416x416)
        var largeConfig = view.createLayoutConfig(416, 416);
        var largeScale = 416.0 / 260.0;  // ~1.6
        
        // Verify hour hand width scales correctly
        var expectedLargeHourHandWidth = (160 * largeScale).toNumber();
        if (largeConfig[:hourHandWidth] != expectedLargeHourHandWidth) {
            logger.debug("Failed: Hour hand width scaling incorrect for large screen");
            return false;
        }
        
        // Verify proportional relationships are maintained
        if (largeConfig[:hourHandWidth] <= smallConfig[:hourHandWidth]) {
            logger.debug("Failed: Large screen should have larger hour hand width than small screen");
            return false;
        }
        
        logger.debug("Passed: Layout configuration scaling works correctly");
        return true;
    }

    (:test)
    function testBatteryPositioning(logger) {
        logger.debug("Testing battery positioning calculations");
        
        var view = new MnmlstView();
        
        // Test different screen sizes
        var screens = [
            [218, 218],  // Fenix 5S
            [240, 240],  // VivoActive 3
            [260, 260],  // Fenix 7 (reference)
            [416, 416]   // Epix 2 Pro
        ];
        
        for (var i = 0; i < screens.size(); i++) {
            var width = screens[i][0];
            var height = screens[i][1];
            var config = view.createLayoutConfig(width, height);
            
            // Verify battery positions are within screen bounds
            if (config[:batteryLeft] < 0 || config[:batteryLeft] >= width) {
                logger.debug("Failed: batteryLeft out of bounds for " + width + "x" + height);
                return false;
            }
            
            if (config[:batteryRight] <= config[:batteryLeft] || config[:batteryRight] > width) {
                logger.debug("Failed: batteryRight invalid for " + width + "x" + height);
                return false;
            }
            
            if (config[:batteryHeight] < 0 || config[:batteryHeight] >= height) {
                logger.debug("Failed: batteryHeight out of bounds for " + width + "x" + height);
                return false;
            }
            
            // Verify proportional relationships are maintained (battery should be 25-75% of width)
            var expectedLeft = width * 0.25;
            if (abs(config[:batteryLeft] - expectedLeft) > 1) {
                logger.debug("Failed: Battery left position not proportional for " + width + "x" + height);
                return false;
            }
        }
        
        logger.debug("Passed: Battery positioning calculations work correctly");
        return true;
    }

    (:test)
    function testHashMarkScaling(logger) {
        logger.debug("Testing hash mark scaling");
        
        var view = new MnmlstView();
        var referenceConfig = view.createLayoutConfig(260, 260);
        
        // Test that hash marks scale proportionally
        var smallConfig = view.createLayoutConfig(218, 218);
        var largeConfig = view.createLayoutConfig(416, 416);
        
        // Hour hash marks should scale
        if (smallConfig[:hourHashLength] >= referenceConfig[:hourHashLength]) {
            logger.debug("Failed: Small screen hash marks should be smaller than reference");
            return false;
        }
        
        if (largeConfig[:hourHashLength] <= referenceConfig[:hourHashLength]) {
            logger.debug("Failed: Large screen hash marks should be larger than reference");
            return false;
        }
        
        // Minute hash marks should maintain ratio to hour hash marks
        var refRatio = referenceConfig[:minuteHashLength].toFloat() / referenceConfig[:hourHashLength].toFloat();
        var smallRatio = smallConfig[:minuteHashLength].toFloat() / smallConfig[:hourHashLength].toFloat();
        var largeRatio = largeConfig[:minuteHashLength].toFloat() / largeConfig[:hourHashLength].toFloat();
        
        if (abs(refRatio - smallRatio) > 0.1 || abs(refRatio - largeRatio) > 0.1) {
            logger.debug("Failed: Hash mark ratios not consistent across screen sizes");
            return false;
        }
        
        logger.debug("Passed: Hash mark scaling works correctly");
        return true;
    }

    (:test)
    function testNotificationPositioning(logger) {
        logger.debug("Testing notification positioning");
        
        var view = new MnmlstView();
        
        // Test different screen heights
        var heights = [218, 240, 260, 416];
        
        for (var i = 0; i < heights.size(); i++) {
            var height = heights[i];
            var config = view.createLayoutConfig(260, height);  // Use standard width, vary height
            
            // Calculate notification position
            var notificationY = height * config[:notificationOffsetRatio];
            
            // Should be in bottom portion of screen (> 50% down)
            if (notificationY < height * 0.5) {
                logger.debug("Failed: Notification should be in bottom half of screen for height " + height);
                return false;
            }
            
            // Should not be too close to bottom edge (< 90% down)
            if (notificationY > height * 0.9) {
                logger.debug("Failed: Notification too close to bottom edge for height " + height);
                return false;
            }
            
            // Should maintain consistent relative positioning (~77% from top)
            var expectedRatio = 0.77;
            var actualRatio = notificationY / height;
            if (abs(actualRatio - expectedRatio) > 0.05) {
                logger.debug("Failed: Notification position ratio inconsistent for height " + height);
                return false;
            }
        }
        
        logger.debug("Passed: Notification positioning works correctly");
        return true;
    }

    (:test)
    function testDatePositioning(logger) {
        logger.debug("Testing date positioning");
        
        var view = new MnmlstView();
        
        // Test different screen heights
        var heights = [218, 240, 260, 416];
        
        for (var i = 0; i < heights.size(); i++) {
            var height = heights[i];
            var config = view.createLayoutConfig(260, height);
            
            // Calculate date position
            var dateY = height * config[:dateOffsetRatio];
            
            // Should be in top portion of screen (< 50% down)
            if (dateY > height * 0.5) {
                logger.debug("Failed: Date should be in top half of screen for height " + height);
                return false;
            }
            
            // Should maintain consistent relative positioning (~25% from top)
            var expectedRatio = 0.25;
            var actualRatio = dateY / height;
            if (abs(actualRatio - expectedRatio) > 0.02) {
                logger.debug("Failed: Date position ratio inconsistent for height " + height + ". Expected " + expectedRatio + ", got " + actualRatio);
                return false;
            }
        }
        
        logger.debug("Passed: Date positioning works correctly");
        return true;
    }

    (:test)
    function testScalingConsistency(logger) {
        logger.debug("Testing scaling consistency across elements");
        
        var view = new MnmlstView();
        var config260 = view.createLayoutConfig(260, 260);  // Reference
        var config218 = view.createLayoutConfig(218, 218);  // Small
        var config416 = view.createLayoutConfig(416, 416);  // Large
        
        var scale218 = 218.0 / 260.0;
        var scale416 = 416.0 / 260.0;
        
        // Test that all scaled elements maintain consistent ratios
        var elementsToTest = [
            :hourHandWidth,
            :hourHashLength,
            :minuteHashLength,
            :batteryRadius,
            :batteryOffset,
            :arborRadius
        ];
        
        for (var i = 0; i < elementsToTest.size(); i++) {
            var key = elementsToTest[i];
            var ref = config260[key];
            var small = config218[key];
            var large = config416[key];
            
            // Check if scaling is approximately correct
            var expectedSmall = (ref * scale218).toNumber();
            var expectedLarge = (ref * scale416).toNumber();
            
            if (abs(small - expectedSmall) > 2) {  // Allow 2px tolerance
                logger.debug("Failed: " + key + " scaling inconsistent for small screen. Expected " + expectedSmall + ", got " + small);
                return false;
            }
            
            if (abs(large - expectedLarge) > 2) {  // Allow 2px tolerance
                logger.debug("Failed: " + key + " scaling inconsistent for large screen. Expected " + expectedLarge + ", got " + large);
                return false;
            }
        }
        
        logger.debug("Passed: Scaling consistency maintained across all elements");
        return true;
    }

    (:test)
    function testScreenSizeRanges(logger) {
        logger.debug("Testing supported screen size ranges");
        
        var view = new MnmlstView();
        
        // Test minimum supported screen size
        var minConfig = view.createLayoutConfig(208, 208);  // Smallest theoretical
        
        // Test maximum supported screen size  
        var maxConfig = view.createLayoutConfig(450, 450);  // Largest theoretical
        
        // Verify that all configuration values are reasonable
        var keysToCheck = [
            :hourHandWidth,
            :hourHashLength,
            :minuteHashLength,
            :batteryRadius,
            :batteryOffset
        ];
        
        for (var i = 0; i < keysToCheck.size(); i++) {
            var key = keysToCheck[i];
            
            // Minimum values should be at least 1 pixel
            if (minConfig[key] < 1) {
                logger.debug("Failed: " + key + " too small for minimum screen size: " + minConfig[key]);
                return false;
            }
            
            // Maximum values should be reasonable (not more than 50px for small elements)
            if (key != :hourHandWidth && maxConfig[key] > 50) {
                logger.debug("Failed: " + key + " too large for maximum screen size: " + maxConfig[key]);
                return false;
            }
            
            // Hour hand width can be larger but should be reasonable
            if (key == :hourHandWidth && maxConfig[key] > 300) {
                logger.debug("Failed: Hour hand width unreasonably large: " + maxConfig[key]);
                return false;
            }
        }
        
        logger.debug("Passed: Screen size ranges handled correctly");
        return true;
    }
}