//
// Copyright 2024 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

using Toybox.Test;

// Test runner to execute all test suites
(:test)
function runAllTests(logger) {
    logger.debug("Starting MNMLST Watchface Test Suite");
    
    var totalTests = 0;
    var passedTests = 0;
    var failedTests = 0;
    
    // Run MnmlstApp tests - simplified approach
    logger.debug("=== Running All Tests ===");
    
    try {
        var appTest = new MnmlstAppTest();
        if (appTest.testInitialize(logger)) { passedTests++; } else { failedTests++; }
        totalTests++;
        
        if (appTest.testGetInitialView(logger)) { passedTests++; } else { failedTests++; }
        totalTests++;
        
        if (appTest.testAppLifecycle(logger)) { passedTests++; } else { failedTests++; }
        totalTests++;
        
        var coordTest = new CoordinateTest();
        if (coordTest.testGenerateHandCoordinates(logger)) { passedTests++; } else { failedTests++; }
        totalTests++;
        
        if (coordTest.testGenerateHourCoordinates(logger)) { passedTests++; } else { failedTests++; }
        totalTests++;
        
        var renderTest = new RenderingTest();
        if (renderTest.testWatchfaceInitialization(logger)) { passedTests++; } else { failedTests++; }
        totalTests++;
        
        if (renderTest.testSleepModeHandling(logger)) { passedTests++; } else { failedTests++; }
        totalTests++;
        
        // Run responsive layout tests
        var responsiveTest = new ResponsiveLayoutTest();
        if (responsiveTest.testCalculateScaleFactor(logger)) { passedTests++; } else { failedTests++; }
        totalTests++;
        
        if (responsiveTest.testLayoutConfigurationScaling(logger)) { passedTests++; } else { failedTests++; }
        totalTests++;
        
        if (responsiveTest.testBatteryPositioning(logger)) { passedTests++; } else { failedTests++; }
        totalTests++;
        
        if (responsiveTest.testHashMarkScaling(logger)) { passedTests++; } else { failedTests++; }
        totalTests++;
        
        if (responsiveTest.testNotificationPositioning(logger)) { passedTests++; } else { failedTests++; }
        totalTests++;
        
        if (responsiveTest.testDatePositioning(logger)) { passedTests++; } else { failedTests++; }
        totalTests++;
        
        if (responsiveTest.testScalingConsistency(logger)) { passedTests++; } else { failedTests++; }
        totalTests++;
        
        if (responsiveTest.testScreenSizeRanges(logger)) { passedTests++; } else { failedTests++; }
        totalTests++;
        
    } catch (ex) {
        logger.debug("Error running tests: " + ex.getErrorMessage());
        failedTests++;
    }
    
    // Print results
    logger.debug("Total Tests: " + totalTests);
    logger.debug("Passed: " + passedTests);
    logger.debug("Failed: " + failedTests);
    
    return failedTests == 0;
}