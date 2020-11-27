--Modified version of cut vanilla pet action
starvingAction = {}

function starvingAction.enterWith(args)
  if not args.starvingAction then return nil end

  return {
    timer = 2,
    didEmote = false
  }
end

function starvingAction.update(dt, stateData)
  animator.setAnimationState("movement", "idle")

  stateData.timer = stateData.timer - dt

  if stateData.timer < 1 and not stateData.didEmote then
    emote("lowpower")
    stateData.didEmote = true
  elseif stateData.timer < 0 then
    return true, config.getParameter("actionParams.starving.cooldown", 3)
  else
    return false
  end
end
