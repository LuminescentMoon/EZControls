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
-- Main Object
--------------------------------------------------------------------------------------------------

local controls = {
  _VERSION = '0.4.0',
  _DESCRIPTION = 'Callback style controls library for Lua.',
  _URL = 'https://github.com/Luminess/EZControls',

  states = {},
  _keystrokeListeners = {},
  currentState = nil
}

--------------------------------------------------------------------------------------------------
-- Dependencies
--------------------------------------------------------------------------------------------------

local rootDir = (...):gsub('%.[^%.]+$', '.')

local dkjson --= require(rootDir .. 'lib.dkjson.dkjson') We're lazy loading but leaving a comment just to show our intent. We lazy load to make dkjson an option dependency.
local ser = require(rootDir .. 'lib.Ser.ser')

local loadstring = loadstring
local type = type
local setmetatable = setmetatable
local pairs = pairs
local table = {
  insert = table.insert,
  remove = table.remove
}
local love = love

--------------------------------------------------------------------------------------------------
-- Utility Functions
--------------------------------------------------------------------------------------------------

local tableClone
tableClone = function(orig)
  return loadstring(ser(orig))()
end

local tableContains = function(t, element)
  for _, value in pairs(t) do
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

local stripTableByKeyName
stripTableByKeyName = function(t, keyName, shouldMutate)
  local workingTable = t
  if not shouldMutate then
    workingTable = tableClone(workingTable)
  end

  if type(keyName) ~= 'table' then
    keyName = {keyName}
  end

  for k, v in pairs(workingTable) do
    for _, keyName in ipairs(keyName) do
      if k == keyName then
        workingTable[k] = nil
      elseif type(v) == 'table' then
        stripTableByKeyName(v, {keyName}, true)
      end
    end
  end

  return workingTable
end

local stripArrayByValue = function(t, value, shouldMutate)
  local workingTable = t
  if not shouldMutate then
    workingTable = tableClone(workingTable)
  end

  for i, v in ipairs(workingTable) do
    if v == value then
      table.remove(workingTable, i)
    end
  end

  return workingTable
end

--------------------------------------------------------------------------------------------------
-- Binding Object
--------------------------------------------------------------------------------------------------

local binding = {--[[
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

function binding:isDown()
  for _, key in ipairs(self.keys) do
    if love.keyboard.isDown(key) then
      return true
    end
  end

  return false
end

function binding:bind(key)
  if type(key) == 'table' then
    tableConcat(self.keys, key)
  else
    table.insert(self.keys, key)
  end
end

function binding:bindNext(function_callback)
  table.insert(controls._keystrokeListeners, function(key)
    self:bind(key)
    function_callback(key)
  end)
end

function binding:unbind(key)
  if type(key) == 'table' then
    for _, workingKey in ipairs(key) do
      stripArrayByValue(self.keys, workingKey, true)
    end
  else
    stripArrayByValue(self.keys, key, true)
  end
end

--------------------------------------------------------------------------------------------------
-- Private Methods
--------------------------------------------------------------------------------------------------

local function createBinding(stateName, bindingName)
   local newBinding = setmetatable({
    keys = {},
    onPressCallbacks = {},
    onReleaseCallbacks = {}
  }, binding)

  if not controls.states[stateName] then
    controls.states[stateName] = {}
  end
  controls.states[stateName][bindingName] = newBinding

  return newBinding
end

local function bindingExists(stateName, bindingName)
  return (type(controls.states[stateName][bindingName]) == 'table')
end

local function returnBindingOrNew(stateName, bindingName)
  local workingBinding, isNew = nil, false
  if controls.states[stateName] and bindingExists(stateName, bindingName) then
    workingBinding = controls.states[stateName][bindingName]
  else
    workingBinding = createBinding(stateName, bindingName)
    isNew = true
  end
  return workingBinding, isNew
end

--------------------------------------------------------------------------------------------------
-- Public Methods
--------------------------------------------------------------------------------------------------

function controls.bind(keys, stateName, bindingName)
  local workingBinding = (returnBindingOrNew(stateName, bindingName))
  workingBinding:bind(keys)
  return workingBinding
end

function controls.state(stateName)
  local function getBinding(bindingName)
    return (returnBindingOrNew(stateName, bindingName))
  end
  return { binding = getBinding }
end

function controls.serialize()
  local states = stripTableByKeyName(controls.states, {'onPressCallbacks', 'onReleaseCallbacks'})

  for _, bindings in pairs(states) do
    for _, bindingProps in pairs(bindings) do
      for i, key in ipairs(bindingProps.keys) do
        bindingProps[i] = key
      end
      stripTableByKeyName(bindingProps, 'keys', true)
    end
  end

  return states
end

function controls.parse(t)
  for stateName, bindings in pairs(t) do
    for bindingName, keys in pairs(bindings) do
      controls.bind(keys, stateName, bindingName)
    end
  end
end

function controls.load(loadPath)
  if not dkjson then
    dkjson = require(rootDir .. 'lib.dkjson.dkjson')
  end

  controls.parse(dkjson.decode(io.open(loadPath):read('*all')))
end

function controls.save(savePath)
  if not dkjson then
    dkjson = require(rootDir .. 'lib.dkjson.dkjson')
  end

  local keybinds = controls.serialize()

  io.open(savePath, 'w+'):write(dkjson.encode(keybinds, { exceptions = function() return true end}))
end

--------------------------------------------------------------------------------------------------
-- Mouse Object
--------------------------------------------------------------------------------------------------
local mouse = {
  onMoveCallbacks = {}
}

function mouse:onMove(function_callback)
  table.insert(self.onMoveCallbacks, function_callback)
end

-- Simple syntactical sugar.
mouse.leftButton = controls.bind('mouse_l', 'all', 'mouse_l')
mouse.middleButton = controls.bind('mouse_m', 'all', 'mouse_m')
mouse.rightButton = controls.bind('mouse_r', 'all', 'mouse_r')
mouse.mouseWheel = {}
mouse.mouseWheel.up = controls.bind('mouse_wu', 'all', 'mouse_wu')
mouse.mouseWheel.down = controls.bind('mouse_wd', 'all', 'mouse_wd')

controls.mouse = mouse

--------------------------------------------------------------------------------------------------
-- Callbacks Handlers
--------------------------------------------------------------------------------------------------

local function onKeyPress(key, isRepeat, x, y)
  for i, listener in ipairs(controls._keystrokeListeners) do
    listener(key)
    table.remove(controls._keystrokeListeners, i)
  end

  for state, bindings in pairs(controls.states) do
    if state == controls.currentState or state == 'all' then
      for _, bindingProps in pairs(bindings) do
        if tableContains(bindingProps.keys, key) then
          for _, callback in ipairs(bindingProps.onPressCallbacks) do
            if not (callback.listenToRepeat or isRepeat) then
              callback.func(x, y)
            end
          end
        end
      end
    end
  end
end

local function onKeyRelease(key, x, y)
  for state, bindings in pairs(controls.states) do
    if state == controls.currentState or state == 'all' then
      for _, bindingProps in pairs(bindings) do
        if tableContains(bindingProps.keys, key) then
          for _, callback in ipairs(bindingProps.onReleaseCallbacks) do
            callback(x, y)
          end
        end
      end
    end
  end
end

local function onMouseMove(x, y, deltaX, deltaY) -- TODO: Maybe implement state awareness.
  for _, callback in ipairs(mouse.onMoveCallbacks) do
    callback(x, y, deltaX, deltaY)
  end
end

--------------------------------------------------------------------------------------------------
-- Integrations
--------------------------------------------------------------------------------------------------

if love and not (love.keypressed and love.keyreleased and love.mousepressed and love.mousereleased and love.mousemoved) then
  -- Love2D
  love.keyboard.setKeyRepeat(true)

  function love.keypressed(key, isRepeat)
    onKeyPress(key, isRepeat)
  end

  function love.keyreleased(key)
    onKeyRelease(key)
  end

  function love.mousepressed(x, y, button)
    onKeyPress('mouse_' .. button, false, x, y)
  end

  function love.mousereleased(x, y, button)
    onKeyRelease('mouse_' .. button, x, y)
  end

  function love.mousemoved(x, y, deltaX, deltaY)
    onMouseMove(x, y, deltaX, deltaY)
  end
else
  -- Standalone
  controls.fire = {}

  function controls.fire.keyPressed(key, isRepeat)
    onKeyPress(key, isRepeat)
  end

  function controls.fire.keyReleased(key)
    onKeyRelease(key)
  end

  function controls.fire.mousePressed(x, y, button)
    onKeyPress('mouse_' .. button, false, x, y)
  end

  function controls.fire.mouseReleased(x, y, button)
    onKeyRelease('mouse_' .. button, x, y)
  end

  function controls.fire.mouseMove(x, y, deltaX, deltaY)
    onMouseMove(x, y, deltaX, deltaY)
  end
end

return controls
