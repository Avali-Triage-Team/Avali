--Modified version of vanilla pet action
inspectAction = {
}

function inspectAction.enterWith(args)
  if not args.inspectTarget or not args.approachDistance or self.inspected[args.inspectTarget] then return nil end

  return {
    inspectTarget = args.inspectTarget,
    approachDistance = args.approachDistance,
    followUpAction = args.followUpAction,
    inspected = false,
    runDistance = 5,
    inspectTimer = 1,
    approachTimer = 5,
    targetType = world.entityType(args.inspectTarget),
    targetName = world.entityName(args.inspectTarget)
  }
end

function inspectAction.update(dt, stateData)
  if not world.entityExists(stateData.inspectTarget) then return true end

  local targetPosition = world.entityPosition(stateData.inspectTarget)
  local targetDistance = world.magnitude(targetPosition, mcontroller.position())

  local running = targetDistance > stateData.runDistance

  if stateData.didEmote then
    stateData.inspectTimer = stateData.inspectTimer - dt
  end

  --Approach the target
  if not approachPoint(dt, targetPosition, stateData.approachDistance, running) then
    stateData.approachTimer = stateData.approachTimer - dt

    if stateData.approachTimer < 0 or self.pathing.stuck then
      return true, config.getParameter("actionParams.inspect.cooldown", 15)
    end

    return false
  elseif not stateData.didEmote then
    --emote("confused")
    stateData.didEmote = true
    animator.setAnimationState("movement", "inspect")
  end

  local toTarget = world.distance(targetPosition, mcontroller.position())
  mcontroller.controlFace(toTarget[1])

  --Form an opinion about the target
  if stateData.inspectTimer < 0 then

    if stateData.targetType == "itemDrop" or (stateData.targetType == "object" and stateData.targetName == "avalipetchargingstation") then
      inspectAction.inspectFood(stateData)
    end

    if stateData.targetType == "monster" then
      inspectAction.inspectMonster(stateData)
    end

    if stateData.targetType == "player" then
      inspectAction.inspectPlayer(stateData)
    end

    self.inspected[stateData.inspectTarget] = true
    stateData.inspected = true
    return true, config.getParameter("actionParams.inspect.cooldown", 15)
  end

  return false
end

function inspectAction.inspectFood(stateData)
  local itemName
  if stateData.targetType == "object" then
    itemName = world.containerItemAt(stateData.inspectTarget, 0).name
  elseif stateData.targetType == "itemDrop" then
    itemName = world.entityName(stateData.inspectTarget)
  end

  local foodLiking = itemFoodLiking(itemName)

  if foodLiking == nil then
    foodLiking = math.random(100)
    storage.foodLikings[itemName] = foodLiking
  end

  if foodLiking > 50 then
    emote("happy")
  else
    emote("sad")
  end
end

function inspectAction.inspectMonster(stateData)
  local monsterType = world.monsterType(stateData.inspectTarget)

  if monsterLiking == nil then
    monsterLiking = math.random(100) > 50
  end

  if monsterLiking then
    emote("happy")
  else
    emote("sad")
  end
end

function inspectAction.inspectPlayer(stateData)
  local uuid = world.entityUniqueId(stateData.inspectTarget)
  if not storage.knownPlayers[tostring(uuid)] then
    storage.knownPlayers[tostring(uuid)] = true
  end

  emote("happy")
end

function inspectAction.leavingState(stateData)
  status.modifyResource("curiosity", -20)
end
