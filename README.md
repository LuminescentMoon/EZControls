# EZControls
A stateful LÖVE controls library providing callbacks for key events by name along with configuration support.

```lua

-- Load the library.
local controls = require('EZControls-compiled')

-- Set the controls library state
controls.state = 'game'

-- Setup keybinds using a table.
controls.parse({
  game = {
    shoot = {'up', 'w'},
    pause = {'escape'},
    keyMashingButton = {' '}
  }
})

-- Get the binding by the name "shoot" and register a callback for the onPress event.
controls.binding('shoot'):onPress(function()
  startShooting()
end)

-- Get the binding by the name "shoot" and register a callback for the onRelease event.
controls.binding('shoot'):onRelease(function()
  stopShooting()
end)

controls.binding('pause'):onPress(function()
  pauseGame()
end)

-- The library includes syntactical sugar for the mouse buttons.
controls.mouse.leftButton:onPress(function()
  print('MOUSE LEFT PRESS')
end)

controls.mouse.middleButton:onRelease(function()
  print('MOUSE MIDDLE RELEASE')
end)

controls.mouse.rightButton:onPress(function()
  print('MOUSE RIGHT PRESS')
end)

controls.mouse.physics:onMove(function(x, y, deltaX, deltaY)
  print(x, y, deltaX, deltaY)
end)

-- You can pass a boolean as a second argument to binding:onPress to determine whether or not to trigger on key repeats. Set to true to trigger on repeats. Defaults to false.
controls.binding('keyMashingButton'):onPress(function()
  aRepeatableAction()
end, true)

```
