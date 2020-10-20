-- Has to be here for sub apps and sub libs to work properly
local currentPath = ...

local globalApp = require("premake/app")

-- Load in sub app from it's premakeApp.lua file in third_part/SubApp/
local subApp = globalApp.third_party_app("SubApp", currentPath)
-- Load in sub lib from it's SubLib.lua file in third_party/
local subLib = globalApp.third_party_library("SubLib", currentPath)

-- Create PremakeProject app
local app = globalApp.app("PremakeProject", currentPath)
app.kind = "ConsoleApp"

-- Add subApp as dependency of app
globalApp.addDependency(app, subApp)
-- Add subLib as dependency of app
globalApp.addDependency(app, subLib)
-- Add a custom state to the app that gets called when filter is correct.
globalApp.addState(app, { filter = "system:linux", premakeState = function()
	print("We are on linux baby!")
end})
-- Add a custom state to the app that gets called then the filter is correct.
globalApp.addState(app, { filter = { "system:macosx or ios", "files:**.cpp" }, premakeState = function()
	print("We are either on macosx or ios and we are setting data for all .cpp files")
end})

return app