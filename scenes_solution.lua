local ss = {}
ss.path = "/"

ss.list = {
  -- Scenes that will be rendered by layer number
  activeSorted = {},
  -- Active scenes with name
  active = {},
  
  -- Loaded scenes with name
  loaded = {},
  isThereActiveScenes = false,
  isThereLoadedScenes = false
}

ss.getActiveList = function()--!
  local list = {}
  local localisedSorted = ss.list.activeSorted
  
  for i = 1, #localisedSorted do
    list[i] = localisedSorted[i].name
  end

  return list
end

ss.getInactiveList = function()
  local list = {}
  local localisedList = ss.list
  
  for name, _ in pairs(localisedList.loaded) do
    if not localisedList.active[name] then
      table.insert(list, name)
    end
  end

  return list
end

ss.getLoadedList = function()
  local list = {}
  
  for name, _ in pairs(ss.list.loaded) do
    table.insert(list, name)
  end
  
  return list
end

ss.isAnyActive = function()
  return ss.list.isThereActiveScenes
end

ss.isAnyLoaded = function()
  return ss.list.isThereLoadedScenes
end

ss.isActive = function(scene)
  if ss.list.active[scene] then return true end
  return false
end

ss.isLoaded = function(scene)
  if ss.list.loaded[scene] then return true end
  return false
end


ss.load = function(...)
  --[[
  ss.load(sceneFile, sceneFile1)
  --]]
  local listToLoad = {...}
  local listWithLoaded = {}
  local pathToScene
  local isError
  local fileName
  local functionsList = {"load", "remove", "activate", "deactivate"}
  
  for i = 1, #listToLoad do
    fileName = listToLoad[i]
    pathToScene = ss.path .. fileName
    
    isError, listWithLoaded[i] = pcall(require, pathToScene)
    
    if not isError then
      error("You tried to load scene file \"" .. pathToScene .. ".lua\", but error happened:\n" .. listWithLoaded[i])
    end
    
    listWithLoaded[i].name = listWithLoaded[i].name or fileName
    listWithLoaded[i].layer = listWithLoaded[i].layer or 0
    --check for errors--
    
    for i2 = 1, #functionsList do
      if type(listWithLoaded[i][functionsList[i2]]) ~= "function" then
        error("No func...")
        end
    end
    
    --END -- 
    
    -- Check if there already scene with same name
    if ss.list.loaded[listWithLoaded[i].name] then
      error("s")
    end
    
    ss.list.loaded[listWithLoaded[i].name] = listWithLoaded[i]
  end
  
  ss.list.isThereLoadedScenes = true
end

ss.unload = function(...)
  
end

ss.activate = function(...)
  local list = {...}
  local localList = ss.list
  
  for i = 1, #list do
    local name = list[i]
    
    if localList.loaded[name] then
      localList.active[name] = localList.loaded[name]
    end
    
    localList.active[name].activate()
  end
  
  ss.generate()
  
  ss.list.isThereActiveScenes = true
end

ss.deactivate = function(...)
  local isAnySceneLeft = false
  local list = {...}
  local localList = ss.list
  local name
  
  for i = 1, #localList.activeSorted do
    localList.activeSorted[i].deactivate()
  end
  
  localList.activeSorted = {}
  
  for i = 1, #list do
    name = list[i]
    
    localList.active[name] = nil
  end
  
  ss.generate()
  
  -- If it manages to find at least something, then
  for _, _ in pairs(ss.list.active) do
    isAnySceneLeft = true
    break
  end

  ss.list.isThereActiveScenes = isAnySceneLeft
end
------------------------------------------------
ss.changeLayer = function()
  
end

ss.getLayer = function()
  
end

ss.func = function(functionProperties, ...)
  local argsForFunctions = {...}
  --[[
  
  functionProperties({"name", "scene"}, ...) -- if need to send to specific scene
  or
  functionProperties("name", ...) -- if send only to active scenes
  
  --]]
  
end

ss.sort = function()
  table.sort(ss.list.activeSorted, function(a, b)
    return a.layer < b.layer
  end)
end

ss.generate = function()
  local localList = ss.list
  localList.activeSorted = {}
    for _, scene in pairs(localList.active) do
      table.insert(localList.activeSorted, scene)
    end
    
    ss.sort()
end

return ss