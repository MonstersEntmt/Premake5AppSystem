-- Create SubApp app
local app = APP.GetOrCreateApp("SubApp")
app.kind = "StaticLib"
app.location = ""
app.includeDir = ""
app.sourceDir = ""
app.resourceDir = "run/assets/"
app.debugDir = "run/"

return app