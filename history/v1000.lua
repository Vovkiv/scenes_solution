-- At bottom you will find demo, don't miss it, if you have not much idea of what this library do.
-- There changelog, too.

--[[
-- Scene syntax:

local scene = {}

scene.name = "cool_name" -- optionaly.
scene.layer = 1 -- optionaly.

scene.load = function() end
scene.unload = function() end
scene.activate = function() end
scene.deactivate = function() end

return scene
--]]

local ss = {
  _URL = "https://github.com/Vovkiv/scenes_solution",
  _VERSION = 1000,
  _LOVE = 11.4,
  _DESCRIPTION = "Yet another scene manager.\nCan handle scenes stacking, functions across scene, layering and more!",
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

--[[
Active scene = meaning that this scene in use, library will send function to, callbacks and it will be in list of active scenes.
Loaded scene = scene that was loaded from scene file (that is just lua file). 
Inactive scene = scene, that was loaded, but not in active list.

Scene table = is required table, that you can see in syntax, in top of this file
--]]

--[[
This is used to load scene files.
If you cantain scene files in folder, you can write here path to it and later just write:
ss.load("scene1")
Instead of:
ss.load("/path/to/scenes/scene1").

Path should be written as:
"/path/to/scene" with "/" on end.
--]]
ss.path = "/"

--[[
Here library will store loaded, active, etc scenes.
If you don't have planes to modify or hack this library, then you don't need to touch this table manualy.
--]]
ss.list = {
  -- Scenes that will be rendered by layer number.
  activeSorted = {},
  
  -- Active scenes.
  active = {},
  
  -- Loaded scenes.
  loaded = {}
}

ss.getActiveList = function()
  --[[
  Will generate and return flat table {"scene1", "scene2", etc} with list of active scenes.
  This list will be taken from list, will already sorted by layer scenes, meaning, that this list will
  accurately represent currect active list.
  That might be useful, if you, for example, need to deactivate all active scene, which might be easer to write, then manualy deactivate every active scene (especially if you have to much scenes):
  --[=[
  ss.load("scene1", "scene2", "scene3") -- load all big collection of scenes.
  ss.deactivate(unpack(ss.getActiveList()))
  -- ss.getActiveList will return flat table, unpack will unpack it as list of arguments and then
  -- (since deactivate function can work with as much arguments as you want) deactivate them all.
  --]=]
  
  Or you can (for debug purposes) write on screen list of currectly active scenes:
  --[=[
  ss.load("scene1", "scene2", "scene3")
  ss.activate(unpack(ss.getLoadedList()))
  
  love.draw = function()
    
    for i, name in ipairs(ss.getActiveList()) do
      love.graphics.print(name, i * 100, 20)
    end
    
  end
  --]=]
  --]]
  local activeSorted = ss.list.activeSorted
  -- List where goes name of scenes.
  local list = {}
  
  -- Take names from sorted scenes.
  for i = 1, #activeSorted do
   table.insert(list, activeSorted[i].name)
  end
  
  return list
end

ss.getInactiveList = function()
  --[[
  Will generate and return flat table {"scene1", "scene2", etc} with list of loaded but inactive scenes.
  For example, lets say you loaded 3 scenes:
  ss.load("scene1", "scene2", "scene3")
  And activated only 2:
  ss.activate("scene1", "scene3")
  And you need to get name of loaded, but inactive scenes.
  So you can call this function and get this names:
  print(unpack(ss.getInactiveList())) --> "scene2"
  --]]
  local loaded = ss.list.loaded
  local active = ss.list.active
  local list = {}
  
  for name, _ in pairs(loaded) do
    if not active[name] then
      table.insert(list, name)
    end
  end
  
  return list
end

ss.getLoadedList = function()
  --[[
  Will generate and return flat table {"scene1", "scene2", etc} with list of loaded scenes.
  --]]
  local list = {}
  
  for name, _ in pairs(ss.list.loaded) do
    table.insert(list, name)
  end
  
  return list
end

ss.isAnyActive = function()
  --[[
  Return true if there at least 1 active scene.
  --]]
  local activeSorted = ss.list.activeSorted
  if #activeSorted > 0 then return true
  else return false end
end

ss.isAnyLoaded = function()
  --[[
  Return true if there at least 1 loaded scene.
  --]]
  for _, _ in pairs(ss.list.loaded) do
    return true
  end
  
  return false
end

ss.isActive = function(scene)
  --[[
  Return true if scene is active, otherwise false.
  Function will not check if requested scene is loaded.
  
  Can be used to determine is scene is loaded and only then, for example, call function in it:
  --[=[
  if ss.isActive("scene1") then
    ss.func({"scene1", "functionName"}, agrument1, argument2)
  end
  --]=]
  --]]
  if ss.list.active[scene] then return true end
  return false
end

ss.isLoaded = function(scene)
  --[[
  Return true if scene is loaded.
  --]]
  if ss.list.loaded[scene] then return true end
  return false
end


ss.load = function(...)
  --[[
  Will load requested scene(s), based on their filename (or full path).
ss.load("scene1", "scene2", etc) or ss.load("scene1")
  If you doesn't specified "ss.path" then you need to write full path to scene file. (without ".lua" extension.
  ss.load("/path/to/scene1", "/path/to/scene2", etc).
  
  Scene, that was loaded, will get scene.load callback, which can be used to load assets, init libraries, etc.
  
  Scene name (that you will use later to interact with scenes) is determined by "name" value
  in scene table or if you doesn't specife it, will be taken from file name.
  (So, if you load file "scene1", but it have "name = s1" then later you need use ss.activate("s1");
  and if no "name" then ss.activate("scene1"))
  
  If you try to load scene, that (by filename or table value) is already loaded, then error will be raised.
  (Use "require" under the hood to load files.)
  
  Function will check scene "syntax", so if something that library need is missing, then it raise error.
  (You can find scene syntax in top of that file.)
  --]]
  -- Arguments.
  local listToLoad = {...}
  -- List with loaded scenes.
  local listWithLoaded = {}
  local functionsList = {"load", "unload", "activate", "deactivate"}
  local path = ss.path
  local raiseError = ss.raiseError
  local loaded = ss.list.loaded
  
  for i = 1, #listToLoad do
    local isError
    local fileName = listToLoad[i]
    local pathToScene = path .. fileName
    local currectScene
    local name
    
    isError, listWithLoaded[i] = pcall(require, pathToScene)
    
    if not isError then
      raiseError("You tried to load scene file \"%s.lua\", there error happened:\n%s",
      pathToScene, listWithLoaded[i])
    end
    
    currectScene = listWithLoaded[i]
    
    -- Check if scene return scene table.
    if type(currectScene) ~= "table" then
      raiseError("Scene file at \"%s.lua\" should return table with necessary data.\nCheck library file for more info.", pathToScene)
    end
    
    currectScene.name = currectScene.name or fileName
    currectScene.layer = currectScene.layer or 0
    
    name = currectScene.name
    
    -- Check if there already scene with same name
    if loaded[name] then
      raiseError("You tried to add scene \"%s\" but there already scene with same name in loaded list.", name)
    end
    
    -- Check for required functions in scene table.
    for i2 = 1, #functionsList do
      local currectFunction = functionsList[i2]
      if type(currectScene[currectFunction]) ~= "function" then
        raiseError("There is no such function\"%s\" in scene \"%s\".", currectFunction, name)
      end
    end
    
    -- If everything alright with scene, then send it to library "ss.list.loaded" table.
    loaded[name] = currectScene
    
    -- Callback.
    loaded[name].load()
  end
end

ss.unload = function(...)
  --[[
  Will unload requested scene(s).
  ss.unload("scene1", "scene2") or ss.unload("scene1")
  If scene, that you want to unload, is active or doesn't even loaded, then error will be raised.

  Unloaded scene will get scene.unload callback and after that, scene will be nil'ed, so garbage colletion can do it's thing.
  (If you store any data outside of scene table, then use scene.unload callback to delete them, because we don't need memory leaks.)
  --]]
  
  local list = {...}
  local active = ss.list.active
  local loaded = ss.list.loaded
  local raiseError = ss.raiseError
  
  for i = 1, #list do
    local name = list[i]
    
    
    -- First of all, we need to check if that scene even was loaded.
    if not loaded[name] then
      raiseError("There is no such scene \"%s\" in list of loaded scenes.", name)
    end
    
    -- Check if required scene is active.
    if active[name] then
      raiseError("You can't unload scene \"%s\" because it activated.", name)
    end
    
    -- Callback.
    loaded[name].unload()
    -- nil so it can be garbage collected.
    loaded[name] = nil
  end
end

ss.activate = function(...)
  --[[
  Used to activate loaded scenes, so library will be able to do it's magic on them.
  ss.activate("scene1", "scene2") or ss.activate("scene1").
  
  If scene, that you requested is not loaded, then error will be raised.
  
  After scene was activated, it will get callback scene.activate.
  
  ss.load("scene1", "scene2")
  ss.activate("scene1")
  --]]
  local list = {...}
  local active = ss.list.active
  local loaded = ss.list.loaded
  local raiseError = ss.raiseError
  
  -- Unpack names from raguments and start activating acn error checking.
  for i = 1, #list do
    local name = list[i]
    
    -- Check if scene even loaded.
    if not loaded[name] then
      raiseError("There is no such scene \"%s\" in loaded scenes list.", name)
    end
    
    -- Check if there already scene with same name.
    if active[name] then
      raiseError("You tried to activate scene \"%s\", but there is already scene with same name.", name)
    end
    
    -- Send scene to active list.
    if loaded[name] then
      active[name] = loaded[name]
    end
    
    -- Callback.
    active[name].activate()
  end
  
  -- Generate new table with active scene based by layer number.
  ss.generate()
end

ss.deactivate = function(...)
  --[[
  Used to deactivate active scenes.
  ss.deactivate("scene1", "scene2") or ss.deactivate("scene1").
  
  If scene, that you requested is not active (or even loaded), then error will be raised.
  
  After scene was deactivated, it will get callback scene.deactivate.
  
  ss.load("scene1", "scene2")
  ss.activate("scene1", "scene2")
  ss.deactivate("scene1")
  --]]
  local list = {...}
  local active = ss.list.active
  local raiseError = ss.raiseError
  
  -- Unpack scenes names and start deactivating and error checking.
  for i = 1, #list do
    local name = list[i]
    
    -- Check if that scene in active list.
    if not active[name] then
      raiseError("There is no such scene \"%s\" to deactivate.", name)
    end
    
    -- Callback.
    active[name].deactivate()
    -- Remove scene from active list.
    active[name] = nil
  end
  
  -- Generate new table with active scene based by layer number.
  ss.generate()
end

ss.changeLayer = function(scene, layer)
  --[[
  Allow to change layer of scene.
  ss.changeLayer("scene1", 10)
  
  The bigger number, the later scene will be called.
  (so, if we have "scene1" with layer 1 and scene "scene2" with layer 0 then
  scene "scene" will be called first, and only after it will be called "scene1".)
  
  You can change layer of scene even if it is inactive.
  
  If you try to change non loaded scene or layer number is non number, then errors will be raised.
  --]]
  local loaded = ss.list.loaded
  local active = ss.list.active
  local raiseError = ss.raiseError
  local oldLayer
  
  -- Check if scene exist.
  if not loaded[scene] then
    raiseError("There is no such scene \"%s\" to change it's layer.", scene)
  end
  
  -- Check if 2nd agr is number.
  if type(layer) ~= "number" then
    raiseError("2nd argument should be a number, not \"%s\".", type(layer))
  end
  
  -- Change layer.
  oldLayer = loaded[scene].layer
  loaded[scene].layer = layer
  
  -- Generate and sort active scenes list, if required scene is active and layer is different from value that it has before.
  -- If it not, then there is no reasons to waste time to sort layers that is not even changed.
  if active[scene] and oldLayer ~= layer then
    ss.generate()
  end
end

ss.getLayer = function(scene)
  --[[
  Allow to get scene layer.
  ss.getLayer("scene1")
  
  Can get scene layer even if scene is not active.
  If scene is not exsist, error will be raised.
  --]]
  local loaded = ss.list.loaded
  
  -- If there is not such scene in loaded list.
  if not loaded[scene] then
    ss.raiseError("There is no such scene \"%s\" to get it layer.", scene)
  end
  
  -- Return layer number.
  return loaded[scene].layer
end

ss.call = function(functionProperties, ...)
  --[[
  Allow call function in all active scenes or to any loaded scene.
  
  If you need to call functions in all scenes, then just send function string name and optional arguments:
  ss.call("name", ...)
  (Where name is name of function that you want to call and "..." is arguments that you want to sent, that
  function in scenes will get.)
  
  If you need to call function in any other scene, then do:
  ss.call({"name", "scene"}, ...)
  (You need to send 1st argument table, where 1 index is name of scene, which should get function call
  and 2 index is function name.)
  (Also, this will do "return scene.function(...)" meaning you can get values from functions from scenes!)
  
  If you need to get data from all active scenes via function, you can't do something like:
  testValue = ss.call("getDataFromFunctionsOfAllScenes")
  Because this method use for loops, which means "return" will end function.
  So if you need to get value from functions of all active scenes, you can do:
  --[=[
  for i, name in ipairs(ss.getActiveList()) do
    tableWithData[i] = ss.call({name, "functionName"}, argument1, argument2, ...)
  end
  --]=]
  --]]
  
  local activeSorted = ss.list.activeSorted
  local loaded = ss.list.loaded
  local raiseError = ss.raiseError
  
  -- Run function for every active scene.
  if type(functionProperties) == "string" then
    for i = 1, #activeSorted do
    -- Check if required function exist (or even function!).
    if type(activeSorted[i][functionProperties]) ~= "function" then
      raiseError("There is no such function \"%s\" in scene \"%s\".", functionProperties, activeSorted[i].name)
    end
    -- Call function if everything fine,
      activeSorted[i][functionProperties](...)
    end

  -- Run function for specific scene.
  elseif type(functionProperties) == "table" then
    -- Unpack table with function and scene names.
    local scene, func = functionProperties[1], functionProperties[2]
    
    -- Check if required scene exist.
    if not loaded[scene] then
      raiseError("There is no such scene \"%s\".", scene)
    end
    
    -- Check if required function exist (or if it even function).
    if type(loaded[scene][func]) ~= "function" then
      raiseError("There is no such function \"%s\" in scene \"%s\".", func, scene)
    end
    
    -- Call function via return (meaning, that you can pass values via function!).
    return loaded[scene][func](...)
  end
  
end


-- Next functions is for iternal library use only!
-- (Or if you need to hack or make changes to library, then welcome.)

ss.raiseError = function(errorString, ...)
  --[[
  Raise error with traceback level 3, so when error is called, it will be
  pointed at user's function, that caused error, not onto library.
  
  It aslo use string.format to generate error string.
  --]]
  local tracebackLevel = 3
  error(string.format(errorString, ...), tracebackLevel)
end

ss.sort = function()
  --[[
  Will sort ss.list.activeSorted by layer number of every scene.
  So if scene have layer 1, then it will be 1st, and scene with number bigger will be 2nd.

  Call it:
  If you changed layer in scene somewhere in ss.list.activeSorted (if you changed ss.list.active,then
  you need to generate new ss.list.activeSorted via ss.generate)
  --]]
  local activeSorted = ss.list.activeSorted
  table.sort(activeSorted, function(a, b)
    return a.layer < b.layer
  end)
  
end

ss.generate = function()
  --[[
  Will generate new ss.list.activeSorted.
  Call it when:
  A. you added or remove something from ss.list.active, because user interact with it
  While ss.list.activeSorted is table that actually used for rendering scenes
  B. When you changed layer in ss.list.active
  --]]
  ss.list.activeSorted = {}
  local activeSorted = ss.list.activeSorted
  local active = ss.list.active
  
    for _, scene in pairs(active) do
      table.insert(activeSorted, scene)
    end

    ss.sort()
end

return ss

-- Demo:
--[[
  Since it's too big, please, refer to SS._URL, there you will found demo.
--]]

-- Changelog:
--[[
Version 1000, 18 may 2022
* Initial release.
--]]