petBehavior = {
  actionQueue = {}
}

function petBehavior.init()
  petBehavior.entityTypeReactions = {
    ["player"] = petBehavior.reactToPlayer,
    ["itemDrop"] = petBehavior.reactToItemDrop,
    ["monster"] = petBehavior.reactToMonster,
    ["object"] = petBehavior.reactToObject
  }

  petBehavior.actions = {
    ["emote"] = petBehavior.emote
  }

  petBehavior.actionStates = {
    ["inspect"] = "inspectAction",
    ["follow"] = "followAction",
    ["eat"] = "eatAction",
    ["beg"] = "begAction",
    ["play"] = "pounceAction",
    ["sleep"] = "sleepAction",
    ["starving"] = "starvingAction"
  }

  self.currentActionScore = 0
  self.actionParams = config.getParameter("actionParams")
  self.actionInterruptThreshold = config.getParameter("actionParams.interruptThreshold", 15)
  self.inspected = {}
end

--Queue an action to later be sorted by score
--score is optional
function petBehavior.queueAction(type, args, score)
  table.insert(petBehavior.actionQueue, {type = type, args = args, score = score})
end

function petBehavior.performAction(action)
  if petBehavior.actions[action.type] and self.actionCooldowns[action.type] <= 0 and self.actionState.stateDesc() == "" then
    return petBehavior.actions[action.type](args)
  end

  return false
end

--Score all actions in the queue, then try them until one returns a success
function petBehavior.run()
  if self.actionState.stateDesc() == "" then
    self.currentActionScore = 0
  end

  --Add state actions to the reaction queue
  for actionName,_ in pairs(petBehavior.actionStates) do
    petBehavior.queueAction(actionName)
  end

  --Sort actions based on score
  for _,queuedAction in pairs(petBehavior.actionQueue) do
    queuedAction.score = queuedAction.score or petBehavior.scoreAction(queuedAction.type)
  end
  table.sort(petBehavior.actionQueue, function(a, b) return a.score > b.score end)

  --Pick the first valid option
  for _,action in pairs(petBehavior.actionQueue) do
    if action.score <= 0 or action.score <= self.currentActionScore + self.actionInterruptThreshold then break end

    local picked = false
    if not self.actionParams[action.type] or action.score > self.actionParams[action.type].minScore then
      if petBehavior.actionStates[action.type] and self.actionState.stateDesc() ~= petBehavior.actionStates[action.type] then
        if (action.args and self.actionState.pickState(action.args)) then
          picked = true
        elseif(petBehavior.actionStates[action.type] and self.actionState.pickState({[petBehavior.actionStates[action.type]] = true})) then
          picked = true
        end
      elseif petBehavior.actions[action.type] and petBehavior.performAction(action.type) then
        picked = true
      end
    end

    if picked then
      self.currentActionScore = action.score
      break
    end
  end

  petBehavior.actionQueue = {}
end

--Evaluate an action and set a weight
function petBehavior.scoreAction(action)
  if action == "eat" or action == "beg" then
    return status.resource("hunger")

  elseif action == "follow" then
    return status.resource("curiosity") - petBehavior.starvingLevel()

  elseif action == "inspect" then
    return status.resource("curiosity") - petBehavior.starvingLevel()

  elseif action == "play" then
    return status.resource("playful") - petBehavior.starvingLevel()

  elseif action == "sleep" then
    return status.resource("sleepy")

  elseif action == "starving" then
    return petBehavior.starvingLevel() - 20

  elseif action == "emote" then
    return 100 - petBehavior.starvingLevel()

  else
    return 0
  end
end

function petBehavior.starvingLevel()
  local hunger = status.resource("hunger")
  if hunger > config.getParameter("actionParams.hungerStarvingLevel") then
    return hunger
  else
    return 0
  end
end

----------------------------------------
--ENTITY REACTIONS
----------------------------------------

function petBehavior.reactTo(entityId)
  local entityType = world.entityType(entityId)

  if petBehavior.entityTypeReactions[entityType] then
    petBehavior.entityTypeReactions[entityType](entityId)
  end
end

function petBehavior.reactToPlayer(entityId)
  local playerUuid = world.entityUniqueId(entityId)

  --Check hands for goodies
  local primaryItem = world.entityHandItem(entityId, "primary")
  local altItem = world.entityHandItem(entityId, "alt")
  local foodLiking = itemFoodLiking(primaryItem) or itemFoodLiking(altItem)
  if foodLiking then
    local score = status.resource("hunger") - (100 - foodLiking)
    petBehavior.queueAction("beg", {begTarget = entityId}, score)
  end

  if storage.knownPlayers[tostring(playerUuid)] then
    petBehavior.queueAction("follow", {followTarget = entityId})
  else
    petBehavior.queueAction("inspect", {inspectTarget = entityId, approachDistance = 4})
  end
end

function petBehavior.reactToItemDrop(entityId)
--  local entityName = world.entityName(entityId)
--  local foodLiking = itemFoodLiking(entityName)
--  if foodLiking then
--    local score = math.max(status.resource("hunger") - (100 - foodLiking), petBehavior.starvingLevel())
--    petBehavior.queueAction("eat", {eatTarget = entityId}, score)
--  elseif foodLiking == nil then
--    petBehavior.queueAction("inspect", {inspectTarget = entityId, approachDistance = 2}, status.resource("hunger"))
--  end
end

function petBehavior.reactToMonster(entityId)
  local entityName = world.monsterType(entityId)
  if entityName == "petball" then
    petBehavior.queueAction("play", {pounceTarget = entityId})
  end
end

function petBehavior.reactToObject(entityId)
  local entityName = world.entityName(entityId)
  if entityName == "avalipetchargingstation" then
    local item = world.containerItemAt(entityId, 0)
    if item then
      local foodLiking = itemFoodLiking(item.name)
      if foodLiking then
        local score = math.max(status.resource("hunger") - (100 - foodLiking), petBehavior.starvingLevel())
        petBehavior.queueAction("eat", {eatTarget = entityId}, score)
      elseif foodLiking == nil then
        self.inspected[entityId] = false
        petBehavior.queueAction("inspect", {inspectTarget = entityId, approachDistance = 2}, status.resource("hunger"))
      end
    end
  end

  if entityName == "pethouse" then
    petBehavior.queueAction("sleep", {sleepTarget = entityId})
  end
--PURCHASEABLE PETS COMPAT
  if entityName == "petTrap" then
    status.setResource("health",0)
  end
--END PURCHASEABLE PETS COMPAT
end

----------------------------------------
--ACTIONS
----------------------------------------

function petBehavior.emote(emoteName)
  emote(emoteName)
  return false
end
