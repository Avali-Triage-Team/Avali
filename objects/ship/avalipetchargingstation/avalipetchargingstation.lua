function update(dt)
  local item = world.containerItemAt(entity.id(), 0)
  if item then
    if item.name == "avalismallbattery" then
      animator.setAnimationState("bowl", "full")
      return
    elseif item.name == "avalibattery" then
      animator.setAnimationState("bowl", "infinite")
      return
    end
  end

  animator.setAnimationState("bowl", "empty")
end
