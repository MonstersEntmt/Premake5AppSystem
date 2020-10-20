local ProjectName = "PremakeProject"

local globalApp = require("premake/app")
local app = assert(loadfile("premakeApp.lua"))("")
app.group = "Apps"

local utils = require("premake/utils")

globalApp.premakeWorkspace(ProjectName, utils.get_platforms(), { "Debug", "Release" }, app)