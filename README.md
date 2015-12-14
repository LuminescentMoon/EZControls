# EZControls
A stateful LÖVE controls library providing a callback-style API for key events by name along with configuration support.

## Installation
Simply git clone this project into your preferred library folder and require the project folder itself. Make sure to use ```--recursive``` when cloning so that you grab the dependencies as well.

So if you cloned the project into ```/home/Desktop/ub3rl33tg4m3/vendor```, the path would be ```/home/Desktop/ub3rl33tg4m3/vendor/EZControls```. If your main.lua is in ```/home/Desktop/ub3rl33tg4m3/```, you would then require it like so:
```lua
local controls = require('vendor.EZControls')
```

## TODO
- Remove dependency for love2d in the isDown binding object function.

## Example
```lua

-- Load the library.
local controls = require('EZControls')

-- Set the controls library state.
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

-- Get the binding in the state "game" by the name "shoot" and register
-- a callback for the onPress event.
controls.state('game').binding('shoot'):onPress(function()
  startShooting()
end)

-- Get the binding in the state "game" by the name "shoot" and register
-- a callback for the onRelease event.
controls.state('game').binding('shoot'):onRelease(function()
  stopShooting()
end)

controls.state('all').binding('pause'):onPress(function()
  pauseGame()
end)

-- You can also do the traditional way of checking if a key is down, like so:
function love.update(deltaTime)
  if controls.state('game').binding('shoot'):isDown() then
    shootTick(deltaTime)
  end
end

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

-- You can pass a boolean as a second argument to binding:onPress to determine whether
-- or not to trigger on key repeats. Set to true to trigger on repeats. Defaults to false.
controls.state('game').binding('keyMashingButton'):onPress(function()
  aRepeatableAction()
end, true)

-- Programmatically bind and unbind keys. The functions accept both a list of keys
-- to bind/unbind as an array or just one key as a string.
controls.state('game').binding('pause'):bind('q')
controls.state('game').binding('pause'):unbind({'q', 'escape'})
```
You can also bind the next key pressed to a binding like so:
```lua
-- Load the library.
local controls = require('EZControls')

-- Set the controls library state.
controls.currentState = 'game'

 -- Binds the next key pressed to the binding "jetpack_fire".
controls.state('game').binding('jetpack_fire'):bindNext(function(key)
  print('binded ' .. key .. ' to binding "jetpack_fire"')
end)

-- Create callbacks for the bindings.
controls.state('game').binding('jetpack_fire'):onPress(function()
  enableJetpack()
end)

controls.state('game').binding('jetpack_fire'):onRelease(function()
  disableJetpack()
end)
```
EZControls will check if love.keypressed, love.keyreleased, love.mousepressed, love.mousereleased, or love.mousemoved is already being used. If it isn't, it'll override them. If it is, it'll provide functions to fire control events to.
```lua
-- Override the love.keypressed function
function love.keypressed(key, isRepeat)
  if key == 'a' then
    print('ayy')
  end
end

-- Load the library.
local controls = require('EZControls')

-- Set the controls library state.
controls.currentState = 'game'

-- Bind a function to the binding "test" in the state "game". Note that if the binding
-- or state does not exist in EZControl's keybinds, it'll make it automatically.
controls.state('game').binding('test'):onPress(function()
  print('lmao')
end)

-- Bind key "a" to binding "test" in state "game".
controls.state('game').binding('test'):bind('a')

--
-- Pressing "a" will never print "lmao" since the controls library never overriden
-- the love.keypressed function because it already detected a function there.
--

function love.keypressed(key, isRepeat)
  controls.fire.keyPressed(key, isRepeat)
end

function love.keyreleased(key)
  controls.fire.keyReleased(key)
end

function love.mousepressed(x, y, button)
  controls.fire.mousePressed(x, y, button)
end

function love.mousereleased(x, y, button)
  controls.fire.mouseReleased(x, y, button)
end

function love.mousemoved(x, y, deltaX, deltaY)
  controls.fire.mouseMove(x, y, deltaX, deltaY)
end

--
-- Now pressing "a" will print "ayy\nlmao" since we have used the standalone event functions.
--
```
### Saving keybinds
```lua
-- Load library
local controls = require('EZControls')

-- Make a few keybinds
controls.state('game').binding('player_left'):bind({'a', 'left'})
controls.state('game').binding('player_right'):bind({'d', 'right'})
controls.state('all').binding('quit'):bind('escape')

-- The internal keybinds representation would be this:

{
  game = {
    player_left = {
      keys = {'a', 'left'},
      onPressCallbacks = {},
      onReleaseCallbacks = {}
    },
    player_right = {
      keys = {'d', 'right'},
      onPressCallbacks = {},
      onReleaseCallbacks = {}
    },
  },
  all = {
    quit = {
      keys = {'escape'},
      onPressCallbacks = {},
      onReleaseCallbacks = {}
    }
  }
}

-- Now this is not exactly simple. So we use EZControls' built-in serialize function
-- to simplify it for saving.
local keybinds = controls.serialize()

-- The keybinds table representation would be this:

{
  game = {
    player_left = {'a', 'left'},
    player_right = {'d', 'right'},
  },
  all = {
    quit = {'escape'},
  }
}

-- And to load the keybinds table:
controls.parse(keybinds)
```
