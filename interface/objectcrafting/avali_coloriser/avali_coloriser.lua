require "/scripts/util.lua"
require "/scripts/interp.lua"

function init()
    self.itemTag = config.getParameter("itemTag")
	colorInfo = root.assetJson("/interface/objectcrafting/avali_coloriser/avali_colors.config").colorInfo
    count = 1
	colorAmount = colorAmount()
	change = -1
	itemNew = reload()
end

function update(dt)
	item = root.itemConfig(world.containerItemAt(pane.containerEntityId(),0))
	itemNew = reload()
end

function colorAmount()
	colorCount = 0
	for _, _ in pairs (colorInfo) do
		colorCount = colorCount + 1
	end
	return colorCount
end

function reload()
  info = colorInfo[count]
  if info then
    widget.setText("lblText", info.name)
    change = -1
    return info
  end
  changeColor()
	widget.setText("lblText", "")
end

function nextColor()
	change = 1
	changeColor()
end

function previousColor()
	change = -1
	changeColor()
end

function changeColor()
	count = count + change
	if count < 1 then
		count = colorAmount
	elseif count > colorAmount then
		count = 1
	end
end

function colorise()
  itemOld = world.containerItemAt(pane.containerEntityId(),0)

  local rootItemConfig = root.itemConfig(itemOld)
  local itemConfig = rootItemConfig.config

  if hasValue(itemConfig .itemTags, self.itemTag) or hasValue(itemOld.itemTags, self.itemTag) then
    world.containerTakeAt(pane.containerEntityId(),0)
    world.containerAddItems(pane.containerEntityId(), {name = itemOld.name, count = itemOld.count, parameters = getNewParameters()})
  end
end

function hasValue(tab, val)
    if type(tab) ~= "table" then return false end
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

function getNewParameters()
	itemConfig = root.itemConfig(itemNew)
	if count ~= 0 then
		info = colorInfo[count]
	end
	newParameters = {}
  if item then
    shortDescriptionNew = item.config.shortdescription .. " (" .. info.name .. ")"
    newParameters = util.mergeTable(newParameters, {shortdescription = shortDescriptionNew})
  end
  colorNew = info.value
  newParameters = util.mergeTable(newParameters, {color = colorNew})
	return newParameters
end