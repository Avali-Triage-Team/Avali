--Copy of vanilla pet action to prevent conflicts with pet overhauls
sleepAction = {
  cooldown = 10
}

function sleepAction.enterWith(args)
  if not args.sleepAction and not args.sleepTarget then return nil end

  if args.sleepAction and status.resourcePercentage("sleepy") < 1 then
    return nil
  end

  if args.sleepTarget and status.resource("sleepy") < config.getParameter("actions.sleep.minSleepy", 65) then
    return nil
  end

  return {
    targetId = args.sleepTarget,
    sleepRate = -5,
    sleeping = false
  }
end

function sleepAction.enteringState(stateData)
  if stateData.targetId then
    emote("sleepy")
  else
    animator.setParticleEmitterActive("sleep", true)
  end
end

function sleepAction.update(dt, stateData)
  if not stateData.sleeping then
    if not stateData.targetId then
      stateData.sleeping = true
      animator.setParticleEmitterActive("sleep", true)
    else
      if not world.entityExists(stateData.targetId) then return true end
      --Approach the target
      local targetPosition = world.entityPosition(stateData.targetId)
      if not approachPoint(dt, targetPosition, 1.5, false) then
        if self.pathing.stuck then
          return true, config.getParameter("actionParams.sleep.cooldown")
        end
        return false
      end

      animator.setParticleEmitterActive("sleep", true)
      local bounds = boundingBox()
      mcontroller.setPosition({targetPosition[1], targetPosition[2] - bounds[2]})
      stateData.sleeping = true
    end
  else
    status.modifyResource("sleepy", stateData.sleepRate * dt)
    if stateData.targetId then
      if not world.entityExists(stateData.targetId) then
        return true, config.getParameter("actionParams.sleep.cooldown", 15)
      end
      animator.setAnimationState("movement", "invisible")
    else
      animator.setAnimationState("movement", "sleep")
    end

    if status.resourcePercentage("sleepy") <= 0 then 
      return true, config.getParameter("actionParams.sleep.cooldown", 15)
    else
      return false
    end
  end
end

function sleepAction.leavingState(stateData)
  setIdleState()
  animator.setParticleEmitterActive("sleep", false)
end
