-- Create SubApp lib
local app = APP.GetOrCreateApp("SubAppLib")
app.kind = "StaticLib"
app.location = ""
app.includeDir = ""
app.sourceDir = ""
app.debugDir = "run/"

return app