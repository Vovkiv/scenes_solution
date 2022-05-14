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
scenes.currectScenes = {}
-- path to scenes, that you want to load;
-- leave name without "/" at end, e.g: "path/to/scenes", not "path/to/scenes/"
scenes.path = ""
-- list of scenes by name
scenes.list = {}
-- scenes stored in "currectScenes" with numeric indexes, but here they stored with names, that you give them
-- (or names, that file with scene have).
-- So you can call for specific scene with "scenes.cash.scene".
-- if you somewhere changed "currectScenes" not via provided by library functions, make sure after changes
-- do "scenes.updateCash"; it will build new one
scenes.cash = {}

-- simply sort scenes by their "layer" properties, that you give in their files
-- or via "scenes.updateLayer"
-- if you somewhere changed layers of scenes not via library functions, then call "scenes.sort".
-- It will sort from the smallest numbers to biggest.
scenes.sort = function()
  table.sort(scenes.currectScenes, function(a, b)
    return a.layer < b.layer
  end)
end

-- will build new cash; refer to scenes.cash for more info.
scenes.updateCash = function()
  scenes.cash = {}
  for i = 1, #scenes.currectScenes do
    scenes.cash[scenes.currectScenes[i].name] = scenes.currectScenes[i]
  end
end

-- Will remove scenes from list (and therefore memory).
-- You can't remove scene, that in use, so use "scenes.set" or "scenes.unset"
-- to remove scene from active scenes and only then delete unused scene.
scenes.remove = function(...)
  local scenesToDelete = {...}
  for i = 1, #scenesToDelete do
    if scenes.cash[scenesToDelete[i]] then
      error("You attempted to delete scene \"" .. scenesToDelete[i] .. "\".\nYou can delete")
    else
      for i2 = 1, #scenes.list do
        if scenes.list[i2].name == scenesToDelete[i] then
          table.remove(scenes.list, i2)
          break
        end
      end
    end
  end
end

-- Return flat table of all currectly used scenes names
-- {scene1, scene2, scene3}.
-- If there is no at all active scenes, then return false.
-- Might be useful, to check if there at least 1 scene is active, before sendinf functions to it, to avoid errors raising.
scenes.getActiveScenes = function()
  local activeScenes = {}
  for i = 1, #scenes.currectScenes do
    activeScenes[i] = scenes.currectScenes[i].name
  end
  if #activeScenes > 1 then
    return activeScenes
  end
  return false
  end

-- Check if specified scene is active.
scenes.isSceneActive = function(sceneName)
  if scenes.cash[sceneName] then
    return true
  end
  return false
end

--
scenes.updateLayer = function(scene, layer)
  assert(scenes.cash[scene], "You tried to update layer of scene \"" .. layer .. "\" but there is not such scene")
  scenes.cash[scene].layer = layer
  scenes.sort()
end

-- add you scene to list.
scenes.add = function(...)
  local scenesList = {...}
  local loaded = {}
  local sceneLoadingError
  for i = 1, #scenesList do
    local pathRequire = scenes.path .. "/" .. scenesList[i]
    sceneLoadingError, loaded[i] = pcall(require, pathRequire)
    assert(sceneLoadingError, "You tried to open scene file \"" .. pathRequire .. ".lua\", but there is no such file")
    
    assert(type(loaded[i]) == "table", "Scene file \"" .. scenesList[i] .. "\" doesn't return table, required by library, at all!\nCheck bottom of this library file for more instructions!")
    assert(type(loaded[i].load) == "function", "Library require, that table of scene \"" .. scenesList[i] .. "\" should have \"load\" function!")
    assert(type(loaded[i].final) == "function", "Library require, that table of scene \"" .. scenesList[i] .. "\" should have \"final\" function!")
    
    loaded[i].name = (loaded[i].name or scenesList[i])
    loaded[i].layer = (loaded[i].layer or 0)
  end
  
  -- Check if there already loaded scene file
    for i = 1, #loaded do
      for i2 = 1, #scenes.list do
        if loaded[i].name == scenes.list[i2].name then
          error("You tried to add scene " .. loaded[i].name .. " to list, but there already " .. scenes.list[i2].name .. "...")
          break
        end
      end
  end
    
    scenes.list = loaded
end

-- Will unset ONLY specified scene.
-- Not specified scenes WILL BE NOT touched.
scenes.unset = function(...)
  local scenesToUnset = {...}
  for i = 1, #scenesToUnset do
    for i2 = 1, #scenes.currectScenes do
      if scenes.currectScenes[i2].name == scenesToUnset[i] then
        scenes.currectScenes[i2] = nil
        scenes.updateCash()
        break
      end
    end
  end
end

-- Will clear list of all 
scenes.set = function(...)
  for i = 1, #scenes.currectScenes do
    scenes.currectScenes[i].final()
  end
  
  scenes.currectScenes = {}
  local scenesToSet = {...}
  for i = 1, #scenesToSet do
    for i2 = 1, #scenes.list do
      if scenesToSet[i] == scenes.list[i2].name then
        scenes.currectScenes[i] = scenes.list[i2]
        break
      end
    end
  end
  
  scenes.sort()
  scenes.updateCash()
  
  for i = 1, #scenes.currectScenes do
    scenes.currectScenes[i].load()
  end
  
end

scenes.func = function(func, ...)
    -- used to push string name function to ALL currect scenes
    for i = 1, #scenes.currectScenes do
      scenes.currectScenes[i][func](...)
    end
end

scenes.func2 = function(scene, func, ...)
  -- push func to specific scene
  scene.cash[scene][func](...)
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