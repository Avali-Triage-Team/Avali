--Copy of vanilla pet action to prevent conflicts with pet overhauls
followAction = {}

function followAction.enterWith(args)
  if not args.followTarget then return nil end

  local startDistance = config.getParameter("actionParams.follow.startDistance", 6)
  local targetPosition = world.entityPosition(args.followTarget)
  local targetDistance = world.magnitude(targetPosition, mcontroller.position())
  if targetDistance < startDistance or not entity.entityInSight(args.followTarget) then
    return nil
  end

  return { 
    targetId = args.followTarget,
    stopDistance = config.getParameter("actionParams.follow.stopDistance", 3),
    startDistance = startDistance,
    runDistance = config.getParameter("actionParams.follow.runDistance", 20),
    curiosityDelta = config.getParameter("actionParams.follow.curiosityDelta", -5),
    running = false,
    waiting = false,
    boredTimer = config.getParameter("actionParams.follow.boredTime", 3)
  }
end

function followAction.update(dt, stateData)
  if not world.entityExists(stateData.targetId) then return true end

  local targetPosition = world.entityPosition(stateData.targetId)
  local targetDistance = world.magnitude(targetPosition, mcontroller.position())

  if targetDistance > stateData.runDistance then
    stateData.running = true
  end

  if targetDistance > stateData.startDistance then
    stateData.waiting = false
  end

  if not stateData.waiting and approachPoint(dt, targetPosition, stateData.stopDistance, stateData.running) then
    stateData.waiting = true
    stateData.running = false

    stateData.boredTimer = stateData.boredTimer - dt
    if stateData.boredTimer <= 0 or self.pathing.stuck then
      return true, config.getParameter("actionParams.follow.cooldown", 15)
    end
  elseif stateData.waiting then
    setIdleState()
  end

  status.modifyResource("curiosity", stateData.curiosityDelta * dt)

  if status.resource("curiosity") <= 0 or self.pathing.stuck then
    return true, config.getParameter("actionParams.follow.cooldown", 15)
  end
end
