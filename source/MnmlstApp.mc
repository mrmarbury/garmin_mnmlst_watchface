//
// Copyright 2016-2017 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

using Toybox.Application;
using Toybox.WatchUi;
using Toybox.Time;

// This is the primary entry point of the application.
class Mnmlst extends Application.AppBase {
  function initialize() {
    AppBase.initialize();
  }

  function onStart(state) {}

  function onStop(state) {}

  // This method is called when the user changes settings
  function onSettingsChanged() {
    // Get the current view and reload its configuration
    var view = WatchUi.getCurrentView()[0];
    if (view != null && view has :loadConfiguration) {
      view.loadConfiguration();
    }
    WatchUi.requestUpdate();
  }

  // This method runs each time the main application starts.
  function getInitialView() {
    if (Toybox.WatchUi has :WatchFaceDelegate) {
      return [new MnmlstView(), new MnmlstDelegate()];
    } else {
      return [new MnmlstView()];
    }
  }
}
