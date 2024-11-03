std = "lua53c"
max_line_length = 200
ignore = {
	-- due to how Starbound isolates Lua files, not using "local" for these variables is not a problem.
	"111", -- "setting non-standard global variable [...]"
	"112", -- "mutating non-standard global variable [...]"
	"113" -- "accessing undefined variable [...]"
}
-- These global variables are allowed.
globals = {
	"item",
	"self",
	"storage"
}
-- These global variables are allowed, but can't be modified.
-- These are mainly things from https://starbounder.org/Modding:Lua
read_globals = {
	"config",
	"entity",
	"monster",
	"npc",
	"object",
	"player",
	"root",
	"world"
}
codes = true -- Show luacheck's error/warning codes. Useful for adding exceptions.
-- Ignore "unused argument self" (W212) in object-oriented methods like widgetBase:hasMouse()
self = false
exclude_files = {
	"**/*unused*",
	"**/*UNUSED*"
}