require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
  --wake up, invent a unique key ID.
  if item.instanceValue("key") == nil then
    activeItem.setInstanceValue("key", sb.makeUuid())
  end

  blocked, placeable, empty =1,2,3

  self.vehicleBoundingBox=item.instanceValue("vehicleBoundingBox")

  if ( item.instanceValue("filled")) then
    self.vehicleState = blocked
  else
    self.vehicleState = empty
  end

  self.respawnTimer=0.0

  updateIcon()

  --Set the sprite to be drawn as a cursor
  activeItem.setScriptedAnimationParameter("vehicleImage", item.instanceValue("vehicleImage"))
  --set that the vehcile can't be instanciated here
  activeItem.setScriptedAnimationParameter("vehicleState",self.vehicleState)

  util.setDebug(true)
end

function activate(fireMode, shiftHeld)

  --do we have a vehicle on board ?
  if item.instanceValue("filled") then

    if fireMode == "primary" then 
      if (self.vehicleState==placeable) then
        --make a spawn noise and perhaps some particles.
        animator.playSound("placeOk")

        -- what kind, and where do we put it ?
        world.spawnVehicle(item.instanceValue("vehicleType"), activeItem.ownerAimPosition(), { ownerKey = item.instanceValue("key"), startHealthFactor = item.instanceValue("vehicleStartHealthFactor"), fromItem = true} )

        --not filled any more.
        activeItem.setInstanceValue("filled", false)

        self.vehicleState = empty
        activeItem.setScriptedAnimationParameter("vehicleState",self.vehicleState)
      else
        --Collision, make an "oh no" sound
        animator.playSound("placeBad")
      end
    end
  
  elseif self.consumePromise == nil then

    --currently empty. suck up the nearest vehicle to the cursor
    local vehicleId = world.entityQuery(activeItem.ownerAimPosition(), 0, {
      includedTypes = {"vehicle"}, order = "nearest"})[1]                          --only get one of them

    if vehicleId then
      --ask the vehicle if we can store it.
      self.consumePromise = world.sendEntityMessage(vehicleId, "store", item.instanceValue("key"))
    end
  end

  updateIcon()
end

function update()
  local spawnPosition = activeItem.ownerAimPosition()

  if ( item.instanceValue("filled")) then

    if (self.respawnTimer>0) then
      self.respawnTimer=self.respawnTimer-script.updateDt()
      self.vehicleState=empty
    else
      local vehicleBounds = {}
      vehicleBounds[1] = self.vehicleBoundingBox[1] + spawnPosition[1]  --Left
      vehicleBounds[2] = self.vehicleBoundingBox[2] + spawnPosition[2]  --Bot
      vehicleBounds[3] = self.vehicleBoundingBox[3] + spawnPosition[1]  --Right
      vehicleBounds[4] = self.vehicleBoundingBox[4] + spawnPosition[2]  --Top

      if (world.rectTileCollision(vehicleBounds, {"Null", "Block", "Dynamic"})) then
        self.vehicleState = blocked
        util.debugRect(vehicleBounds,"red")
      else
        self.vehicleState = placeable
        util.debugRect(vehicleBounds,"green")
      end
    end

  else
    if self.consumePromise then
      if self.consumePromise:finished() then

        local vehicleResult = self.consumePromise:result()    --so this is a json returned from the vehicle we want to store.

        if (vehicleResult) then
          activeItem.setInstanceValue("filled", vehicleResult.storable)
          self.respawnTimer=item.instanceValue("respawnTime")

          if vehicleResult.storable then
            --remember how healthy the vehicle was when we spawned
            activeItem.setInstanceValue("vehicleStartHealthFactor", vehicleResult.healthFactor)
          end
        end

        updateIcon()

        self.consumePromise = nil
      end
    end
  end

  --set whether the vehicle can be instanciated here
  --this is used to change the cursor from red to green.
  activeItem.setScriptedAnimationParameter("vehicleState",self.vehicleState)

end

function updateIcon()
  if item.instanceValue("filled") then
    animator.setAnimationState("controller", "full") 
    activeItem.setInventoryIcon(item.instanceValue("filledInventoryIcon"))
  else
    animator.setAnimationState("controller", "empty")
    activeItem.setInventoryIcon(item.instanceValue("emptyInventoryIcon"))
  end
end
