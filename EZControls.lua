-- ezcontrols.lua - v0.1.0
-- © 2015 Howard Nguyen
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

--------------------------------------------------------------------------------------------------
-- Dependencies
--------------------------------------------------------------------------------------------------

local type = type
local setmetatable = setmetatable
local pairs = pairs
local table = {
  insert = table.insert
}
local error = error
local love = love

--------------------------------------------------------------------------------------------------
-- Utility Functions
--------------------------------------------------------------------------------------------------

local tableContains = function(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end

local tableConcat = function(t1, t2)
  for i=1,#t2 do
      t1[#t1+1] = t2[i]
  end
  return t1
end

--------------------------------------------------------------------------------------------------
-- Main Object
--------------------------------------------------------------------------------------------------

local controls = {
  bindings = {},
  keyObjects = {},
  state = nil
}

--------------------------------------------------------------------------------------------------
-- Binding Object
--------------------------------------------------------------------------------------------------

local binding = {--[[
  stateRequired = nil,
  keys = {},
  onPressCallbacks = {},
  onReleaseCallbacks = {}
]]}
binding.__index = binding

function binding:onPress(function_callback, listenToRepeat)
  table.insert(self.onPressCallbacks, {
    func = function_callback,
    listenToRepeat = listenToRepeat or false
  })
end

function binding:onRelease(function_callback)
  table.insert(self.onReleaseCallbacks, function_callback)
end

function binding:bind(key)
  if type(key) == 'table' then
    tableConcat(self.keys, key)
  else
    table.insert(self.keys, key)
  end
end

--------------------------------------------------------------------------------------------------
-- Private Methods
--------------------------------------------------------------------------------------------------

local function createBinding(bindingName)
   local newBinding = setmetatable({
    stateRequired = nil,
    keys = {},
    onPressCallbacks = {},
    onReleaseCallbacks = {}
  }, binding)

  controls.bindings[bindingName] = newBinding

  return newBinding
end

local function bindingExists(bindingName)
  return (type(controls.bindings[bindingName]) == 'table')
end

local function returnBindingOrNew(bindingName)
  local workingBinding, isNew = nil, false
    if bindingExists(bindingName) then
      workingBinding = controls.bindings[bindingName]
    else
      workingBinding = createBinding(bindingName)
      isNew = true
    end
  return workingBinding, isNew
end

--------------------------------------------------------------------------------------------------
-- Public Methods
--------------------------------------------------------------------------------------------------

function controls.bind(keys, bindingName)
  local workingBinding = returnBindingOrNew(bindingName)
  workingBinding:bind(keys)
  return workingBinding
end

function controls.binding(bindingName)
  return (returnBindingOrNew(bindingName))
end

function controls.parse(table)
  for state, bindings in pairs(table) do
    for bindingName, keys in pairs(bindings) do
      local workingBinding, isNew = returnBindingOrNew(bindingName)

      if not isNew then
        if not workingBinding.stateRequired == nil then
          if not workingBinding.stateRequired == state then
            error('binding name "' .. bindingName .. '" in state "' .. state .. '" is not unique')
          end
        else
          workingBinding.stateRequired = state
        end
      end

      workingBinding:bind(keys)
    end
  end
end

--------------------------------------------------------------------------------------------------
-- Mouse Object
--------------------------------------------------------------------------------------------------
local mouse = {}

mouse.physics = {
  secondLastPosition = {
    x = 0,
    y = 0
  },
  lastPosition = {
    x = 0,
    y = 0
  },
  onMoveCallbacks = {}
}

function mouse.physics:onMove(function_callback)
  table.insert(self.onMoveCallbacks, function_callback)
end

-- Simple syntactical sugar.
mouse.leftButton = controls.bind('mouse_l', 'mouse_l')
mouse.middleButton = controls.bind('mouse_m', 'mouse_m')
mouse.rightButton = controls.bind('mouse_r', 'mouse_r')
mouse.mouseWheel = {}
mouse.mouseWheel.up = controls.bind('mouse_wu', 'mouse_wu')
mouse.mouseWheel.down = controls.bind('mouse_wd', 'mouse_wd')

controls.mouse = mouse

--------------------------------------------------------------------------------------------------
-- Love2D Callbacks Handlers
--------------------------------------------------------------------------------------------------

love.keyboard.setKeyRepeat(true)

function love.keypressed(key, isRepeat, x, y)
  for _, bindingProps in pairs(controls.bindings) do
    if tableContains(bindingProps.keys, key) and (bindingProps.stateRequired == controls.state or bindingProps.stateRequired == nil) then
      for _, callback in pairs(bindingProps.onPressCallbacks) do
        if not (callback.listenToRepeat or isRepeat) then
          callback.func(x, y)
        end
      end
    end
  end
end

function love.keyreleased(key, x, y)
  for _, bindingProps in pairs(controls.bindings) do
    if tableContains(bindingProps.keys, key) and (bindingProps.stateRequired == controls.state or bindingProps.stateRequired == nil) then
      for i = 1, #bindingProps.onReleaseCallbacks do
        bindingProps.onReleaseCallbacks[i](x, y)
      end
    end
  end
end

function love.mousepressed(x, y, button)
  love.keypressed('mouse_' .. button, false, x, y)
end

function love.mousereleased(x, y, button)
  love.keyreleased('mouse_' .. button, x, y)
end

function love.mousemoved(x, y, deltaX, deltaY) -- TODO: Maybe implement state awareness.
  for _, callback in pairs(mouse.physics.onMoveCallbacks) do
    callback(x, y, deltaX, deltaY)
  end
end

return controls
