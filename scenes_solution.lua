-- At bottom you will find demo, don't miss it, if you have not much idea of what this library do.
-- There changelog, too.

--[[
Scene "syntax":

local scene = {}
-- Optional, will be gathered from file name, if you doesn't name it.
scene.name = "name1" -- also don't try change it after you loaded it, it will give you bunch of errors
-- Optional, can be changed later with "scenes.updateLayer".
-- 0 by default.
-- Determines which scene should be rendered firstly, if you planning to use stacking functionality
scene.layer = 0

-- Callback function, will be called when scenes.add will finish loading scene file.
scene.onAdd = function() end

-- Callback function, will be called when scenes.set will mark scene as "active" scene.
scene.onSet = function() end

-- Callback function, will be called when you remove scene from active via scenes.set or scenes.unset.
-- (if scene was not added via "scenes.set" then this callback will be never triggered)
scene.onUnset = function() end

-- Callback function, will be called when you remove scene via "scenes.remove".
-- Will be called before nil'ing scene table.
scene.onRemove = function() end

-- callback, that allow send from anywhere data to scene.
scene.onMessage = function(...) end

return scene
--]]

local scenes = {
  _URL = "https://github.com/Vovkiv/scenes_solution",
  _VERSION = 1000,
  _LOVE = 11.4,
  _DESCRIPTION = "Yet another scene manager.\nCan handle scenes stacking, functions and data pushing, layering and bunch of other functions!",
  _NAME = "Scenes Solution",
  _LICENSE = "The Unlicense",
  _LICENSE_TEXT = [[
This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <https://unlicense.org>
]]
}

-- List of scenes that marked as "active", meaning it will be sorted to "scenes.activeSorted" and that table will be used to actually draw/update/send/etc scenes.
scenes.active = {}
-- This table use to actually render scene stuff.
scenes.activeSorted = {}
-- Path to folder where scenes files is stored.
-- "/path/to/folder/with/scenes/files/".
-- Don't forgert to put "/" at end.
scenes.path = ""
-- list of scenes that is "active"
scenes.list = {}

scenes.add = function(...)
--[[
Require scene names as arguments:
scenes.add("scene1", "scene2", "scene3")

Add/load new scenes to memory.
Name of scene will be determined either by:
File name or in table, that scene optionally return scene.name

You can add as much scenes at once, as you want:
scenes.add("scene", "scene1", "scene2").
If scene, that you trying to add, have name that already in use, then error will be raised:
scene.add("scene", "scene") or scene.add("scene"); scene.add("scene")
Uses "require" to load scenes.

Example:
-- Require library.
scenes = require("libs/scenes_solution")
-- Load scene from file to library.
scenes.add("scene1")
--]]

  local scenesList = {...}
  
  -- Check incoming list for duplicates
  table.sort(scenesList)
  for i = 1, #scenesList do
    if i == #scenesList then break end
    if scenesList[i] == scenesList[i + 1] then
      error(".add: you tried to add 2 scenes with same name: \"" .. scenesList[i] .. "\"!")
    end
  end

  -- This table will contain scenes that library gonna load.
  local loaded = {}
  -- Check for pcall
  local sceneLoadingError
  -- Parse arguments
  for i = 1, #scenesList do
  -- Get name of file from arguments
  local pathRequire = scenes.path .. scenesList[i]
    -- Try to load scene file to table
    sceneLoadingError, loaded[scenesList[i]] = pcall(require, pathRequire)
    
    -- Check if errors happened during scene file loading
    if not sceneLoadingError then
      error(".add: You tried to load scene file \"" .. pathRequire .. ".lua\", but error happened:\n" .. loaded[scenesList[i]])
    end
  end
  
  -- check scene for errors, fill missing data
  for key, scene in pairs(loaded) do
    -- Get name from scene table, or from scene filename.
    scene.name = (scene.name or key)
    -- Get layer name from scene tabe or set it to 0, if you don't need stacking features
    scene.layer = (scene.layer or 0)
    -- Localise name for errors
    local name = scene.name
    
    -- Check newly added scene for errors.
    -- Check if scene file return table at all.
    if type(scene) ~= "table" then
      error(".add: Scene file \"" .. name .. "\" doesn't return table, required by library, at all!\nCheck library file for more instructions, if you don't know what to do!")
    end
    
    -- Check if table have "onSet" function.
    if type(scene.onSet) ~= "function" then
      error(".add: Library require, that table of scene \"" .. name .. "\" should have \"onSet\" function!")
    end

    -- Check if table have "onUnset" function.
    if type(scene.onUnset) ~= "function" then
      error(".add: Library require, that table of scene \"" .. name .. "\" should have \"onUnset\" function!")
    end
    
    -- Check if table have "onRemove" function.
    if type(scene.onRemove) ~= "function" then
      error(".add: Library require, that table of scene \"" .. name .. "\" should have \"onRemove\" function!")
    end
    
    -- Check if table have "onAdd" function.
    if type(scene.onAdd) ~= "function" then
      error("Library require, that table of scene \"" .. name .. "\" should have \"onAdd\" function!")
    end
    
    -- Check if table have "onMessage" function.
    if type(scene.onMessage) ~= "function" then
      error("Library require, that table of scene \"" .. name .. "\" should have \"onMessage\" function!")
    end
    
    -- Check, if there already loaded scene with same name.
    if scenes.list[name] then
      error("You tried to add scene " .. name .. " to list, but there already scene with same name!")
    end
    
    -- If everything is okay, then add scene to list of files
    scenes.list[key] = scene
    -- Call callback, so library can do something.
    scenes.list[key].onAdd()
  end
end

scenes.remove = function(...)
--[[
Require scenes names as arguments:
scenes.remove("scene1", "scene2", "scene3")

Will nil scene, and therefore, it will become subject for garbage collection.
.onDelete callback will be called to specific scene before nil'ing, so you can use this to clear your scene data.
You can't remove scene, that in use, so use "scenes.set" or "scenes.unset"
to remove scene from active scenes and only then remove scene.
--]]
  local deleteScenes = {...}
  
  -- Check incoming arguments for dublicates.
  table.sort(deleteScenes)
  for i = 1, #deleteScenes do
    if i == #deleteScenes then break end
    if deleteScenes[i] == deleteScenes[i + 1] then
      error(".remove: you tried to remove 2 scenes with same name: \"" .. deleteScenes[i] .. "\"!")
    end
  end
  
  -- Unpack incoming arguments.
  for i = 1, #deleteScenes do
    -- Localise name for errors
    local name = deleteScenes[i]
    
    -- Check if scene in active list (in use).
    if scenes.active[name] then
      error(".remove: You tried to delete scene \"" .. name .. "\", but it's scene in active list, which means you can't delete it.\nUnset it and only then remove.")
    end
    
    -- Check if scene is loaded in library.
    if not scenes.list[name] then
      error(".remove: You tried to delete scene \"" .. name .. "\", but there is no such scene")
    end
    -- Call callback function to scene, so it can do something about it (for example, clear variables).
    scenes.list[name].onRemove()
    -- nil scene table, so it now become subject for garbage collection.
    scenes.list[name] = nil
  end
end

scenes.set = function(...)
  --[[
Require scenes that you want to set as arguments:
scenes.set("scene1", "scene2", "scene3")

This function will set scenes as "active", so that mean they will get functions, callbacks, etc.
Also, they can be stacked, so you can simultaneously draw several scenes at once!
Still, you can set 1 scene at time.

Example:
-- Require library.
scenes = require("libs/scenes_solution")
-- Load scene from file to library.
scenes.add("scene1", "scene2", "scene3")
-- Set/activate scenes.
scenes.set("scene1", "scene2, "scene3")
-- or activate only 1 scene.
scenes.set("scene1")
--]]
  local setScenes = {...}
  
  -- Check incoming arguments for dublicates.
  table.sort(setScenes)
  for i = 1, #setScenes do
    if i == #setScenes then break end
    if setScenes[i] == setScenes[i + 1] then
      error(".set: you tried to set 2 scenes with same name: \"" .. setScenes[i] .. "\"!")
    end
  end
  
  -- Call unset callback, so library can finish it's business.
  for i = 1, #scenes.activeSorted do
    scenes.activeSorted[i].onUnset()
  end
  
  -- remove all active scenes
  scenes.active = {}
  
  for i = 1, #setScenes do
    local name = setScenes[i]
    if not scenes.list[name] then
      error(".set: You tried to set scene \"" .. name .. "\" but there no such scene")
    end
    scenes.active[name] = scenes.list[name]
  end
  
  scenes.generateActive()
  
  for i = 1, #scenes.activeSorted do
    scenes.activeSorted[i].onSet()
  end
end

scenes.func = function(func, ...)
--[[
Require function name that you want to call and optional argument that will be send with function call:
scenes.func("functionName")
note: "functionName" should be string and scene table should contain that function to be called.

Used to push string name function to ALL currect scenes, based on their "layer" value, which determines which scene will get function earlier, then others.

Example:
-- main.lua
scenes.func("test", 10)

-- scene1.lua
scene.test = function(testVariable)
    print(testVariable)
end

-- scene2.lua
scene.test = function(testVariable)
    print(testVariable)
end
--]]
  
  for i = 1, #scenes.activeSorted do
    scenes.activeSorted[i][func](...)
  end
end

scenes.funcTo = function(scene, func, ...)
--[[
Require scene name as 1st argument, function that you want to call as 2nd argument and optional arguments:
scenes.funcTo("sceneName", "functionName", agruments)

Push function with arguments to specific scene and sent arguments for it.
By default, it will NOT check if function exist in that scene table (for perfomance reasons).
(If you need to check incoming function for errors, uncomment commented-out code below).

Example:
-- main.lua
scenes.funcTo("scene1", "testFunction", "hello world!", 102)

-- scene1.lua
scene.testFunction = function(testArgument, ...)
  print(testArgument)
end
--]]
  
  -- Check if scene exist.
  if not scenes.list[scene] then
    error(".funcTo: You tried to push function \"".. func .. "\" in scene \"" .. scene .. "\" but there is no such scene")
  end

--[[
  if type(scenes.list[scene][func]) ~= "function" then
    error(".func2: You tried to push function \"".. func .. "\" in scene \"" .. scene .. "\" but there is no such function")
  end
--]]
  scenes.list[scene][func](...)
end

scenes.send = function(scene, ...)
--[[
Require scene name as argument and optional arguments:
scenes.send("scene1", "hello world!")

Send data and or message to specific scene.
That will call .onMessage callback, which will get all arguments.

Example:
-- main.lua
scenes.send("scene1", "hello world!")

-- scene1.lua
scene.onMessage = function(...)
  local args = {...}
  print(args[1])
end
--]]
  
  -- Check if scene exist.
  if not scenes.list[scene] then
    error(".send: You tried to send message to scene \"" .. scene .. "\" but there is no such scene")
  end
  -- Send all arguments to scene
  scenes.list[scene].onMessage(...)
end

scenes.unset = function(...)
  --[[
Require scenes names:
scenes.unset(("scene1", "scene2", "scene3")

Will unset ONLY specified scene.
Not specified scenes WILL BE NOT touched.
(Usefull, if you have, for example, 5 active scenes and you need siable one, without touching other scenes (callbacks, etc))

Example:
-- Activate scenes that you need.
scenes.set("scene1", "scene2", "scene3")
-- Now you don't need scene1, so you
scenes.unset("scene1")
-- scene2 and scene3 remained untouched, while scene1 was removed from active list and get ".onUnset() callack.
--]]
  
  local unsetScenes = {...}
  
  -- Check for dublicates
  table.sort(unsetScenes)
  for i = 1, #unsetScenes do
    if i == #unsetScenes then break end
    if unsetScenes[i] == unsetScenes[i + 1] then
      error(".unset: you tried to unset 2 scenes with same name: \"" .. unsetScenes[i] .. "\"!")
    end
  end
  
  -- Unpack list of specified scenes and unset them
  for i = 1, #unsetScenes do
    local name = unsetScenes[i]
    if not scenes.active[name] then
      error(".unset: You tried to unset \"" .. name .. "\" but there no such scene in list of active scenes")
    end
    scenes.active[name].onUnset()
    scenes.active[name] = nil
  end
  
  -- Since list of active scenes changed, we need generate new one.
  scenes.generateActive()
end

scenes.get = function(scene)
--[[
Require name scene as argument:
local scene = scenes.get("scene1")

Will return table of named scene, so you can localise it or do other stuff.
Will raise error if there is no scene in loaded list.

Example:
local scene1 = scenes.get("scene1")
print(scene1.name, scene1.layer)
--]]
  
  -- Check if that scene exist in list.
  if not scenes.list[scene] then
    error(".send: You tried to get scene \"" .. scene .. "\" but there is no such scene")
  end
  
  return scenes.list[scene]
end

scenes.getLoadedList = function()
  --[[
Return table of all loaded scenes
e.g: {scene1, scene2, scene3}.

If there is no active scenes, will return false.

Example:
-- Print all active scenes
love.draw = function()
  for i, v in ipairs(scenes.getLoadedList()) do
    love.graphics.print(v, i * 100, 300)
  end
end
--]]
  
  -- Create table for active list
  local loadedScenes = {}
  
  -- Unpack loaded table to local table.
  for sceneName, scene in pairs(scenes.list) do
    table.insert(loadedScenes, sceneName)
  end
  
  -- If table contains something, that means list is non-empty, so return table.
  if #loadedScenes > 0 then
    return loadedScenes
  end
  
  -- Otherwise return false
  return false
end

scenes.getActiveList = function()
--[[
Return table of all currectly active scenes
e.g: {scene1, scene2, scene3}.

If there is no active scenes, will return false.

Example:
-- Print all active scenes
love.draw = function()
  for i, v in ipairs(ss.getActiveList()) do
    love.graphics.print(v, i * 100, 300)
  end
end
--]]
  
  -- Create table for active list
  local activeScenes = {}
  
  -- Unpack active sorted table to local table.
  for i = 1, #scenes.activeSorted do
    activeScenes[i] = scenes.activeSorted[i].name
  end
  
  -- If table contains something, that means active list is non-empty, so return table.
  if #activeScenes > 0 then
    return activeScenes
  end
  
  -- Otherwise return false
  return false
end

scenes.getInactiveList = function()
--[[
Will return list of loaded scenes, that not active.

Example:
-- Print list of all inactive, but loaded scenes
love.draw = function()
  for i, v in ipairs(scenes.getInactiveList()) do
    love.graphics.print(v, i * 100, 300)
  end
end
--]]
  local inactiveScenes = {}
  
  for sceneName, scene in pairs(scenes.list) do
    if not scenes.active[sceneName] then
      table.insert(inactiveScenes, sceneName)
    end
  end
  
  if #inactiveScenes > 0 then return inactiveScenes end
  
  return false
end

scenes.isSceneActive = function(scene)
  --[[
Require 1 argument:
scenes.isSceneActive("scene1")

Check if specified scene is active.
Will return true if exist and false if not.

-- Example:
-- If "scene" become active, then disable "scene2"
if scenes.isSceneActive("scene") then
    scene.unset("scene2")
end
--]]

  if scenes.active[scene] then
    return true
  end
  return false
end

scenes.isSceneLoaded = function(scene)
  --[[
Require scene name as argument:
scenes.isSceneLoaded("scene1")

Check if specific scene is loaded (via scene.add) and exist.
Will return true if loaded and false if not.
--]]

  if scenes.list[scene] then
    return true
  end
  
  return false
end

scenes.updateLayer = function(scene, layer)
--[[
Require scene name as 1st argument and layer position as 2nd argument:
scenes.updateLayer("scene1", 10)

!!!! Keep im mind, that everytime you update layer of scene, library will build new list (in scenes.activeSorted), using (by default) table.sort!!!!

To update layer of scene, it should be loaded for that.
Ordering goes from lesser number to bigger: layer 0 scene1 ==> layer 20 scene2 ==> layer 30 scene3.
(Which means: layer with bigger number will be ontop of layer with lesser number)
If several scenes have same layer number, then scenes.sort(which is basically wraped around table.sort) will decide how to sort them.

Example:
-- you have 2 scenes
-- 1st named scene1 with layer 1 and 2nd scene2 with layer 2
scenes.updateLayer("scene
--]]
  
  -- Check if scene exist
  if not scenes.list[scene] then
    error(".updateLayer: You tried to update layer of scene \"" .. scene.. "\" but there is not such scene")
  end
  -- Check if user sended layer number
  if not layer or type(layer) ~= "number" then
    error(".updateLayer: To update layer of scene \"" .. scene.. "\"" .. " you need to provide number, not " .. type(layer))
  end
  scenes.list[scene].layer = layer
  scenes.sort()
end
--[[
Requires name of scene, which you want to get layer:
scenes.getLayer("scene1")

Get layer of named scene
--]]
scenes.getLayer = function(scene)
  if not scenes.list[scene] then
    error(".updateLayer: You tried to get layer of scene \"" .. scene.. "\" but there is not such scene")
  end
  
  return scenes.list[scene].layer
end

-- !!!! You don't need to use next 2 function, unless to need to hack this library for additional functionality, which it doesn't provide!!!! --

--[[
Will generate new "scenes.activeSorted" array, which used to call scenes in order, which determined by "layer" value.
You don't need to use this function, if you use only built-in functions to change/update list of active scenes
otherwise, call this function when "scenes.active" or "scenes.activeSorted" changed.
--]]
scenes.generateActive = function()
  -- Clean table with active sorted scenes, to create new one.
  scenes.activeSorted = {}
  
  -- Generate new table.
  for name, scene in pairs(scenes.active) do
    table.insert(scenes.activeSorted, scene)
  end
  
  -- Sort new table.
  scenes.sort()
end

scenes.sort = function()
--[[
Will sort "scenes.activeSorted" by "layer" properties, that you give in their respective scene files
or via "scenes.updateLayer" (or with any other way...).
If you use only built-in function to add active scene, change scenes oredering, etc, then you can ignore this function
But if you manually somewhere changed "layer" of scenes manually then call "scenes.sort" after you changed it.
--]]
  
  -- Sort active layers by layer position.
  table.sort(scenes.activeSorted, function(a, b)
    return a.layer < b.layer
  end)
end

return scenes

-- demo:
--[[
-- main.lua

-- scene1.lua

-- scene2.lua

--]]

-- Changelog:
--[[
Version 1000, 16 may 2022
* Initial release
--]]