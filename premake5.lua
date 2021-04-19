-- Require the premake app system globally
APP = require("premake/app")

-- Set workspace name
APP.SetWorkspaceName("Workspace")

-- Get the local app at "premakeApp.lua"
local apps = APP.GetLocalApp()

-- Set the startup app as the first app from the local app
-- apps might be a single element too, this depeneds on what
-- you return from the "premakeApp.lua" file.
APP.SetStartApp(apps[1])

-- Call the premake functions
APP.PremakeWorkspace()