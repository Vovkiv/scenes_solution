local scenes = {
  _URL = "",
  _VERSION = 1000,
  _LOVE = 11.4,
  _DESCRIPTION = "Scene manager",
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
-- list of all loaded scenes
scenes.list = {}
scenes.cash = function() end


scenes.remove = function(scenesToDelete)
  
end

scenes.add = function(...)
  --[[
  
  ... = fileName1, fileName2
  
  --]]
  
  --[[
  local scene = {}
  
  scene.name = "name"
  
  return scene
  --]]
  local isExist
  local scenesList = {...}
  for i = 1, #scenesList do
    assert(love.filesystem.getInfo(scenes.path .. "/" .. scenesList[i] .. ".lua"), "Failed")
    table.insert(scenes.list, require(scenes.path .. "." .. scenesList[i]))
    --isExist, scenes.list[scenesList[i][1]] = pcall(require, scenes.path .. "." .. scenesList[i][2])
    --assert(isExist, "You attempted to load " .. "\"" .. scenesList[i][2] .. ".lua\" by that path: \"" .. scenes.path .. "." .. scenesList[i][2] .. "\" but that file doesn't exist")
  end
  
end

scenes.set = function(scenesToSet)
  --[[
  scenesToSet = {
  name1, name2, name3
  }
  
  don't forget about drawind layering
  
  --]]
  for i = 1, #scenesToSet do
    if not scenes.list[scenesToSet[i]] then error(".set: you attempted to set scene, that actually don't exist: " .. "\"" .. scenesToSet[i] .. "\"") end
    scenes.currectScenes[i] = scenesToSet[i]
  end
end

scenes.draw = function()
  for i = 1, #scenes.currectScenes do
    scenes.list[scenes.currectScenes[i]].draw()
  end
end

scenes.update = function(dt)
  for i = 1, #scenes.currectScenes do
    scenes.list[scenes.currectScenes[i]].update(dt)
  end
end

return scenes