-- At bottom you will find demo, don't miss it, if you have not much idea of what this library do.
-- There changelog, too.

local scenes = {
  _URL = "https://github.com/Vovkiv/scenes_solution",
  _VERSION = 1000,
  _LOVE = 11.4,
  _DESCRIPTION = "Yet another scene manager. Can handle several scenes at once, have nice documentation!",
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
-- scenes, that will be rendered
scenes.active = {}
-- when library need to send something for active scenes
-- it will use this, because it will be sorted for that.
scenes.activeSorted = {}
-- path to scenes, that you want to load;
-- leave name without "/" at end, e.g: "path/to/scenes", not "path/to/scenes/"
scenes.path = ""
-- list of scenes by name.
-- e.g: scene1, scene2
scenes.list = {}

-- Will generate new "scenes.activeSorted" array, which used to call scenes in order, which determined by
-- "layer" value.
-- You don't need to use this function, if you use only built-in functions to change/update list of active scenes
-- otherwise, call this function when "scenes.active" or "activeSorted" changed.
scenes.generateActive = function()
  scenes.activeSorted = {}
  for key, scene in pairs(scenes.active) do
    table.insert(scenes.activeSorted, scene)
  end
  scenes.sort()
end

-- Will sort "scenes.activeSorted" by "layer" properties, that you give in their respective scene files
-- or via "scenes.updateLayer" or with any other way...
-- If you use only built-in function to add active scene, change scenes oredering, etc, then you can ignore this function
-- But if you manually somewhere changed "layer" of scenes manually then call "scenes.sort" after you changed it.
scenes.sort = function()
  table.sort(scenes.activeSorted, function(a, b)
    return a.layer < b.layer
  end)
end

-- Will remove scenes from list (and therefore memory).
-- You can't remove scene, that in use, so use "scenes.set" or "scenes.unset"
-- to remove scene from active scenes and only then delete unused scene.
scenes.remove = function(...)
  local deleteScenes = {...}
  for i = 1, #deleteScenes do
    local name = deleteScenes[i]
    assert(not scenes.active[name], "You tried to delete scene \"" .. name .. "\", but it's scene in active list, which means you can't delete it.\nUnset it and only then remove")
    assert(scenes.list[name], "You tried to delete scene \"" .. name .. "\", but there is no such scene")
    scenes.list[name].delete()
    scenes.active[name] = nil
  end
end

-- Return table of all currectly active scenes
-- e.g: {scene1, scene2, scene3}.
-- If there is no active scenes, will return false.
-- Might be used as:
--  local activeList = scenes.getActiveList 
--  for i = 1, #activeList do
--     -- why not delete all "load" functions from them?
--     -- (don't delete load function, please)
--     scenes.list.active[activeList[i]].load = nil
--  end
scenes.getActiveList = function()
  local activeScenes = {}
  
  for i = 1, #scenes.activeSorted do
    activeScenes[i] = scenes.activeSorted[i].name
  end
  if #activeScenes > 0 then
    return activeScenes
  end
  return false
end

-- Check if specified scene is active.
scenes.isActive = function(scene)
  if scenes.active[scene] then
    return true
  end
  
  return false
end

-- Check if specific scene is in list of loaded scenes.
scenes.inList = function(scene)
  if scenes.list[scene] then
    return true
  end
  
  return false
end

-- Update layer of specific scene.
-- Ordering goes from lesser number to bigger: 0 > 1 > 1 > 10 > 20.
scenes.updateLayer = function(scene, layer)
  assert(scenes.active[scene], "You tried to update layer of scene \"" .. scene.. "\"" .. " but there is not such scene")
  assert(layer, "To update layer of scene \"" .. scene.. "\"" .. " you need to provide number!")
  scenes.active[scene].layer = layer
  scenes.sort()
end

-- Add new scene to list.
-- Uses "require" to load scenes.
scenes.add = function(...)
  local scenesList = {...}
  local loaded = {}
  local sceneLoadingError
  for i = 1, #scenesList do
  local pathRequire = scenes.path .. "/" .. scenesList[i]
    sceneLoadingError, loaded[scenesList[i]] = pcall(require, pathRequire)
    assert(sceneLoadingError, "You tried to open scene file \"" .. pathRequire .. ".lua\", but there is no such file")
  end
  
  for key, scene in pairs(loaded) do
    scene.name = (scene.name or key)
    scene.layer = (scene.layer or 0)
    local name = scene.name
    assert(type(scene) == "table", "Scene file \"" .. name .. "\" doesn't return table, required by library, at all!\nCheck bottom of this library file for more instructions!")
    assert(type(scene.load) == "function", "Library require, that table of scene \"" .. name .. "\" should have \"load\" function!")
    assert(type(scene.final) == "function", "Library require, that table of scene \"" .. name .. "\" should have \"final\" function!")
    assert(type(scene.delete) == "function", "Library require, that table of scene \"" .. name .. "\" should have \"delete\" function!")
    assert(type(scene.add) == "function", "Library require, that table of scene \"" .. name .. "\" should have \"add\" function!")
    
    assert(not scenes.list[name], "You tried to add scene " .. name .. " to list, but there already scene with same name!")
    
    scenes.list[key] = scene
    scenes.list[key].add()
  end

end

-- Will unset ONLY specified scene.
-- Not specified scenes WILL BE NOT touched.
scenes.unset = function(...)
  local unsetScenes = {...}
  
  for i = 1, #unsetScenes do
    local name = unsetScenes[i]
    assert(scenes.active[name], "You tried to unset \"" .. name .. "\" but there no such scene in list of active scenes")
    scenes.active[name].final()
    scenes.active[name] = nil
  end
  
  scenes.generateActive()
end

-- Will clear list of all 
scenes.set = function(...)
  local setScenes = {...}

  for i = 1, #scenes.activeSorted do
    scenes.activeSorted[i].final()
  end

  scenes.active = {}
  
  for i = 1, #setScenes do
    local name = setScenes[i]
    assert(scenes.list[name], "You tried to set scene \"" .. name .. "\" but there no such scene")
    scenes.active[name] = scenes.list[name]
  end
  
  scenes.generateActive()
  
  for i = 1, #scenes.activeSorted do
    scenes.activeSorted[i].load()
  end

end

scenes.func = function(func, ...)
  -- used to push string name function to ALL currect scenes, based on their
  -- "layer value, which determines which scene will get function earlier, then others
  for i = 1, #scenes.activeSorted do
    scenes.activeSorted[i][func](...)
  end
end

scenes.func2 = function(scene, func, ...)
  -- push func to specific scene
  scene.active[scene][func](...)
end

return scenes

-- demo:
--[[

--]]

-- Changelog:
--[[
Version 1000, ?? mounth 2022
* Initial release
--]]