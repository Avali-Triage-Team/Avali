--Modified version of vanilla pet action
eatAction = {
}

function eatAction.enterWith(args)
  if not args.eatTarget then return nil end

  if status.resource("hunger") < config.getParameter("actionParams.eat.minHunger", 40) then
    return nil
  end

  --Make sure the target is valid
  local entityType = world.entityType(args.eatTarget)
  if not world.entityExists(args.eatTarget) or (entityType ~= "itemDrop" and entityType ~= "object") then 
    return nil
  end

  return {
    targetId = args.eatTarget,
    approachDistance = config.getParameter("actionParams.eat.distance", 2),
    runDistance = 5,
    eatTimer = 2,
    approachTimer = 5,
    eating = false
  }
end

function eatAction.update(dt, stateData)
  if not world.entityExists(stateData.targetId) then return true end

  local targetPosition = world.entityPosition(stateData.targetId)
  local targetDistance = world.magnitude(targetPosition, mcontroller.position())

  local running = targetDistance > stateData.runDistance

  --Approach the target
  if not approachPoint(dt, targetPosition, stateData.approachDistance, running) then
    stateData.approachTimer = stateData.approachTimer - dt

    if stateData.approachTimer < 0 or self.pathing.stuck then
      return true, 5
    end

    return false
  end

  if stateData.eating == false then
    animator.setAnimationState("movement", "eat")
    stateData.eating = true
  end

  stateData.eatTimer = stateData.eatTimer - dt

  if stateData.eatTimer < 0 then
    local targetType = world.entityType(stateData.targetId)
    if (targetType == "itemDrop" and eatAction.consumeItemDrop(stateData)) or
       (targetType == "object" and not eatAction.foodInBowl(stateData.targetId)) or
       (targetType == "object" and eatAction.consumeFromObject(stateData)) then
      return true, config.getParameter("actionParams.eat.cooldown")
    end
  end

  return false
end

function eatAction.consumeItemDrop(stateData)
  local oldDropPosition = world.entityPosition(stateData.targetId)
  local itemDrop = world.takeItemDrop(stateData.targetId)
  if itemDrop then
    local foodLiking = itemFoodLiking(itemDrop.name)

    if foodLiking > 50 then
      emote("happy")
    else
      emote("sad")
    end

    local numEaten = math.min(itemDrop.count, math.ceil(status.resource("hunger") / 40))
    status.modifyResource("hunger", -40 * numEaten)

    if numEaten < itemDrop.count then
      world.spawnItem(itemDrop.name, oldDropPosition, itemDrop.count - numEaten, itemDrop.parameters)
    end

    return true
  end
end

function eatAction.foodInBowl(objectId)
  local item = world.containerItemAt(objectId, 0)
  if item then
    local foodLiking = itemFoodLiking(item.name)
    if foodLiking then
      return foodLiking
    end
  end
  return false
end

function eatAction.consumeFromObject(stateData)
  local foodLiking = eatAction.foodInBowl(stateData.targetId)
  
  local item = world.containerItemAt(stateData.targetId, 0)
  if item then
    if foodLiking and item.name == "avalibattery" and world.containerConsumeAt(stateData.targetId, 0, 0) then
        emote("recharged")
        status.modifyResource("hunger", -30)
        return true
      elseif foodLiking and world.containerConsumeAt(stateData.targetId, 0, 1) then
        emote("recharged")
        status.modifyResource("hunger", -40)
        return true
      end
  end

  return false
end
