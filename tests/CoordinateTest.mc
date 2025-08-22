//
// Copyright 2024 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

using Toybox.Test;
using Toybox.Math;

// Test suite for coordinate generation algorithms
(:test)
class CoordinateTest {

    (:test)
    function testGenerateHandCoordinates(logger) {
        logger.debug("Testing generateHandCoordinates");
        
        var view = new MnmlstView();
        var centerPoint = [100, 100];
        var angle = 0; // 12 o'clock position
        var handLength = 50;
        var tailLength = 10;
        var width = 4;
        
        var coords = view.generateHandCoordinates(centerPoint, angle, handLength, tailLength, width);
        
        // Test that 4 coordinates are returned
        if (coords.size() != 4) {
            logger.debug("Failed: Expected 4 coordinates, got " + coords.size());
            return false;
        }
        
        // Test that coordinates are arrays with 2 elements each
        for (var i = 0; i < coords.size(); i++) {
            if (coords[i].size() != 2) {
                logger.debug("Failed: Coordinate " + i + " should have 2 elements");
                return false;
            }
        }
        
        // Test that at 0 angle (12 o'clock), hand points upward
        // At 0 angle, the hand should extend upward from center
        var topY = coords[0][1];
        if (coords[1][1] < topY) { topY = coords[1][1]; }
        if (topY >= centerPoint[1]) {
            logger.debug("Failed: Hand should extend upward at 0 angle");
            return false;
        }
        
        logger.debug("Passed: generateHandCoordinates works correctly");
        return true;
    }

    (:test)
    function testGenerateHourCoordinates(logger) {
        logger.debug("Testing generateHourCoordinates");
        
        var view = new MnmlstView();
        var centerPoint = [100, 100];
        var angle = 0; // 12 o'clock position
        var handLength = 50;
        var tailLength = 10;
        var width = 20;
        
        var coords = view.generateHourCoordinates(centerPoint, angle, handLength, tailLength, width);
        
        // Test that 3 coordinates are returned (triangular hour hand)
        if (coords.size() != 3) {
            logger.debug("Failed: Expected 3 coordinates for hour hand, got " + coords.size());
            return false;
        }
        
        // Test that coordinates are arrays with 2 elements each
        for (var i = 0; i < coords.size(); i++) {
            if (coords[i].size() != 2) {
                logger.debug("Failed: Coordinate " + i + " should have 2 elements");
                return false;
            }
        }
        
        // Test triangle formation - at 0 angle, should have two points at top and one at bottom
        var topPoints = 0;
        var bottomPoints = 0;
        for (var i = 0; i < coords.size(); i++) {
            if (coords[i][1] < centerPoint[1]) {
                topPoints++;
            } else if (coords[i][1] > centerPoint[1]) {
                bottomPoints++;
            }
        }
        
        if (topPoints != 2 || bottomPoints != 1) {
            logger.debug("Failed: Triangle not formed correctly at 0 angle");
            return false;
        }
        
        logger.debug("Passed: generateHourCoordinates works correctly");
        return true;
    }

    (:test)
    function testCoordinateRotation(logger) {
        logger.debug("Testing coordinate rotation");
        
        var view = new MnmlstView();
        var centerPoint = [100, 100];
        var handLength = 50;
        var tailLength = 10;
        var width = 4;
        
        // Test at 0 degrees (12 o'clock)
        var coords0 = view.generateHandCoordinates(centerPoint, 0, handLength, tailLength, width);
        
        // Test at 90 degrees (3 o'clock)
        var coords90 = view.generateHandCoordinates(centerPoint, Math.PI / 2, handLength, tailLength, width);
        
        // At 90 degrees, hand should extend to the right
        var rightMostX = coords90[0][0];
        for (var i = 1; i < coords90.size(); i++) {
            if (coords90[i][0] > rightMostX) { rightMostX = coords90[i][0]; }
        }
        if (rightMostX <= centerPoint[0]) {
            logger.debug("Failed: Hand should extend right at 90 degrees");
            return false;
        }
        
        // Test symmetry - rotating by 180 degrees should give opposite coordinates
        var coords180 = view.generateHandCoordinates(centerPoint, Math.PI, handLength, tailLength, width);
        
        // At 180 degrees, hand should extend downward
        var bottomMostY = coords180[0][1];
        for (var i = 1; i < coords180.size(); i++) {
            if (coords180[i][1] > bottomMostY) { bottomMostY = coords180[i][1]; }
        }
        if (bottomMostY <= centerPoint[1]) {
            logger.debug("Failed: Hand should extend downward at 180 degrees");
            return false;
        }
        
        logger.debug("Passed: Coordinate rotation works correctly");
        return true;
    }

    (:test)
    function testGetBoundingBox(logger) {
        logger.debug("Testing getBoundingBox");
        
        var view = new MnmlstView();
        var points = [
            [10, 20],
            [30, 5],
            [25, 35],
            [5, 15]
        ];
        
        var bbox = view.getBoundingBox(points);
        
        // Test that bounding box has correct structure
        if (bbox.size() != 2) {
            logger.debug("Failed: Bounding box should have 2 elements (min, max)");
            return false;
        }
        
        if (bbox[0].size() != 2 || bbox[1].size() != 2) {
            logger.debug("Failed: Min and max should each have 2 coordinates");
            return false;
        }
        
        // Test that min values are correct
        var expectedMinX = 5;
        var expectedMinY = 5;
        if (bbox[0][0] != expectedMinX || bbox[0][1] != expectedMinY) {
            logger.debug("Failed: Incorrect min values. Expected [" + expectedMinX + ", " + expectedMinY + "], got [" + bbox[0][0] + ", " + bbox[0][1] + "]");
            return false;
        }
        
        // Test that max values are correct
        var expectedMaxX = 30;
        var expectedMaxY = 35;
        if (bbox[1][0] != expectedMaxX || bbox[1][1] != expectedMaxY) {
            logger.debug("Failed: Incorrect max values. Expected [" + expectedMaxX + ", " + expectedMaxY + "], got [" + bbox[1][0] + ", " + bbox[1][1] + "]");
            return false;
        }
        
        logger.debug("Passed: getBoundingBox works correctly");
        return true;
    }

    (:test)
    function testEdgeCases(logger) {
        logger.debug("Testing edge cases");
        
        var view = new MnmlstView();
        
        // Test with zero dimensions
        var coords = view.generateHandCoordinates([0, 0], 0, 0, 0, 0);
        if (coords.size() != 4) {
            logger.debug("Failed: Should handle zero dimensions");
            return false;
        }
        
        // Test with negative dimensions
        try {
            coords = view.generateHandCoordinates([100, 100], 0, -10, -5, -2);
            // Should not crash
        } catch (ex) {
            logger.debug("Failed: Should handle negative dimensions gracefully");
            return false;
        }
        
        // Test bounding box with single point
        var singlePoint = [[10, 20]];
        var bbox = view.getBoundingBox(singlePoint);
        if (bbox[0][0] != 10 || bbox[0][1] != 20 || bbox[1][0] != 10 || bbox[1][1] != 20) {
            logger.debug("Failed: Bounding box with single point incorrect");
            return false;
        }
        
        logger.debug("Passed: Edge cases handled correctly");
        return true;
    }
}