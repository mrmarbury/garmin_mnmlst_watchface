//
// Copyright 2024 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

using Toybox.Test;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Time;

// Integration tests for watchface rendering
(:test)
class RenderingTest {

    (:test)
    function testWatchfaceInitialization(logger) {
        logger.debug("Testing watchface initialization");
        
        var view = new MnmlstView();
        
        // Test that view was created successfully
        if (view == null) {
            logger.debug("Failed: Watchface view not created");
            return false;
        }
        
        // Test initial state
        if (view.isAwake == null) {
            logger.debug("Failed: isAwake not initialized");
            return false;
        }
        
        logger.debug("Passed: Watchface initialized successfully");
        return true;
    }

    (:test)
    function testOnLayoutSetup(logger) {
        logger.debug("Testing onLayout setup");
        
        var view = new MnmlstView();
        var mockDc = new MockObjects.MockDc(240, 240);
        
        try {
            view.onLayout(mockDc);
            
            // Test that screen center point is calculated
            if (view.screenCenterPoint == null) {
                logger.debug("Failed: Screen center point not set");
                return false;
            }
            
            if (view.screenCenterPoint.size() != 2) {
                logger.debug("Failed: Screen center point should have 2 coordinates");
                return false;
            }
            
            // Test that center point is calculated correctly
            var expectedCenterX = mockDc.getWidth() / 2;
            var expectedCenterY = mockDc.getHeight() / 2;
            
            if (view.screenCenterPoint[0] != expectedCenterX || view.screenCenterPoint[1] != expectedCenterY) {
                logger.debug("Failed: Screen center point calculated incorrectly");
                return false;
            }
            
            logger.debug("Passed: onLayout setup completed successfully");
            return true;
        } catch (ex) {
            logger.debug("Failed: onLayout threw exception: " + ex.getErrorMessage());
            return false;
        }
    }

    (:test)
    function testBasicDrawing(logger) {
        logger.debug("Testing basic drawing operations");
        
        var view = new MnmlstView();
        var mockDc = new MockObjects.MockDc(240, 240);
        
        // Initialize the view
        view.onLayout(mockDc);
        
        try {
            // Test that drawing doesn't crash
            view.onUpdate(mockDc);
            
            // Test that some drawing operations occurred
            if (!mockDc.hasDrawnType("fillRectangle")) {
                logger.debug("Failed: Background not drawn");
                return false;
            }
            
            if (!mockDc.hasDrawnType("fillPolygon")) {
                logger.debug("Failed: Watch hands not drawn");
                return false;
            }
            
            if (!mockDc.hasDrawnType("fillCircle")) {
                logger.debug("Failed: Center arbor not drawn");
                return false;
            }
            
            logger.debug("Passed: Basic drawing operations completed");
            return true;
        } catch (ex) {
            logger.debug("Failed: Drawing threw exception: " + ex.getErrorMessage());
            return false;
        }
    }

    (:test)
    function testHashMarkDrawing(logger) {
        logger.debug("Testing hash mark drawing");
        
        var view = new MnmlstView();
        var mockDc = new MockObjects.MockDc(240, 240);
        
        view.onLayout(mockDc);
        mockDc.reset();
        
        try {
            // Test drawing hash marks directly
            view.drawHashMarks(mockDc, 12, 6, 15);
            
            // Should have drawn multiple lines for hour marks
            var lineCount = mockDc.countDrawnType("drawLine");
            if (lineCount == 0) {
                logger.debug("Failed: No hash marks drawn");
                return false;
            }
            
            // Should have drawn exactly 24 lines (12 hours * 2 lines per hour)
            if (lineCount != 24) {
                logger.debug("Failed: Expected 24 hash marks, got " + lineCount);
                return false;
            }
            
            logger.debug("Passed: Hash marks drawn correctly");
            return true;
        } catch (ex) {
            logger.debug("Failed: Hash mark drawing threw exception: " + ex.getErrorMessage());
            return false;
        }
    }

    (:test)
    function testBatteryIndicator(logger) {
        logger.debug("Testing battery indicator drawing");
        
        var view = new MnmlstView();
        var mockDc = new MockObjects.MockDc(240, 240);
        
        view.onLayout(mockDc);
        mockDc.reset();
        
        try {
            view.drawBattery(mockDc, 240, 240);
            
            // Should have drawn battery scale lines
            var lineCount = mockDc.countDrawnType("drawLine");
            if (lineCount == 0) {
                logger.debug("Failed: No battery scale lines drawn");
                return false;
            }
            
            // Should have drawn battery level circle
            var circleCount = mockDc.countDrawnType("fillCircle");
            if (circleCount == 0) {
                logger.debug("Failed: No battery level indicator drawn");
                return false;
            }
            
            logger.debug("Passed: Battery indicator drawn correctly");
            return true;
        } catch (ex) {
            logger.debug("Failed: Battery indicator drawing threw exception: " + ex.getErrorMessage());
            return false;
        }
    }

    (:test)
    function testHourHandDrawing(logger) {
        logger.debug("Testing hour hand drawing");
        
        var view = new MnmlstView();
        var mockDc = new MockObjects.MockDc(240, 240);
        
        view.onLayout(mockDc);
        mockDc.reset();
        
        try {
            view.drawHourHand(mockDc);
            
            // Should have drawn hour hand polygon
            var polygonCount = mockDc.countDrawnType("fillPolygon");
            if (polygonCount == 0) {
                logger.debug("Failed: Hour hand polygon not drawn");
                return false;
            }
            
            // Should have set color for hour hand
            if (!mockDc.hasDrawnType("setColor")) {
                logger.debug("Failed: Hour hand color not set");
                return false;
            }
            
            logger.debug("Passed: Hour hand drawn correctly");
            return true;
        } catch (ex) {
            logger.debug("Failed: Hour hand drawing threw exception: " + ex.getErrorMessage());
            return false;
        }
    }

    (:test)
    function testArborDrawing(logger) {
        logger.debug("Testing arbor (center dot) drawing");
        
        var view = new MnmlstView();
        var mockDc = new MockObjects.MockDc(240, 240);
        
        view.onLayout(mockDc);
        mockDc.reset();
        
        try {
            view.drawArbor(mockDc);
            
            // Should have drawn filled circle for arbor
            var fillCircleCount = mockDc.countDrawnType("fillCircle");
            if (fillCircleCount == 0) {
                logger.debug("Failed: Arbor fill circle not drawn");
                return false;
            }
            
            // Should have drawn outline circle for arbor
            var drawCircleCount = mockDc.countDrawnType("drawCircle");
            if (drawCircleCount == 0) {
                logger.debug("Failed: Arbor outline circle not drawn");
                return false;
            }
            
            logger.debug("Passed: Arbor drawn correctly");
            return true;
        } catch (ex) {
            logger.debug("Failed: Arbor drawing threw exception: " + ex.getErrorMessage());
            return false;
        }
    }

    (:test)
    function testDateStringDrawing(logger) {
        logger.debug("Testing date string drawing");
        
        var view = new MnmlstView();
        var mockDc = new MockObjects.MockDc(240, 240);
        
        view.onLayout(mockDc);
        mockDc.reset();
        
        try {
            view.drawDateString(mockDc, 120, 60);
            
            // Should have drawn text for date
            var textCount = mockDc.countDrawnType("drawText");
            if (textCount == 0) {
                logger.debug("Failed: Date text not drawn");
                return false;
            }
            
            // Verify text was drawn at expected position
            var lastText = mockDc.getLastDrawnOfType("drawText");
            if (lastText == null || lastText[:x] != 120 || lastText[:y] != 60) {
                logger.debug("Failed: Date text not drawn at expected position");
                return false;
            }
            
            logger.debug("Passed: Date string drawn correctly");
            return true;
        } catch (ex) {
            logger.debug("Failed: Date string drawing threw exception: " + ex.getErrorMessage());
            return false;
        }
    }

    (:test)
    function testFullWatchfaceRender(logger) {
        logger.debug("Testing full watchface rendering");
        
        var view = new MnmlstView();
        var mockDc = new MockObjects.MockDc(240, 240);
        
        view.onLayout(mockDc);
        mockDc.reset();
        
        try {
            view.onUpdate(mockDc);
            
            // Verify all major elements are drawn
            var elementsDrawn = 0;
            
            if (mockDc.hasDrawnType("fillRectangle")) { elementsDrawn++; }  // Background
            if (mockDc.hasDrawnType("drawLine")) { elementsDrawn++; }       // Hash marks
            if (mockDc.hasDrawnType("fillPolygon")) { elementsDrawn++; }    // Watch hands
            if (mockDc.hasDrawnType("fillCircle")) { elementsDrawn++; }     // Battery/Arbor
            if (mockDc.hasDrawnType("drawText")) { elementsDrawn++; }       // Date/Notifications
            
            if (elementsDrawn < 4) {
                logger.debug("Failed: Not all major elements drawn. Count: " + elementsDrawn);
                return false;
            }
            
            logger.debug("Passed: Full watchface rendered with " + elementsDrawn + " element types");
            return true;
        } catch (ex) {
            logger.debug("Failed: Full watchface rendering threw exception: " + ex.getErrorMessage());
            return false;
        }
    }

    (:test)
    function testSleepModeHandling(logger) {
        logger.debug("Testing sleep mode handling");
        
        var view = new MnmlstView();
        
        try {
            // Test entering sleep mode
            view.onEnterSleep();
            if (view.isAwake != false) {
                logger.debug("Failed: isAwake should be false after onEnterSleep");
                return false;
            }
            
            // Test exiting sleep mode
            view.onExitSleep();
            if (view.isAwake != true) {
                logger.debug("Failed: isAwake should be true after onExitSleep");
                return false;
            }
            
            logger.debug("Passed: Sleep mode handled correctly");
            return true;
        } catch (ex) {
            logger.debug("Failed: Sleep mode handling threw exception: " + ex.getErrorMessage());
            return false;
        }
    }
}