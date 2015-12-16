function update()
end

function drawables()
  local blocked, placeable, empty =1,2,3

  local vehicleState = activeItemAnimation.animationParameter("vehicleState")

  if (vehicleState == empty) then
    return {{ }}
  else
    local vehicleImage = activeItemAnimation.animationParameter("vehicleImage")
    local spawnPosition = activeItemAnimation.ownerAimPosition()
    local highlightColour = {150, 255, 150, 96}

    if (vehicleState == blocked) then
      highlightColour = {255, 150, 150, 128}
    end

    return {{
      image = vehicleImage,
      position = spawnPosition,
      color = highlightColour,
      fullbright = true
    }}
  end
end