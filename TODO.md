# TODO

## Features

 - [X] refactor code:
   - [x] remove unused code
 - [X] Support all round watches and round watches only. Exclude everything square, not supporting analog watch faces and the Instinct line
 - [] Make UI elements look the same across watches
   - the thing that I have in mind here is that depending on the screen and screen size the hour triangle, the battery gauge and the numbers look slightly different and are something also shifted. 
   - I have already put custom code for some watches in the code but there might be an automatic way to position and resize all elements depending on the screen.
   - HYPERTHINK about the possible solution, then implement it, write and execute tests for the new code and review the code.
   - [X] Phase 1: Create Responsive Layout Foundation
     - [X] Add screen density calculator - Calculate scale factor based on screen size vs reference resolution (260x260)
     - [X] Create layout configuration class - Centralize all positioning and sizing calculations
     - [X] Replace hardcoded values with proportional calculations
   - [X] Phase 2: Implement Adaptive UI Elements
     - [X] Hour hand triangle scaling - Replace hourModifier = width / 1.714 with proportional calculation
     - [X] Battery gauge responsive positioning - Scale battery bar size and position based on screen
     - [X] Notification positioning system - Replace msgCountMultiplier = 4.6 with calculated offset
     - [X] Hash mark adaptive sizing - Scale tick mark lengths (15px, 5px) proportionally
     - [X] Date positioning system - Calculate optimal date placement for each screen size
     - [X] Hand width scaling - Make minute/hour hand widths proportional to screen size
   - [X] Phase 3: Testing & Verification
     - [X] Write unit tests for scaling calculations and layout positioning
     - [X] Create mock screen size tests - Test layout on 208x208, 240x240, 260x260, 280x280, 390x390
     - [X] Integration tests for visual consistency across devices
     - [X] Manual verification on different device simulators
   - [X] Phase 4: Code Review & Optimization
     - [X] Performance review - Ensure calculations don't impact rendering performance
     - [X] Code quality review - Verify maintainability and readability
     - [X] Documentation - Add comments explaining the responsive system
 - [X] Make fields configurable
   - [X] implement a garmin config page to configure everything
   - [X] add config value to make hour triangle jump hourly only or move the regular way that's working already
   - [X] set goals for calories later used for the alternative battery bar gauge
     - [X] overall calories with default 2400
     - [X] active calories with default 750
   - [X] battery bar -> "goals" like steps, active minutes, and so on
   - [X] message count -> plain values like steps, hr, battery percentage, etc
   - [X] date -> plain values like steps, hr, battery percentage, etc
 - [X] Add white color scheme option (background white, orange hour, black minutes, black arbor, everything else that's white is now black)
 - [] bump version to next major version

## Bugs
