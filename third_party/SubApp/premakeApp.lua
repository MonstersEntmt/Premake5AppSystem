-- Has to be here for sub apps and sub libs to work properly
local currentPath = ...

 -- Should be "premake/app" in all projects but this is an example of the files.
local globalApp = require("../../premake/app")

-- Create SubApp app
local app = globalApp.app("SubApp", currentPath)
app.kind = "StaticLib"

return app