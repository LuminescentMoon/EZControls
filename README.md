# EZControls
A stateful LÖVE controls library providing a callback-style API for key events by name along with configuration support.

## Example
```lua

-- Load the library.
local controls = require('EZControls-compiled')

-- Set the controls library state
controls.currentState = 'game'

-- Setup keybinds using a table.
controls.parse({
  all = {
    pause = {'escape'}
  },
  game = {
    shoot = {'up', 'w'},
    keyMashingButton = {' '}
  }
})

-- Get the binding in the state "game" by the name "shoot" and register a callback for the onPress event.
controls.state('game').binding('shoot'):onPress(function()
  startShooting()
end)

-- Get the binding in the state "game" by the name "shoot" and register a callback for the onRelease event.
controls.state('game').binding('shoot'):onRelease(function()
  stopShooting()
end)

controls.state('all').binding('pause'):onPress(function()
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

controls.mouse:onMove(function(x, y, deltaX, deltaY)
  print(x, y, deltaX, deltaY)
end)

-- You can pass a boolean as a second argument to binding:onPress to determine whether or not to trigger on key repeats. Set to true to trigger on repeats. Defaults to false.
controls.state('game').binding('keyMashingButton'):onPress(function()
  aRepeatableAction()
end, true)

-- Programmatically bind and unbind keys. The functions accept both a list of keys to bind/unbind as an array or just one key as a string.
controls.state('game').binding('pause'):bind('q')
controls.state('game').binding('pause'):unbind({'q', 'escape'})
```
