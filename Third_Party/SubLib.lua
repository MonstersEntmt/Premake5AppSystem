-- Create SubLib app
local app = APP.GetOrCreateApp("SubLib")
app.kind = "StaticLib"
app.location = ""
app.includeDir = ""
app.sourceDir = ""
app.debugDir = "run/"

return app