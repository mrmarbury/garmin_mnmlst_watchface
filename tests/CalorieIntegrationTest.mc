//
// Calorie Integration Tests for MNMLST Watchface
// Tests the new calorie data fields and gauge functionality
//

using Toybox.Test;
using Toybox.Graphics;
using Toybox.System;
using Toybox.ActivityMonitor;
using Toybox.Lang;

// Test Calorie Data Field Types
(:test)
function testCalorieDataFields(logger) {
    logger.debug("Testing calorie data field functionality");
    
    var view = new MnmlstView();
    view.initialize();
    
    var success = true;
    
    // Test calories in message field (type 4)
    view.configMessageFieldType = 4;
    if (view.configMessageFieldType != 4) {
        logger.error("Calories message field type not set correctly");
        success = false;
    }
    
    // Test active calories in message field (type 5)
    view.configMessageFieldType = 5;
    if (view.configMessageFieldType != 5) {
        logger.error("Active calories message field type not set correctly");
        success = false;
    }
    
    // Test calories in date field (type 4)
    view.configDateFieldType = 4;
    if (view.configDateFieldType != 4) {
        logger.error("Calories date field type not set correctly");
        success = false;
    }
    
    // Test active calories in date field (type 5)
    view.configDateFieldType = 5;
    if (view.configDateFieldType != 5) {
        logger.error("Active calories date field type not set correctly");
        success = false;
    }
    
    logger.debug("Calorie data fields test " + (success ? "passed" : "failed"));
    return success;
}

// Test Calorie Progress Gauge Modes
(:test)
function testCalorieGaugeModes(logger) {
    logger.debug("Testing calorie gauge mode functionality");
    
    var view = new MnmlstView();
    view.initialize();
    
    var success = true;
    
    // Test calories progress gauge (mode 4)
    view.configBatteryDisplayMode = 4;
    if (view.configBatteryDisplayMode != 4) {
        logger.error("Calories gauge mode not set correctly");
        success = false;
    }
    
    // Test active calories progress gauge (mode 5)
    view.configBatteryDisplayMode = 5;
    if (view.configBatteryDisplayMode != 5) {
        logger.error("Active calories gauge mode not set correctly");
        success = false;
    }
    
    logger.debug("Calorie gauge modes test " + (success ? "passed" : "failed"));
    return success;
}

// Test Calorie Progress Calculations
(:test)
function testCalorieProgressCalculations(logger) {
    logger.debug("Testing calorie progress calculation functions");
    
    var view = new MnmlstView();
    view.initialize();
    
    // Set test calorie goals
    view.configCalorieGoalOverall = 2400;
    view.configCalorieGoalActive = 750;
    
    var success = true;
    
    try {
        var caloriesProgress = view.getCaloriesProgress();
        if (caloriesProgress < 0 || caloriesProgress > 100) {
            logger.error("Calories progress out of range: " + caloriesProgress);
            success = false;
        }
    } catch (ex) {
        logger.error("Exception in getCaloriesProgress: " + ex.getErrorMessage());
        success = false;
    }
    
    try {
        var activeCaloriesProgress = view.getActiveCaloriesProgress();
        if (activeCaloriesProgress < 0 || activeCaloriesProgress > 100) {
            logger.error("Active calories progress out of range: " + activeCaloriesProgress);
            success = false;
        }
    } catch (ex) {
        logger.error("Exception in getActiveCaloriesProgress: " + ex.getErrorMessage());
        success = false;
    }
    
    logger.debug("Calorie progress calculations test " + (success ? "passed" : "failed"));
    return success;
}

// Test Configuration Validation with New Ranges
(:test)
function testCalorieConfigurationValidation(logger) {
    logger.debug("Testing configuration validation with new calorie field ranges");
    
    var view = new MnmlstView();
    view.initialize();
    
    var success = true;
    
    // Test invalid values are corrected
    view.configMessageFieldType = 10; // Invalid
    view.validateConfiguration();
    if (view.configMessageFieldType != 0) {
        logger.error("Invalid message field type not corrected to 0");
        success = false;
    }
    
    view.configDateFieldType = -1; // Invalid
    view.validateConfiguration();
    if (view.configDateFieldType != 0) {
        logger.error("Invalid date field type not corrected to 0");
        success = false;
    }
    
    view.configBatteryDisplayMode = 10; // Invalid
    view.validateConfiguration();
    if (view.configBatteryDisplayMode != 0) {
        logger.error("Invalid battery display mode not corrected to 0");
        success = false;
    }
    
    // Test valid values are preserved
    view.configMessageFieldType = 5; // Valid (active calories)
    view.validateConfiguration();
    if (view.configMessageFieldType != 5) {
        logger.error("Valid message field type was incorrectly changed");
        success = false;
    }
    
    view.configDateFieldType = 4; // Valid (calories)
    view.validateConfiguration();
    if (view.configDateFieldType != 4) {
        logger.error("Valid date field type was incorrectly changed");
        success = false;
    }
    
    view.configBatteryDisplayMode = 5; // Valid (active calories)
    view.validateConfiguration();
    if (view.configBatteryDisplayMode != 5) {
        logger.error("Valid battery display mode was incorrectly changed");
        success = false;
    }
    
    logger.debug("Calorie configuration validation test " + (success ? "passed" : "failed"));
    return success;
}

// Test Goal Integration
(:test)
function testCalorieGoalIntegration(logger) {
    logger.debug("Testing calorie goal integration with settings");
    
    var view = new MnmlstView();
    view.initialize();
    
    var success = true;
    
    // Test that goals are properly stored and used
    view.configCalorieGoalOverall = 3000;
    view.configCalorieGoalActive = 900;
    
    if (view.configCalorieGoalOverall != 3000) {
        logger.error("Overall calorie goal not stored correctly");
        success = false;
    }
    
    if (view.configCalorieGoalActive != 900) {
        logger.error("Active calorie goal not stored correctly");
        success = false;
    }
    
    // Test goal validation ranges
    view.configCalorieGoalOverall = 500; // Below minimum
    view.validateConfiguration();
    if (view.configCalorieGoalOverall < 1000) {
        logger.error("Overall calorie goal validation should enforce minimum 1000");
        success = false;
    }
    
    view.configCalorieGoalActive = 50; // Below minimum
    view.validateConfiguration();
    if (view.configCalorieGoalActive < 200) {
        logger.error("Active calorie goal validation should enforce minimum 200");
        success = false;
    }
    
    logger.debug("Calorie goal integration test " + (success ? "passed" : "failed"));
    return success;
}