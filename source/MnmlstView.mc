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
using Toybox.Application;
using Toybox.ActivityMonitor;

var partialUpdatesAllowed = false;

// This implements an analog watch face
// Original design by Austen Harbour
class MnmlstView extends WatchUi.WatchFace {
  var font;
  var isAwake;
  var screenShape;
  var dndIcon;
  var offscreenBuffer;
  var dateBuffer;
  var notificationBuffer;
  var curClip;
  var screenCenterPoint;
  var fullScreenRefresh;
  var bt_connected = true;
  var msgCountMultiplier = 4.6;
  var watchfaceColors;

  // Initialize variables for this view
  function initialize() {
    WatchFace.initialize();
    screenShape = System.getDeviceSettings().screenShape;
    fullScreenRefresh = true;
    partialUpdatesAllowed = Toybox.WatchUi.WatchFace has :onPartialUpdate;
    watchfaceColors = MnmlstApp.Colors.DarkColors;
  }

  // Configure the layout of the watchface for this device
  function onLayout(dc) {
    // Load the custom font we use for drawing the 3, 6, 9, and 12 on the watchface.
    font = WatchUi.loadResource(Rez.Fonts.id_font_black_diamond);

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
    var height = dc.getHeight();

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
  }

  function drawBattery(targetDc, width, height) {
    var battery = (System.getSystemStats().battery + 0.5).toNumber();

    var battLeft = width / 4;
    var battRight = battLeft * 3;
    var battRange = battRight - battLeft;
    var battRangeSteps = battRange / 10;
    var battBaseHeight = (4 * height) / 6;
    var stats = System.getSystemStats();

    for (var i = battLeft; i <= battRight; i += battRangeSteps) {
      targetDc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
      targetDc.drawLine(i, battBaseHeight, i, battBaseHeight + 10);
      if (stats.charging == true) {
        targetDc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLUE);
      } else if (stats.battery <= 10) {
        targetDc.setColor(Graphics.COLOR_RED, Graphics.COLOR_RED);
      } else if (stats.battery <= 20) {
        targetDc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_YELLOW);
      } else {
        targetDc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_GREEN);
      }
      targetDc.fillCircle(
        battLeft + battRangeSteps * (battery / 10.0),
        battBaseHeight + 5,
        5
      );
    }
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
    var notificationCount = System.getDeviceSettings().notificationCount;

    if (notificationCount != null && notificationCount > 0) {
      drawString(notificationCount, dc, posX, posY, Graphics.COLOR_WHITE);
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
    var hourModifier = width / 1.714;

    var hourTail = width - hourModifier;

    if (bt_connected) {
      colorHourHand = Graphics.COLOR_ORANGE;
    } else {
      colorHourHand = Graphics.COLOR_LT_GRAY;
    }

    //Use white to draw the hour and minute hands
    targetDc.setColor(colorHourHand, Graphics.COLOR_TRANSPARENT);

    // Draw the hour hand.
    hourHandAngle = (clockTime.hour % 12) * 60 + clockTime.min;
    hourHandAngle = hourHandAngle / (12 * 60.0);
    hourHandAngle = hourHandAngle * Math.PI * 2;

    targetDc.fillPolygon(
      generateHourCoordinates(
        screenCenterPoint,
        hourHandAngle,
        width,
        -hourTail,
        160
      )
    );
  }

  function drawArbor(targetDc) {
    var width = targetDc.getWidth();
    var height = targetDc.getHeight();
    var arborColor = Graphics.COLOR_LT_GRAY;
    var moveBarLevel = ActivityMonitor.getInfo().moveBarLevel;

    if (moveBarLevel == null) {
      moveBarLevel = 0;
    }

    if (moveBarLevel > ActivityMonitor.MOVE_BAR_LEVEL_MIN) {
      arborColor = Graphics.COLOR_RED;
    }

    // Draw the arbor in the center of the screen.
    targetDc.setColor(arborColor, Graphics.COLOR_BLACK);
    targetDc.fillCircle(width / 2, height / 2, 7);
    targetDc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
    targetDc.drawCircle(width / 2, height / 2, 7);
  }

  // Handle the update event
  function onUpdate(dc) {
    var width;
    var height;
    var screenWidth = dc.getWidth();
    var clockTime = System.getClockTime();
    var minuteHandAngle;
    var targetDc = null;
    var hourTail;

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

    // Fill the entire background with Black.
    targetDc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
    targetDc.fillRectangle(0, 0, dc.getWidth(), dc.getHeight());

    // Draw Hour and Minute Ticks
    targetDc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
    drawHashMarks(targetDc, 12, 6, 15);
    targetDc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_LT_GRAY);
    drawHashMarks(targetDc, 31, 30, 5);

    drawBattery(targetDc, width, height);
    drawHourHand(targetDc);

    targetDc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    //drow minute hand
    minuteHandAngle = (clockTime.min / 60.0) * Math.PI * 2;
    targetDc.fillPolygon(
      generateHandCoordinates(screenCenterPoint, minuteHandAngle, width, 15, 2)
    );

    drawArbor(targetDc);

    // If we have an offscreen buffer that we are using for the date string,
    // Draw the date into it. If we do not, the date will get drawn every update
    // after blanking the second hand.
    if (null != dateBuffer) {
      var dateDc = dateBuffer.getDc();

      //Draw the background image buffer into the date buffer to set the background
      dateDc.drawBitmap(0, -(height / 4), offscreenBuffer);

      //Draw the date string into the buffer.
      drawDateString(dateDc, width / 2, 0);
    }

    if (null != notificationBuffer) {
      var notificationDc = notificationBuffer.getDc();
      notificationDc.drawBitmap(
        0,
        -(height / 6) * msgCountMultiplier,
        offscreenBuffer
      );
      drawNotificationCount(notificationDc, width / 2, 0);
    }

    // Output the offscreen buffers to the main display if required.
    drawBackground(dc);

    fullScreenRefresh = false;
  }

  // Draw the date string into the provided buffer at the specified location
  function drawDateString(dc, x, y) {
    var info = Gregorian.info(Time.now(), Time.FORMAT_LONG);
    var dateStr = Lang.format("$1$", [info.day]);

    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    dc.drawText(
      x,
      y,
      Graphics.FONT_SMALL,
      dateStr,
      Graphics.TEXT_JUSTIFY_CENTER
    );
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
    if (null != dateBuffer) {
      // If the date is saved in a Buffered Bitmap, just copy it from there.
      dc.drawBitmap(0, height / 4, dateBuffer);
    } else {
      // Otherwise, draw it from scratch.
      drawDateString(dc, width / 2, height / 4);
    }

    if (null != notificationBuffer) {
      dc.drawBitmap(0, (height / 6) * msgCountMultiplier, notificationBuffer);
    } else {
      drawNotificationCount(dc, width / 2, (height / 6) * msgCountMultiplier);
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
