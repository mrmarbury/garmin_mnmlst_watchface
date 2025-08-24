//
// Copyright 2024 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

using Toybox.Test;
using Toybox.Lang;

// Test suite for MnmlstApp class
(:test)
class MnmlstAppTest {

    (:test)
    function testInitialize(logger as Test.Logger) {
        logger.debug("Testing MnmlstApp initialize");
        
        var app = new Mnmlst();
        
        // Test that app was created successfully
        if (app == null) {
            logger.debug("Failed: App not created");
            return false;
        }
        
        logger.debug("Passed: App initialized successfully");
        return true;
    }

    (:test)
    function testGetInitialView(logger as Test.Logger) {
        logger.debug("Testing MnmlstApp getInitialView");
        
        var app = new Mnmlst();
        var views = app.getInitialView();
        
        // Test that views array is returned
        if (views == null) {
            logger.debug("Failed: No views returned");
            return false;
        }
        
        // Test that array has expected length
        if (views.size() < 1 || views.size() > 2) {
            logger.debug("Failed: Unexpected number of views: " + views.size());
            return false;
        }
        
        // Test that first element is MnmlstView
        if (!(views[0] instanceof MnmlstView)) {
            logger.debug("Failed: First view is not MnmlstView");
            return false;
        }
        
        // Test delegate presence based on API availability
        if (Toybox.WatchUi has :WatchFaceDelegate) {
            if (views.size() != 2) {
                logger.debug("Failed: Expected 2 views when WatchFaceDelegate available");
                return false;
            }
            if (!(views[1] instanceof MnmlstDelegate)) {
                logger.debug("Failed: Second view is not MnmlstDelegate");
                return false;
            }
        } else {
            if (views.size() != 1) {
                logger.debug("Failed: Expected 1 view when WatchFaceDelegate not available");
                return false;
            }
        }
        
        logger.debug("Passed: getInitialView returns correct views");
        return true;
    }

    (:test)
    function testAppLifecycle(logger as Test.Logger) {
        logger.debug("Testing MnmlstApp lifecycle methods");
        
        var app = new Mnmlst();
        
        try {
            // Test onStart - should not throw
            app.onStart(null);
            app.onStart({});
            
            // Test onStop - should not throw
            app.onStop(null);
            app.onStop({});
            
            logger.debug("Passed: Lifecycle methods execute without errors");
            return true;
        } catch (ex) {
            logger.debug("Failed: Lifecycle method threw exception: " + ex.getErrorMessage());
            return false;
        }
    }

    (:test)
    function testSettingsReload(logger as Test.Logger) {
        logger.debug("Testing automatic settings reload functionality");
        
        var app = new Mnmlst();
        var success = true;
        
        try {
            // Test that onSettingsChanged method exists and can be called
            app.onSettingsChanged();
            
            // We can't easily test the actual UI update without mocking WatchUi.getCurrentView()
            // But we can verify the method doesn't crash and completes successfully
            logger.debug("Settings reload method executed successfully");
            
        } catch (ex) {
            logger.debug("Failed: onSettingsChanged threw exception: " + ex.getErrorMessage());
            success = false;
        }
        
        // Test that the method exists by checking if we can access it
        if (!(app has :onSettingsChanged)) {
            logger.debug("Failed: onSettingsChanged method not found on app instance");
            success = false;
        }
        
        logger.debug(success ? "Passed: Settings reload functionality works" : "Failed: Settings reload functionality");
        return success;
    }

}