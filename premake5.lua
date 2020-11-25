-- Require the premake app system globally
APP = require("premake/app")
UTILS = require("premake/utils")

-- Set workspace name
-- Add platforms and configurations
APP.SetWorkspaceName("Premake Workspace")
UTILS.AddPlatforms()
UTILS.AddConfigurations()

-- Get the local app at "premakeApp.lua"
local apps = APP.GetLocalApp()

-- Set the Startup app as the first app from the local app
-- apps might be a single element too, this depends on what
-- you put inside the local "premakeApp.lua" file.
APP.SetStartApp(apps[1])

-- Call the premake functions
APP.PremakeWorkspace()