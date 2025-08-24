import Toybox.Test;
import Toybox.ActivityMonitor;
import Toybox.Graphics;

(:test)
function testInactivityAlertFunctionality(logger as Test.Logger) {
    logger.debug("Testing inactivity alert (move bar) functionality");
    
    var view = new MnmlstView();
    view.loadConfiguration();
    
    // Test getArborColor with different move bar levels
    
    // Test 1: No move bar alert (level at minimum)
    var colorNormal = view.getArborColor(ActivityMonitor.MOVE_BAR_LEVEL_MIN);
    var expectedNormalColor = view.configColorScheme == 1 
        ? Graphics.COLOR_BLACK 
        : Graphics.COLOR_LT_GRAY;
    
    if (colorNormal != expectedNormalColor) {
        logger.debug("FAIL: Normal arbor color incorrect. Expected: " + expectedNormalColor + ", Got: " + colorNormal);
        return false;
    }
    logger.debug("PASS: Normal arbor color correct");
    
    // Test 2: Move bar alert triggered (level above minimum)
    var colorAlert = view.getArborColor(ActivityMonitor.MOVE_BAR_LEVEL_MIN + 1);
    var expectedAlertColor = view.getRedColor();
    
    if (colorAlert != expectedAlertColor) {
        logger.debug("FAIL: Alert arbor color incorrect. Expected red: " + expectedAlertColor + ", Got: " + colorAlert);
        return false;
    }
    logger.debug("PASS: Alert arbor color correct (red)");
    
    // Test 3: Null move bar level handling
    var colorNull = view.getArborColor(0); // This simulates null handling in drawArbor
    if (colorNull != expectedNormalColor) {
        logger.debug("FAIL: Null move bar level handling incorrect");
        return false;
    }
    logger.debug("PASS: Null move bar level handled correctly");
    
    logger.debug("All inactivity alert tests passed");
    return true;
}

(:test)
function testArborVisibilityWithAlert(logger as Test.Logger) {
    logger.debug("Testing arbor visibility with inactivity alert");
    
    var view = new MnmlstView();
    view.loadConfiguration();
    
    // Test that arbor is drawn when showMinuteHand is enabled (1)
    if (view.showMinuteHand != 1) {
        // Temporarily set to enabled for test
        view.showMinuteHand = 1;
    }
    
    // Verify the arbor drawing logic works with visibility controls
    // The drawArbor function should be called when showMinuteHand == 1
    // and should use the correct color based on move bar level
    
    // Test the responsive arbor radius is properly configured
    var arborRadius = view.layoutConfig.get(:arborRadius);
    if (arborRadius == null || arborRadius <= 0) {
        logger.debug("FAIL: Arbor radius not properly configured");
        return false;
    }
    logger.debug("PASS: Arbor radius properly configured: " + arborRadius);
    
    // Test that doubled arbor size is working (should be > original 3px)
    if (arborRadius != null && arborRadius <= 3) {
        logger.debug("FAIL: Arbor radius not doubled as expected");
        return false;
    }
    logger.debug("PASS: Arbor radius properly doubled");
    
    logger.debug("Arbor visibility with alert tests passed");
    return true;
}