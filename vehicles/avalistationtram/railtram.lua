require "/scripts/rails.lua"

function init()
  message.setHandler("positionTileDamaged", function()
      if not world.isTileProtected(mcontroller.position()) then
        popVehicle()
      end
    end)

  mcontroller.setRotation(0)

  local railConfig = config.getParameter("railConfig", {})
  railConfig.facing = config.getParameter("initialFacing", 1)

  self.railRider = Rails.createRider(railConfig)
  self.railRider:init(storage.railStateData)

  self.driver = nil
end

function update(dt)
  if mcontroller.atWorldLimit() then
    vehicle.destroy()
    return
  end

  local driver = vehicle.entityLoungingIn("seat")
  if driver then
    if not self.driver then
      animator.setAnimationState("gate", "closing")
    end

    local upHeld = vehicle.controlHeld("seat", "up")
    local downHeld = vehicle.controlHeld("seat", "down")
    local leftHeld = vehicle.controlHeld("seat", "left")
    local rightHeld = vehicle.controlHeld("seat", "right")

    if not self.railRider.moving then
      if upHeld then
        resume(Rails.dirs.n)
      elseif downHeld then
        resume(Rails.dirs.s)
      elseif leftHeld then
        resume(Rails.dirs.w)
      elseif rightHeld then
        resume(Rails.dirs.e)
      end
    end

    if upHeld then
      animator.setAnimationState("controls", "up")
    elseif downHeld then
      animator.setAnimationState("controls", "down")
    elseif leftHeld then
      animator.setAnimationState("controls", "left")
    elseif rightHeld then
      animator.setAnimationState("controls", "right")
    else
      animator.setAnimationState("controls", "idle")
    end
    vehicle.setInteractive(false)
  else
    if self.driver then
      animator.setAnimationState("gate", "opening")
    end
    animator.setAnimationState("controls", "idle")
    vehicle.setInteractive(true)
  end
  self.driver = driver

  if mcontroller.isColliding() then
    popVehicle()
  else
    self.railRider:update(dt)
    storage.railStateData = self.railRider:stateData()
  end

  if self.railRider.onRailType and self.railRider.moving then
    animator.setAnimationState("rail", "on")
  else
    animator.setAnimationState("rail", "off")
  end
end

function resume(direction)
  self.railRider:railResume(self.railRider:position(), nil, direction)
  animator.playSound("activate")
end

function uninit()
  self.railRider:uninit()
end

function popVehicle()
  local popItem = config.getParameter("popItem")
  if popItem then
    world.spawnItem(popItem, entity.position(), 1)
  end
  vehicle.destroy()
end

function isRailTramAt(nodePos)
  if nodePos and vec2.eq(nodePos, self.railRider:position()) then
    return true
  end
end

