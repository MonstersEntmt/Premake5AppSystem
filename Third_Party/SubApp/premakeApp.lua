-- Create SubApp app
local lib = APP.GetLibrary("Lib/Lib")

local app = APP.GetOrCreateApp("SubApp")
app.kind = "StaticLib"
app.location = ""
app.includeDir = ""
app.sourceDir = ""
app.debugDir = "run/"

app.AddDependency(lib)

return { app, lib }