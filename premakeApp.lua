-- Load in sub app from it's premakeApp.lua file in Third_Party/SubApp/
local subApp = APP.GetThirdPartyApp("SubApp")
-- Load in sub lib from it's SubLib.lua file in Third_Party/
local subLib = APP.GetThirdPartyLibrary("SubLib")

-- Create PremakeProject app
local app = APP.GetOrCreateApp("PremakeProject")
app.kind = "ConsoleApp"

-- Add subApp as dependency of app
app.AddDependency(subApp[1])
-- Add subLib as dependency of app
app.AddDependency(subLib)
-- Add a custom state to the app that gets called when the filter is correct.
app.AddState("system:linux", function()
	defines({ "LINUX_BABY" })
end)
-- Add a custom state to the app that gets called when the filters are correct.
app.AddState({ "system:macosx or ios", "files:**.cpp" }, function()
	
end)

return { app }