local didInit=false
local oldInit=init
local oldUpdate=update

function init()
	if oldInit then oldInit() end
	didInit=true --prime it
end

function update(...)
	if oldUpdate then oldUpdate(...) end
	if didInit then
		if world.entityType(entity.id()) == "player" then --can't send radio messages to nonexistent entities. this is the case when players are loading in.
			local avaliproduce1=root.itemConfig("avaliproduce1") -- this should be a given, this is in Avali Triage
			local kirifruit=root.itemConfig("kirifruit") -- this is from FU.
			local avalitriagepatchitem=root.itemConfig("avalitriagepatchitem") -- this will be in the patch.
			if avaliproduce1 and kirifruit and not avalitriagepatchitem then
				world.sendEntityMessage(entity.id(),"queueRadioMessage","needfuavalitriagepatch")
			end
			didInit=false
		end
	end
end