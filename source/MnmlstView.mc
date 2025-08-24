//
// Copyright 2016-2017 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Math;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.WatchUi;
using Toybox.Application.Properties;
using Toybox.Activity;
using Toybox.Application;
using Toybox.ActivityMonitor;

var partialUpdatesAllowed = false;

// This implements an analog watch face
// Original design by Austen Harbour
class MnmlstView extends WatchUi.WatchFace {
  var isAwake;
  var screenShape;
  var offscreenBuffer;
  var dateBuffer;
  var notificationBuffer;
  var curClip;
  var screenCenterPoint;
  var fullScreenRefresh;
  var bt_connected = true;
  var msgCountMultiplier; // Will be set in onLayout based on screen size

  // Responsive layout system - Performance optimized
  // All scaling calculations done once in onLayout() and cached for rendering performance
  var scaleFactor;
  var layoutConfig;

  // Configuration properties - cached for performance
  var configHourHandBehavior;
  var configBatteryDisplayMode;
  var configMessageFieldType;
  var configDateFieldType;
  var configColorScheme;
  var configCalorieGoalOverall;
  var configCalorieGoalActive;

  // UI Element Visibility properties
  var showTopField;
  var showMiddleGauge;
  var showBottomField;
  var showMinuteHand;

  // Initialize variables for this view
  function initialize() {
    WatchFace.initialize();
    screenShape = System.getDeviceSettings().screenShape;
    fullScreenRefresh = true;
    partialUpdatesAllowed = Toybox.WatchUi.WatchFace has :onPartialUpdate;
  }

  // Calculate responsive scale factor based on screen size
  // Reference resolution: 260x260 (common mid-range device size)
  function calculateScaleFactor(width, height) {
    var referenceSize = 260.0;
    var avgDimension = (width + height) / 2.0;
    return avgDimension / referenceSize;
  }

  // Create layout configuration based on screen dimensions
  // Called once per session in onLayout() to optimize rendering performance
  function createLayoutConfig(width, height) {
    scaleFactor = calculateScaleFactor(width, height);

    return {
      // Hour hand configuration
      :hourHandWidth => (160 * scaleFactor).toNumber(),
      :hourHandLength => (151.6 * scaleFactor).toNumber(), // Responsive replacement for width/1.714 (260/1.714≈151.6)
      :hourHandLengthRatio => 0.6, // 60% of screen radius
      :hourTailRatio => 0.15, // 15% of screen radius

      // Minute hand configuration
      :minuteHandWidth => (2 * scaleFactor).toNumber(),
      :minuteHandLengthRatio => 0.9, // 90% of screen radius
      :minuteTailLength => (15 * scaleFactor).toNumber(),

      // Hash marks configuration
      :hourHashLength => (15 * scaleFactor).toNumber(),
      :minuteHashLength => (5 * scaleFactor).toNumber(),

      // Battery gauge configuration - perfectly centered
      :batteryLeft => (width * 0.25).toNumber(), // 25% from left edge, ensure integer
      :batteryRight => (width * 0.75).toNumber(), // 75% from left edge, ensure integer
      :batteryHeight => height * 0.67, // 67% from top
      :batteryBarHeight => (11 * scaleFactor).toNumber(),

      // Text positioning
      :dateOffsetRatio => 0.25, // 25% from top
      :notificationOffsetRatio => 0.77, // 77% from top

      // Center arbor (doubled for better visibility)
      :arborRadius => (8 * scaleFactor).toNumber(),

      // Battery gauge circle configuration
      :batteryRadius => (5 * scaleFactor).toNumber(),

      // Notification positioning multiplier
      :msgCountMultiplier => 4.6 * scaleFactor,
    };
  }

  // Load configuration properties from application settings
  // Called once per session in onLayout() to optimize performance
  function loadConfiguration() {
    try {
      // TEMPORARY: Manual override for simulator testing
      // Remove this block after testing is complete
      var deviceSettings = System.getDeviceSettings();
      if (
        deviceSettings.partNumber != null &&
        deviceSettings.partNumber.toString().find("SIMULATOR") != null
      ) {
        System.println("SIMULATOR DETECTED - Using test configuration");
        configBatteryDisplayMode = 4; // Test calories progress
        configHourHandBehavior = 1; // Test hourly jump
        configMessageFieldType = 4; // Test calories in message field
        configDateFieldType = 5; // Test active calories in date field
        configColorScheme = 1; // Test white theme
        configCalorieGoalOverall = 2400;
        configCalorieGoalActive = 750;
        // Test visibility settings
        showTopField = 1;
        showMiddleGauge = 0; // Test hidden gauge
        showBottomField = 1;
        showMinuteHand = 1;
        System.println(
          "Test config - Battery: " +
            configBatteryDisplayMode +
            ", Hand: " +
            configHourHandBehavior
        );
        return;
      }
      // END TEMPORARY SECTION

      // Load properties with explicit null checks
      configHourHandBehavior = Properties.getValue("hourHandBehavior");
      if (configHourHandBehavior == null) {
        configHourHandBehavior = 0;
      }

      configBatteryDisplayMode = Properties.getValue("batteryDisplayMode");
      if (configBatteryDisplayMode == null) {
        configBatteryDisplayMode = 0;
      }

      configMessageFieldType = Properties.getValue("messageFieldType");
      if (configMessageFieldType == null) {
        configMessageFieldType = 0;
      }

      configDateFieldType = Properties.getValue("dateFieldType");
      if (configDateFieldType == null) {
        configDateFieldType = 0;
      }

      configColorScheme = Properties.getValue("colorScheme");
      if (configColorScheme == null) {
        configColorScheme = 0;
      }

      configCalorieGoalOverall = Properties.getValue("calorieGoalOverall");
      if (configCalorieGoalOverall == null) {
        configCalorieGoalOverall = 2400;
      }

      configCalorieGoalActive = Properties.getValue("calorieGoalActive");
      if (configCalorieGoalActive == null) {
        configCalorieGoalActive = 750;
      }

      // Load visibility properties
      showTopField = Properties.getValue("showTopField");
      if (showTopField == null) {
        showTopField = 1;
      }

      showMiddleGauge = Properties.getValue("showMiddleGauge");
      if (showMiddleGauge == null) {
        showMiddleGauge = 1;
      }

      showBottomField = Properties.getValue("showBottomField");
      if (showBottomField == null) {
        showBottomField = 1;
      }

      showMinuteHand = Properties.getValue("showMinuteHand");
      if (showMinuteHand == null) {
        showMinuteHand = 1;
      }

      System.println(
        "Config loaded - Battery: " +
          configBatteryDisplayMode +
          ", Hand: " +
          configHourHandBehavior
      );
    } catch (ex) {
      // Fallback to defaults if Properties access fails
      System.println(
        "Properties failed, using defaults: " + ex.getErrorMessage()
      );
      loadDefaultConfiguration();
    }

    // Validate configuration values
    validateConfiguration();
  }

  // Fallback function to load default configuration values
  function loadDefaultConfiguration() {
    configHourHandBehavior = 0;
    configBatteryDisplayMode = 0;
    configMessageFieldType = 0;
    configDateFieldType = 0;
    configColorScheme = 0;
    configCalorieGoalOverall = 2400;
    configCalorieGoalActive = 750;
    // Default visibility - all elements shown
    showTopField = 1;
    showMiddleGauge = 1;
    showBottomField = 1;
    showMinuteHand = 1;
    System.println("Default configuration loaded");
  }

  // Validate configuration values are within expected ranges
  function validateConfiguration() {
    if (configBatteryDisplayMode < 0 || configBatteryDisplayMode > 5) {
      configBatteryDisplayMode = 0;
    }
    if (configHourHandBehavior < 0 || configHourHandBehavior > 1) {
      configHourHandBehavior = 0;
    }
    if (configMessageFieldType < 0 || configMessageFieldType > 5) {
      configMessageFieldType = 0;
    }
    if (configDateFieldType < 0 || configDateFieldType > 5) {
      configDateFieldType = 0;
    }
    if (configColorScheme < 0 || configColorScheme > 1) {
      configColorScheme = 0;
    }
    if (configCalorieGoalOverall < 1000 || configCalorieGoalOverall > 5000) {
      configCalorieGoalOverall = 2400;
    }
    if (configCalorieGoalActive < 200 || configCalorieGoalActive > 2000) {
      configCalorieGoalActive = 750;
    }
    // Visibility properties validation (1=show, 0=hide)
    if (showTopField < 0 || showTopField > 1) {
      showTopField = 1;
    }
    if (showMiddleGauge < 0 || showMiddleGauge > 1) {
      showMiddleGauge = 1;
    }
    if (showBottomField < 0 || showBottomField > 1) {
      showBottomField = 1;
    }
    if (showMinuteHand < 0 || showMinuteHand > 1) {
      showMinuteHand = 1;
    }
  }

  // Configure the layout of the watchface for this device
  function onLayout(dc) {
    // If this device supports BufferedBitmap, allocate the buffers we use for drawing
    if (Toybox.Graphics has :createBufferedBitmap) {
      // Allocate a full screen size buffer with a palette of only 4 colors to draw
      // the background image of the watchface.  This is used to facilitate blanking
      // the second hand during partial updates of the display
      offscreenBuffer = Graphics.createBufferedBitmap({
        :width => dc.getWidth(),
        :height => dc.getHeight(),
        :palette => [
          Graphics.COLOR_DK_GRAY,
          Graphics.COLOR_LT_GRAY,
          Graphics.COLOR_BLACK,
          Graphics.COLOR_WHITE,
          Graphics.COLOR_ORANGE,
          Graphics.COLOR_YELLOW,
          Graphics.COLOR_GREEN,
          Graphics.COLOR_RED,
          Graphics.COLOR_BLUE,
        ],
      }).get();

      // Allocate a buffer tall enough to draw the date into the full width of the
      // screen. This buffer is also used for blanking the second hand. This full
      // color buffer is needed because anti-aliased fonts cannot be drawn into
      // a buffer with a reduced color palette
      dateBuffer = Graphics.createBufferedBitmap({
        :width => dc.getWidth(),
        :height => Graphics.getFontHeight(Graphics.FONT_MEDIUM),
      }).get();
      notificationBuffer = Graphics.createBufferedBitmap({
        :width => dc.getWidth(),
        :height => Graphics.getFontHeight(Graphics.FONT_MEDIUM),
      }).get();
    } else {
      offscreenBuffer = null;
    }

    curClip = null;

    screenCenterPoint = [dc.getWidth() / 2, dc.getHeight() / 2];

    // Initialize responsive layout configuration
    layoutConfig = createLayoutConfig(dc.getWidth(), dc.getHeight());
    msgCountMultiplier = layoutConfig[:msgCountMultiplier];

    // Load user configuration settings
    loadConfiguration();
  }

  // This function is used to generate the coordinates of the 4 corners of the polygon
  // used to draw a watch hand. The coordinates are generated with specified length,
  // tail length, and width and rotated around the center point at the provided angle.
  // 0 degrees is at the 12 o'clock position, and increases in the clockwise direction.
  function generateHandCoordinates(
    centerPoint,
    angle,
    handLength,
    tailLength,
    width
  ) {
    // Map out the coordinates of the watch hand
    var coords = [
      [-(width / 2), tailLength],
      [-(width / 2), -handLength],
      [width / 2, -handLength],
      [width / 2, tailLength],
    ];
    var result = new [4];
    var cos = Math.cos(angle);
    var sin = Math.sin(angle);

    // Transform the coordinates
    for (var i = 0; i < 4; i += 1) {
      var x = coords[i][0] * cos - coords[i][1] * sin + 0.5;
      var y = coords[i][0] * sin + coords[i][1] * cos + 0.5;

      result[i] = [centerPoint[0] + x, centerPoint[1] + y];
    }

    return result;
  }

  function generateHourCoordinates(
    centerPoint,
    angle,
    handLength,
    tailLength,
    width
  ) {
    // Map out the coordinates of the watch hand
    var coords = [
      [-(width / 2), -handLength],
      [width / 2, -handLength],
      [0, tailLength],
    ];
    var result = new [3];
    var cos = Math.cos(angle);
    var sin = Math.sin(angle);

    // Transform the coordinates
    for (var i = 0; i < 3; i += 1) {
      var x = coords[i][0] * cos - coords[i][1] * sin + 0.5;
      var y = coords[i][0] * sin + coords[i][1] * cos + 0.5;

      result[i] = [centerPoint[0] + x, centerPoint[1] + y];
    }

    return result;
  }

  // Draws the clock tick marks around the outside edges of the screen.
  function drawHashMarks(dc, one, two, length) {
    var width = dc.getWidth();

    // Set pen width to 2 pixels for thicker segment lines
    dc.setPenWidth(2);

    var sX, sY;
    var eX, eY;
    var outerRad = width / 2;
    var innerRad = outerRad - length;
    // Loop through each 15 minute block and draw tick marks.
    for (var i = Math.PI; i <= one * Math.PI; i += Math.PI) {
      // Partially unrolled loop to draw two tickmarks in 15 minute block.
      sY = outerRad + innerRad * Math.sin(i);
      eY = outerRad + outerRad * Math.sin(i);
      sX = outerRad + innerRad * Math.cos(i);
      eX = outerRad + outerRad * Math.cos(i);
      dc.drawLine(sX, sY, eX, eY);

      i += Math.PI / two;
      sY = outerRad + innerRad * Math.sin(i);
      eY = outerRad + outerRad * Math.sin(i);
      sX = outerRad + innerRad * Math.cos(i);
      eX = outerRad + outerRad * Math.cos(i);
      dc.drawLine(sX, sY, eX, eY);
    }

    // Reset pen width to default for other drawing operations
    dc.setPenWidth(1);
  }

  function drawBattery(targetDc, width, height) {
    // All modes now use the same gauge visual with different data sources
    drawBatteryGauge(targetDc, width, height);
  }

  function drawBatteryGauge(targetDc, width, height) {
    var percentage, useMultiColor;

    if (configBatteryDisplayMode == 0) {
      // Battery mode - multi-colored
      var stats = System.getSystemStats();
      percentage = (stats.battery + 0.5).toNumber();
      useMultiColor = true;
    } else if (configBatteryDisplayMode == 1) {
      // Steps progress - single green
      percentage = getStepsProgress();
      useMultiColor = false;
    } else if (configBatteryDisplayMode == 2) {
      // Weekly active minutes - single green
      percentage = getWeeklyActiveMinutesProgress();
      useMultiColor = false;
    } else if (configBatteryDisplayMode == 3) {
      // Stairs progress - single green
      percentage = getStairsProgress();
      useMultiColor = false;
    } else if (configBatteryDisplayMode == 4) {
      // Calories progress - single green
      percentage = getCaloriesProgress();
      useMultiColor = false;
    } else {
      // Active calories progress - single green (mode 5)
      percentage = getActiveCaloriesProgress();
      useMultiColor = false;
    }

    drawGaugeWithData(targetDc, width, height, percentage, useMultiColor);
  }

  function drawGaugeWithData(
    targetDc,
    width,
    height,
    percentage,
    useMultiColor
  ) {
    var battLeft = layoutConfig[:batteryLeft];
    var battRight = layoutConfig[:batteryRight];
    var battRange = battRight - battLeft;
    var battRangeSteps = battRange / 10.0; // Use float for precise calculation
    var battBaseHeight = layoutConfig[:batteryHeight];

    // Set pen width to 2 pixels for thicker battery gauge lines
    targetDc.setPenWidth(2);

    // Draw exactly 11 gauge lines (0%, 10%, 20%, ..., 100%)
    var gaugeLineColor = getBatteryGaugeColor();
    for (var i = 0; i <= 10; i++) {
      var xPos = battLeft + i * battRangeSteps;
      targetDc.setColor(gaugeLineColor, gaugeLineColor);
      targetDc.drawLine(
        xPos,
        battBaseHeight,
        xPos,
        battBaseHeight + layoutConfig[:batteryBarHeight]
      );
    }

    // Reset pen width to default for other drawing operations
    targetDc.setPenWidth(1);

    // Draw indicator dot
    var indicatorColor;
    if (useMultiColor) {
      // Battery mode - theme-aware multi-color based on percentage and charging state
      var stats = System.getSystemStats();
      if (stats.charging == true) {
        indicatorColor = getBlueColor();
      } else if (percentage <= 10) {
        indicatorColor = getRedColor();
      } else if (percentage <= 20) {
        indicatorColor = getYellowColor();
      } else {
        indicatorColor = getGreenColor();
      }
    } else {
      // All progress modes - theme-aware green color
      indicatorColor = getGreenColor();
    }

    targetDc.setColor(indicatorColor, indicatorColor);
    targetDc.fillCircle(
      battLeft + battRangeSteps * (percentage / 10.0),
      battBaseHeight + (layoutConfig[:batteryBarHeight] / 2),
      layoutConfig[:batteryRadius]
    );
  }

  // Data retrieval functions for different gauge modes
  function getStepsProgress() {
    var info = ActivityMonitor.getInfo();
    if (
      info.steps != null &&
      info has :stepGoal &&
      info.stepGoal != null &&
      info.stepGoal > 0
    ) {
      var progress = (
        (info.steps.toFloat() / info.stepGoal.toFloat()) *
        100
      ).toNumber();
      return progress > 100 ? 100 : progress;
    }
    return 0;
  }

  function getWeeklyActiveMinutesProgress() {
    var info = ActivityMonitor.getInfo();
    if (
      info has :activeMinutesWeek &&
      info.activeMinutesWeek != null &&
      info has :activeMinutesWeekGoal &&
      info.activeMinutesWeekGoal != null
    ) {
      var current = info.activeMinutesWeek.total;
      var goal = info.activeMinutesWeekGoal;
      if (goal > 0) {
        var progress = ((current.toFloat() / goal.toFloat()) * 100).toNumber();
        return progress > 100 ? 100 : progress;
      }
    }
    return 0;
  }

  function getStairsProgress() {
    var info = ActivityMonitor.getInfo();
    if (
      info has :floorsClimbed &&
      info.floorsClimbed != null &&
      info has :floorsClimbedGoal &&
      info.floorsClimbedGoal != null
    ) {
      var current = info.floorsClimbed;
      var goal = info.floorsClimbedGoal;
      if (goal > 0) {
        var progress = ((current.toFloat() / goal.toFloat()) * 100).toNumber();
        return progress > 100 ? 100 : progress;
      }
    }
    return 0;
  }

  function getCaloriesProgress() {
    var info = ActivityMonitor.getInfo();
    if (
      info has :calories &&
      info.calories != null &&
      configCalorieGoalOverall > 0
    ) {
      var progress = (
        (info.calories.toFloat() / configCalorieGoalOverall.toFloat()) *
        100
      ).toNumber();
      return progress > 100 ? 100 : progress;
    }
    return 0;
  }

  function getActiveCaloriesProgress() {
    var info = ActivityMonitor.getInfo();
    if (
      info has :caloriesActive &&
      info.caloriesActive != null &&
      configCalorieGoalActive > 0
    ) {
      var progress = (
        (info.caloriesActive.toFloat() / configCalorieGoalActive.toFloat()) *
        100
      ).toNumber();
      return progress > 100 ? 100 : progress;
    }
    return 0;
  }

  // Theme-aware color helper functions
  function getBackgroundColor() {
    return configColorScheme == 1 ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
  }

  function getTextColor() {
    return configColorScheme == 1 ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE;
  }

  function getMinuteHandColor() {
    return configColorScheme == 1 ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE;
  }

  function getArborColor(moveBarLevel) {
    if (moveBarLevel > ActivityMonitor.MOVE_BAR_LEVEL_MIN) {
      return getRedColor(); // Theme-aware red for move bar
    }
    return configColorScheme == 1
      ? Graphics.COLOR_BLACK
      : Graphics.COLOR_LT_GRAY;
  }

  function getHourHashColor() {
    return configColorScheme == 1 ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE;
  }

  function getMinuteHashColor() {
    return configColorScheme == 1
      ? Graphics.COLOR_DK_GRAY
      : Graphics.COLOR_LT_GRAY;
  }

  function getBatteryGaugeColor() {
    return configColorScheme == 1 ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE;
  }

  function getHourHandColor(bt_connected) {
    if (bt_connected) {
      return Graphics.COLOR_ORANGE; // Orange when connected in both themes
    } else {
      // When disconnected, use theme-appropriate gray
      return configColorScheme == 1
        ? Graphics.COLOR_DK_GRAY
        : Graphics.COLOR_LT_GRAY;
    }
  }

  // Theme-aware status colors for better light mode aesthetics
  function getGreenColor() {
    return configColorScheme == 1
      ? Graphics.COLOR_DK_GREEN
      : Graphics.COLOR_GREEN; // Dark green in light mode
  }

  function getRedColor() {
    return configColorScheme == 1 ? Graphics.COLOR_DK_RED : Graphics.COLOR_RED; // Dark red in light mode
  }

  function getYellowColor() {
    return configColorScheme == 1
      ? Graphics.COLOR_ORANGE
      : Graphics.COLOR_YELLOW; // Orange in light mode (better contrast than yellow)
  }

  function getBlueColor() {
    return configColorScheme == 1
      ? Graphics.COLOR_DK_BLUE
      : Graphics.COLOR_BLUE; // Dark blue in light mode
  }

  function drawString(myString, dc, posX, posY, color) {
    dc.setColor(color, Graphics.COLOR_TRANSPARENT);
    dc.drawText(
      posX,
      posY,
      Graphics.FONT_SMALL,
      myString,
      Graphics.TEXT_JUSTIFY_CENTER
    );
  }

  function drawNotificationCount(dc, posX, posY) {
    var displayValue = null;
    var displayStr = "";

    if (configMessageFieldType == 1) {
      // Steps
      var info = ActivityMonitor.getInfo();
      if (info.steps != null) {
        displayValue = info.steps;
        displayStr = displayValue.toString();
      }
    } else if (configMessageFieldType == 2) {
      // Heart Rate
      var info = Activity.getActivityInfo();
      if (info != null && info.currentHeartRate != null) {
        displayValue = info.currentHeartRate;
        displayStr = displayValue.toString();
      }
    } else if (configMessageFieldType == 3) {
      // Battery Percentage
      var battery = (System.getSystemStats().battery + 0.5).toNumber();
      displayValue = battery;
      displayStr = battery.toString();
    } else if (configMessageFieldType == 4) {
      // Calories
      var info = ActivityMonitor.getInfo();
      if (info has :calories && info.calories != null) {
        displayValue = info.calories;
        displayStr = displayValue.toString();
      }
    } else if (configMessageFieldType == 5) {
      // Active Calories
      var info = ActivityMonitor.getInfo();
      if (info has :caloriesActive && info.caloriesActive != null) {
        displayValue = info.caloriesActive;
        displayStr = displayValue.toString();
      }
    } else {
      // Default: Notifications (0)
      var notificationCount = System.getDeviceSettings().notificationCount;
      if (notificationCount != null && notificationCount > 0) {
        displayValue = notificationCount;
        displayStr = notificationCount.toString();
      }
    }

    if (displayValue != null && displayStr.length() > 0) {
      drawString(displayStr, dc, posX, posY, getTextColor());
    }
  }

  function drawHourHand(targetDc) {
    var hourHandAngle;
    var width = targetDc.getWidth();
    var clockTime = System.getClockTime();

    //We have BT?
    var deviceSettings = System.getDeviceSettings();
    bt_connected = deviceSettings.phoneConnected;
    var colorHourHand = null;
    // Used to align the hour hand triangle according to
    // the screen size. Responsive calculation replaces hardcoded 1.714
    var hourModifier = layoutConfig[:hourHandLength];

    var hourTail = width - hourModifier;

    colorHourHand = getHourHandColor(bt_connected);

    //Use theme-aware color to draw the hour hand
    targetDc.setColor(colorHourHand, Graphics.COLOR_TRANSPARENT);

    // Draw the hour hand with configurable behavior
    if (configHourHandBehavior == 1) {
      // Discrete hourly jumps - ignore minutes
      hourHandAngle = (clockTime.hour % 12) * 60;
    } else {
      // Smooth continuous movement - include minutes
      hourHandAngle = (clockTime.hour % 12) * 60 + clockTime.min;
    }
    hourHandAngle = hourHandAngle / (12 * 60.0);
    hourHandAngle = hourHandAngle * Math.PI * 2;

    targetDc.fillPolygon(
      generateHourCoordinates(
        screenCenterPoint,
        hourHandAngle,
        width,
        -hourTail,
        layoutConfig[:hourHandWidth]
      )
    );
  }

  function drawArbor(targetDc) {
    var width = targetDc.getWidth();
    var height = targetDc.getHeight();
    var moveBarLevel = ActivityMonitor.getInfo().moveBarLevel;

    if (moveBarLevel == null) {
      moveBarLevel = 0;
    }

    var arborColor = getArborColor(moveBarLevel);
    var backgroundColor = getBackgroundColor();

    // Draw the arbor in the center of the screen.
    var arborRadius = layoutConfig[:arborRadius];
    targetDc.setColor(arborColor, backgroundColor);
    targetDc.fillCircle(width / 2, height / 2, arborRadius);
    targetDc.setColor(backgroundColor, backgroundColor);
    targetDc.drawCircle(width / 2, height / 2, arborRadius);
  }

  // Handle the update event
  function onUpdate(dc) {
    var width;
    var height;
    var clockTime = System.getClockTime();
    var minuteHandAngle;
    var targetDc = null;

    // We always want to refresh the full screen when we get a regular onUpdate call.
    fullScreenRefresh = true;

    if (null != offscreenBuffer) {
      dc.clearClip();
      curClip = null;
      // If we have an offscreen buffer that we are using to draw the background,
      // set the draw context of that buffer as our target.
      targetDc = offscreenBuffer.getDc();
    } else {
      targetDc = dc;
    }

    width = targetDc.getWidth();
    height = targetDc.getHeight();

    // Fill the entire background based on color scheme.
    var backgroundColor = getBackgroundColor();
    targetDc.setColor(backgroundColor, backgroundColor);
    targetDc.fillRectangle(0, 0, dc.getWidth(), dc.getHeight());

    // Draw Hour and Minute Ticks
    var hourHashColor = getHourHashColor();
    targetDc.setColor(hourHashColor, hourHashColor);
    drawHashMarks(targetDc, 12, 6, layoutConfig[:hourHashLength]);
    var minuteHashColor = getMinuteHashColor();
    targetDc.setColor(minuteHashColor, minuteHashColor);
    drawHashMarks(targetDc, 31, 30, layoutConfig[:minuteHashLength]);

    if (showMiddleGauge == 1) {
      drawBattery(targetDc, width, height);
    }
    drawHourHand(targetDc);

    if (showMinuteHand == 1) {
      targetDc.setColor(getMinuteHandColor(), Graphics.COLOR_TRANSPARENT);
      //draw minute hand
      minuteHandAngle = (clockTime.min / 60.0) * Math.PI * 2;
      var minuteHandLength = width * layoutConfig[:minuteHandLengthRatio];
      targetDc.fillPolygon(
        generateHandCoordinates(
          screenCenterPoint,
          minuteHandAngle,
          minuteHandLength,
          layoutConfig[:minuteTailLength],
          layoutConfig[:minuteHandWidth]
        )
      );

      drawArbor(targetDc);
    }

    // If we have an offscreen buffer that we are using for the date string,
    // Draw the date into it. If we do not, the date will get drawn every update
    // after blanking the second hand.
    if (null != dateBuffer) {
      var dateDc = dateBuffer.getDc();

      //Draw the background image buffer into the date buffer to set the background
      dateDc.drawBitmap(
        0,
        -(height * layoutConfig[:dateOffsetRatio]),
        offscreenBuffer
      );

      //Draw the date string into the buffer.
      if (showTopField == 1) {
        drawDateString(dateDc, width / 2, 0);
      }
    }

    if (null != notificationBuffer) {
      var notificationDc = notificationBuffer.getDc();
      notificationDc.drawBitmap(
        0,
        -(height * layoutConfig[:notificationOffsetRatio]),
        offscreenBuffer
      );
      if (showBottomField == 1) {
        drawNotificationCount(notificationDc, width / 2, 0);
      }
    }

    // Output the offscreen buffers to the main display if required.
    drawBackground(dc);

    fullScreenRefresh = false;
  }

  // Draw the date string into the provided buffer at the specified location
  function drawDateString(dc, x, y) {
    var displayStr = "";

    if (configDateFieldType == 1) {
      // Steps
      var info = ActivityMonitor.getInfo();
      if (info.steps != null) {
        displayStr = info.steps.toString();
      }
    } else if (configDateFieldType == 2) {
      // Heart Rate
      var info = Activity.getActivityInfo();
      if (info != null && info.currentHeartRate != null) {
        displayStr = info.currentHeartRate.toString();
      }
    } else if (configDateFieldType == 3) {
      // Battery Percentage
      var battery = (System.getSystemStats().battery + 0.5).toNumber();
      displayStr = battery.toString();
    } else if (configDateFieldType == 4) {
      // Calories
      var info = ActivityMonitor.getInfo();
      if (info has :calories && info.calories != null) {
        displayStr = info.calories.toString();
      }
    } else if (configDateFieldType == 5) {
      // Active Calories
      var info = ActivityMonitor.getInfo();
      if (info has :caloriesActive && info.caloriesActive != null) {
        displayStr = info.caloriesActive.toString();
      }
    } else {
      // Default: Date (0)
      var info = Gregorian.info(Time.now(), Time.FORMAT_LONG);
      displayStr = Lang.format("$1$", [info.day]);
    }

    if (displayStr.length() > 0) {
      dc.setColor(getTextColor(), Graphics.COLOR_TRANSPARENT);
      dc.drawText(
        x,
        y,
        Graphics.FONT_SMALL,
        displayStr,
        Graphics.TEXT_JUSTIFY_CENTER
      );
    }
  }

  // Compute a bounding box from the passed in points
  function getBoundingBox(points) {
    var min = [9999, 9999];
    var max = [0, 0];

    for (var i = 0; i < points.size(); ++i) {
      if (points[i][0] < min[0]) {
        min[0] = points[i][0];
      }

      if (points[i][1] < min[1]) {
        min[1] = points[i][1];
      }

      if (points[i][0] > max[0]) {
        max[0] = points[i][0];
      }

      if (points[i][1] > max[1]) {
        max[1] = points[i][1];
      }
    }

    return [min, max];
  }

  // Draw the watch face background
  // onUpdate uses this method to transfer newly rendered Buffered Bitmaps
  // to the main display.
  // onPartialUpdate uses this to blank the second hand from the previous
  // second before outputing the new one.
  function drawBackground(dc) {
    var width = dc.getWidth();
    var height = dc.getHeight();

    //If we have an offscreen buffer that has been written to
    //draw it to the screen.
    if (null != offscreenBuffer) {
      dc.drawBitmap(0, 0, offscreenBuffer);
    }

    // Draw the date
    if (showTopField == 1) {
      if (null != dateBuffer) {
        // If the date is saved in a Buffered Bitmap, just copy it from there.
        dc.drawBitmap(0, height * layoutConfig[:dateOffsetRatio], dateBuffer);
      } else {
        // Otherwise, draw it from scratch.
        drawDateString(dc, width / 2, height * layoutConfig[:dateOffsetRatio]);
      }
    }

    if (showBottomField == 1) {
      if (null != notificationBuffer) {
        dc.drawBitmap(
          0,
          height * layoutConfig[:notificationOffsetRatio],
          notificationBuffer
        );
      } else {
        drawNotificationCount(
          dc,
          width / 2,
          height * layoutConfig[:notificationOffsetRatio]
        );
      }
    }
  }

  // This method is called when the device re-enters sleep mode.
  // Set the isAwake flag to let onUpdate know it should stop rendering the second hand.
  function onEnterSleep() {
    isAwake = false;
    WatchUi.requestUpdate();
  }

  // This method is called when the device exits sleep mode.
  // Set the isAwake flag to let onUpdate know it should render the second hand.
  function onExitSleep() {
    isAwake = true;
  }
}

class MnmlstDelegate extends WatchUi.WatchFaceDelegate {
  function initialize() {
    WatchFaceDelegate.initialize();
  }
  // The onPowerBudgetExceeded callback is called by the system if the
  // onPartialUpdate method exceeds the allowed power budget. If this occurs,
  // the system will stop invoking onPartialUpdate each second, so we set the
  // partialUpdatesAllowed flag here to let the rendering methods know they
  // should not be rendering a second hand.
  function onPowerBudgetExceeded(powerInfo) {
    System.println("Average execution time: " + powerInfo.executionTimeAverage);
    System.println("Allowed execution time: " + powerInfo.executionTimeLimit);
    partialUpdatesAllowed = false;
  }
}
