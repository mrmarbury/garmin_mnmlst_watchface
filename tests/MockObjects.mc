//
// Copyright 2024 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

using Toybox.Test;
using Toybox.Graphics;
using Toybox.Lang;

// Mock objects for testing watchface functionality
(:test)
class MockObjects {

    // Mock drawing context for testing rendering without actual display
    (:test)
    class MockDc {
        var width = 240;
        var height = 240;
        var drawnElements = [];
        var currentColor = Graphics.COLOR_WHITE;
        var backgroundColor = Graphics.COLOR_BLACK;
        
        function initialize(w, h) {
            width = w;
            height = h;
            drawnElements = [];
        }
        
        function getWidth() {
            return width;
        }
        
        function getHeight() {
            return height;
        }
        
        function setColor(foreground, background) {
            currentColor = foreground;
            backgroundColor = background;
            drawnElements.add({
                :type => "setColor",
                :foreground => foreground,
                :background => background
            });
        }
        
        function fillRectangle(x, y, width, height) {
            drawnElements.add({
                :type => "fillRectangle",
                :x => x,
                :y => y,
                :width => width,
                :height => height,
                :color => currentColor
            });
        }
        
        function fillPolygon(coordinates) {
            drawnElements.add({
                :type => "fillPolygon",
                :coordinates => coordinates,
                :color => currentColor
            });
        }
        
        function fillCircle(x, y, radius) {
            drawnElements.add({
                :type => "fillCircle",
                :x => x,
                :y => y,
                :radius => radius,
                :color => currentColor
            });
        }
        
        function drawCircle(x, y, radius) {
            drawnElements.add({
                :type => "drawCircle",
                :x => x,
                :y => y,
                :radius => radius,
                :color => currentColor
            });
        }
        
        function drawLine(x1, y1, x2, y2) {
            drawnElements.add({
                :type => "drawLine",
                :x1 => x1,
                :y1 => y1,
                :x2 => x2,
                :y2 => y2,
                :color => currentColor
            });
        }
        
        function drawText(x, y, font, text, justification) {
            drawnElements.add({
                :type => "drawText",
                :x => x,
                :y => y,
                :font => font,
                :text => text,
                :justification => justification,
                :color => currentColor
            });
        }
        
        function clear() {
            drawnElements.add({
                :type => "clear"
            });
        }
        
        function clearClip() {
            drawnElements.add({
                :type => "clearClip"
            });
        }
        
        function drawBitmap(x, y, bitmap) {
            drawnElements.add({
                :type => "drawBitmap",
                :x => x,
                :y => y,
                :bitmap => bitmap
            });
        }
        
        // Helper method to check if specific drawing operations occurred
        function hasDrawnType(type) {
            for (var i = 0; i < drawnElements.size(); i++) {
                if (drawnElements[i][:type].equals(type)) {
                    return true;
                }
            }
            return false;
        }
        
        // Helper method to count drawing operations of a specific type
        function countDrawnType(type) {
            var count = 0;
            for (var i = 0; i < drawnElements.size(); i++) {
                if (drawnElements[i][:type].equals(type)) {
                    count++;
                }
            }
            return count;
        }
        
        // Helper method to get the last drawn element of a specific type
        function getLastDrawnOfType(type) {
            for (var i = drawnElements.size() - 1; i >= 0; i--) {
                if (drawnElements[i][:type].equals(type)) {
                    return drawnElements[i];
                }
            }
            return null;
        }
        
        // Reset drawing history
        function reset() {
            drawnElements = [];
        }
    }

    // Mock system settings for testing device-specific behavior
    (:test)
    class MockDeviceSettings {
        var phoneConnected = true;
        var notificationCount = 0;
        var screenShape = 1; // SCREEN_SHAPE_ROUND
        
        function initialize(connected, notifications, shape) {
            phoneConnected = connected;
            notificationCount = notifications;
            screenShape = shape;
        }
    }

    // Mock system stats for testing battery and performance
    (:test) 
    class MockSystemStats {
        var battery = 50.0;
        var charging = false;
        var usedMemory = 1024;
        var totalMemory = 4096;
        
        function initialize(batteryLevel, isCharging) {
            battery = batteryLevel;
            charging = isCharging;
        }
    }

    // Mock activity monitor info for testing move bar and fitness data
    (:test)
    class MockActivityInfo {
        var moveBarLevel = 0; // MOVE_BAR_LEVEL_MIN
        var steps = 5000;
        var calories = 250;
        
        function initialize(moveLevel, stepCount) {
            moveBarLevel = moveLevel;
            steps = stepCount;
        }
    }

    // Mock clock time for testing time-dependent rendering
    (:test)
    class MockClockTime {
        var hour = 12;
        var min = 30;
        var sec = 45;
        
        function initialize(h, m, s) {
            hour = h;
            min = m;
            sec = s;
        }
    }
}