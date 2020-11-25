-- Create SubLib app
local app = APP.GetOrCreateApp("SubLib")
app.kind = "StaticLib"
app.location = ""
app.includeDir = ""
app.sourceDir = ""
app.resourceDir = "run/assets/"
app.debugDir = "run/"

return app