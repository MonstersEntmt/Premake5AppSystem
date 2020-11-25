# Premake5AppSystem
A premake5 system that allows apps with dependencies with more dependencies

# How it works
With normal premake projects you have a `premake5.lua` file that controls how premake5 operates in that project.
To make sure that other projects can include another project a fix had to be made.
That's where this premake5 system comes in.

All you need is the `premake/` folder
and a `premakeApp.lua` file that creates an app(s) and returns it.

To create a project you need a `premakeApp.lua` file that creates the app(s) using
```lua
local app = APP.GetOrCreateApp("app") -- Creates an app called 'app'
```

To use another project call one of the following functions in the `premakeApp.lua` file
```lua
local thirdPartyApp = APP.GetThirdPartyApp("ThirdPartyApp")          -- Loads a project at 'APP.thirdPartyFolder .. "ThirdPartyApp/premakeApp.lua"'
local thirdPartyLib = APP.GetThirdPartyLibrary("ThirdPartyLib")      -- Loads a project at 'APP.thirdPartyFolder .. "ThirdPartyApp.lua"
local customPathedApp = APP.GetApp("SomeFolder/CustomPathedApp")     -- Loads a project at '"SomeFolder/CustomPathedApp/premakeApp.lua"'
local customPathedLib = APP.GetLibrary("SomeFolder/CustomPathedLib") -- Loads a project at '"SomeFolder/CustomPathedLib.lua"'
```

You can change what 'APP.thirdPartyFolder' is using this function in the `premakeApp.lua` file
```lua
APP.SetThirdPartyFolder("ThirdParty")
```
Changing project properties can be done using variables in the app object. For help on what can be done visit the Wiki.

### Q. But how do I change premake stuff myself?<br>
A. Use State object and add that to the app with a filter of your choosing, making the filter = {} will make it work on anything.

### Q. Why does git detect some workspace files were include?<br>
A. This project does not have all the ignores specified in the `.gitignore` so if any are missing please open an issue and specify all the ignores that are missing.