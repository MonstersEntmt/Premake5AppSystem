newoption({
	trigger = "verbose",
	description = "Print debug info"
})

local function deepcopy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[deepcopy(orig_key)] = deepcopy(orig_value)
		end
		setmetatable(copy, deepcopy(getmetatable(orig)))
	else -- number, string, boolean, etc
		copy = orig
	end
	return copy
end

local APP = {
	workspaceName = "Workspace",
	platforms = {},
	configurations = {
		"Debug",
		"Release"
	},
	apps = {},
	startApp = nil,
	state = {
		verbose = _OPTIONS["verbose"],
		currentPath = "",
		filename = "premake5.lua",
		filepath = "premake5.lua",
		includeDir = "inc/",
		sourceDir = "src/",
		debugDir = "run/",
		thirdPartyDir = "Third_Party/",
		globalStates = {
			{
				filter = {},
				func = function(app)
					defines({ "_CRT_SECURE_NO_WARNINGS" })
					
					filter("configurations:Debug")
						optimize("Off")
						symbols("On")
						defines({ "_DEBUG", "NRELEASE" })
					
					filter("configurations:Release")
						optimize("Full")
						symbols("Off")
						defines({ "_RELEASE", "NDEBUG" })
						
					filter("system:windows")
						toolset("msc")
						defines({ "NOMINMAX" })
					
					filter("system:not windows")
						toolset("gcc")
					
					filter("system:linux")
						debugenvs({ "LD_LIBRARY_PATH=$LD_LIBRARY_PATH:../%{OUTDIR}" })
				end
			}
		}
	},
	stateStack = {}
}

local function AddDefaultPlatforms()
	if _ACTION == "android-studio" then
		APP.AddPlatform("armeabi-v7a")
		APP.AddPlatform("arm64-v8a")
		APP.AddPlatform("x86")
		APP.AddPlatform("x86_64")
		return
	end
	
	if os.ishost("windows") then
		APP.AddPlatform("x64")
		return
	end
	
	local arch = os.outputof("uname -m")
	APP.AddPlatform(arch)
end

local function boolToString(bool)
	if bool then
		return "true"
	else
		return "false"
	end
end

function APP.DebugLogState()
	print("--------------------------")
	print("|  Premake App State")
	print("|> Verbose: '" .. boolToString(APP.state.verbose) .. "'")
	print("|> Current Path: '" .. APP.state.currentPath .. "'")
	print("|> Filename: '" .. APP.state.filename .. "'")
	print("|> Filepath: '" .. APP.state.filepath .. "'")
	print("|> Include Dir: '"  .. APP.state.includeDir .. "'")
	print("|> Source Dir: '" .. APP.state.sourceDir .. "'")
	print("|> Debug Dir: '" .. APP.state.debugDir .. "'")
	print("|> Third Party Dir: '" .. APP.state.thirdPartyDir .. "'")
	print("--------------------------")
end

function APP.SetWorkspaceName(workspaceName)
	APP.workspaceName = workspaceName
	if APP.IsVerbose() then
		print("Set workspace name to '" .. workspaceName .. "'")
	end
end

function APP.AddPlatform(platform)
	table.insert(APP.platforms, platform)
	if APP.IsVerbose() then
		print("Added platform '" .. platform .. "' to the workspace")
	end
end

function APP.ClearPlatforms()
	APP.platforms = {}
	if APP.IsVerbose() then
		print("Cleared all platforms from the workspace")
	end
end

function APP.AddConfiguration(configuration)
	table.insert(APP.configurations, configuration)
	if APP.IsVerbose() then
		print("Added configuration '" .. configuration .. "' to the workspace")
	end
end

function APP.ClearConfigurations()
	APP.configurations = {}
	if APP.IsVerbose() then
		print("Cleared all configurations from the workspace")
	end
end

function APP.SetStartApp(app)
	APP.startApp = app
	if APP.IsVerbose() then
		print("Set startup app to '" .. app.name .. "'")
	end
end

function APP.IsVerbose()
	return APP.state.verbose
end

function APP.SetIncludeDir(includeDir)
	APP.state.includeDir = includeDir
	if APP.IsVerbose() then
		print("Set include dir to '" .. includeDir .. "'")
	end
end

function APP.SetSourceDir(sourceDir)
	APP.state.sourceDir = sourceDir
	if APP.IsVerbose() then
		print("Set source dir to '" .. sourceDir .. "'")
	end
end

function APP.SetDebugDir(debugDir)
	APP.state.debugDir = debugDir
	if APP.IsVerbose() then
		print("Set debug dir to '" .. debugDir .. "'")
	end
end

function APP.SetThirdPartyDir(thirdPartyDir)
	APP.state.thirdPartyDir = thirdPartyDir
	if APP.IsVerbose() then
		print("Set third party dir to '" .. thirdPartyDir .. "'")
	end
end

function APP.AddGlobalState(filter, func)
	table.insert(APP.state.globalStates, { filter = filter, func = func })
	if APP.IsVerbose() then
		if type(filter) == "table" then
			local str = "Added global state { "
			for i, flt in pairs(filter) do
				str = str .. "'" .. flt .. "'"
				if i < #filter then
					str = str .. ", "
				end
			end
			print(str .. " }")
		else
			print("Added global state '" .. filter .. "'")
		end
	end
	return #APP.state.globalStates
end

function APP.RemoveGlobalState(index)
	if index > 1 and index < #APP.state.globalStates then
		APP.state.globalStates[index] = nil
	end
end

function APP.PushState()
	table.insert(APP.stateStack, deepcopy(APP.state))
	APP.state.includeDir = "/inc/"
	APP.state.sourceDir = "/src/"
	APP.state.debugDir = "/run/"
	APP.state.thirdPartyDir = "Third_Party/"
end

function APP.PopState()
	APP.state = deepcopy(table.remove(APP.stateStack))
end

function APP.GetApp(appName, moduleFile)
	if not moduleFile then
		moduleFile = "premakeApp.lua"
	end
	
	while string.sub(appName, -1, -1) == "/" do
		appName = string.sub(appName, 1, -2)
	end
	
	if APP.IsVerbose() then
		print("Getting App '" .. appName .. "'")
	end
	local lastPathDivisor = string.find(appName, "/[^/]*$")
	if not lastPathDivisor then
		lastPathDivisor = 0
	end
	local path = string.sub(appName, 1, lastPathDivisor)
	local name = string.sub(appName, lastPathDivisor + 1)
	local modulePath
	if moduleFile == "premakeApp.lua" then
		modulePath = appName .. "/premakeApp.lua"
	else
		modulePath = path .. moduleFile
	end
	APP.PushState()
	APP.state.currentPath = APP.state.currentPath .. path .. name .. "/"
	APP.state.filename = moduleFile
	APP.state.filepath = APP.state.currentPath .. moduleFile
	if APP.IsVerbose() then
		APP.DebugLogState()
	end
	local ret = dofile(modulePath)
	APP.PopState()
	return ret
end

function APP.GetLibrary(libraryName)
	local lastPathDivisor = string.find(libraryName, "/[^/]*$")
	if not lastPathDivisor then
		lastPathDivisor = 0
	end
	local name = string.sub(libraryName, lastPathDivisor + 1)
	return APP.GetApp(libraryName, name .. ".lua")
end

function APP.GetThirdPartyApp(appName, moduleFile)
	return APP.GetApp(APP.state.thirdPartyDir .. appName, moduleFile)
end

function APP.GetThirdPartyLibrary(libraryName)
	local lastPathDivisor = string.find(libraryName, "/[^/]*$")
	if not lastPathDivisor then
		lastPathDivisor = 0
	end
	local name = string.sub(libraryName, lastPathDivisor + 1)
	return APP.GetApp(APP.state.thirdPartyDir .. libraryName, name .. ".lua")
end

function APP.GetLocalApp()
	if APP.IsVerbose() then
		print("Getting Local App")
	end
	APP.PushState()
	APP.state.filename = "premakeApp.lua"
	APP.state.filepath = APP.state.currentPath .. "premakeApp.lua"
	if APP.IsVerbose() then
		APP.DebugLogState()
	end
	local ret = dofile("premakeApp.lua")
	APP.PopState()
	return ret
end

function APP.GetOrCreateApp(name)
	if APP.apps[name] then
		return APP.apps[name]
	end
	
	local app = {}
	app.name = name
	app.kind = nil
	local groupStrEnd = string.find(APP.state.filepath, "/[^/]*$")
	if groupStrEnd then
		app.group = string.sub(APP.state.filepath, 1, groupStrEnd)
	else
		app.group = ""
	end
	app.currentPath = APP.state.currentPath
	app.location = app.currentPath .. name .. "/"
	app.objectDir = "Output/Int-" .. app.name .. "-%{cfg.platform}-%{cfg.buildcfg}/"
	app.outputDir = "Output/Bin-%{cfg.platform}-%{cfg.buildcfg}/"
	app.libraryDir = "Output/Lib-%{cfg.platform}-%{cfg.buildcfg}/"
	app.includeDir = APP.state.includeDir
	app.sourceDir = APP.state.sourceDir
	app.debugDir = APP.state.debugDir
	app.addLink = true
	app.cppDialect = "C++17"
	app.rtti = "Off"
	app.exceptionHandling = "On"
	app.warnings = "Default"
	app.usePCH = false
	app.pchHeader = ""
	app.pchSource = ""
	app.privateIncludeDirs = {}
	app.dependencies = {}
	app.states = {}
	app.recursiveStates = {}
	app.files = {}
	app.libs = {}
	app.flags = { "MultiProcessorCompile" }
	
	app.ToString = function()
		local str = "name = '" .. app.name .. "'\n"
		if app.kind then
			str = str .. "kind = '" .. app.kind .. "'\n"
		else
			str = str .. "kind = 'Unknown'\n"
		end
		str = str .. "group = '" .. app.group .. "'\n"
		str = str .. "currentPath = '" .. app.currentPath .. "'\n"
		str = str .. "location = '" .. app.location .. "'\n"
		str = str .. "objectDir = '" .. app.objectDir .. "'\n"
		str = str .. "outputDir = '" .. app.outputDir .. "'\n"
		str = str .. "libraryDir = '" .. app.libraryDir .. "'\n"
		str = str .. "includeDir = '" .. app.includeDir .. "'\n"
		str = str .. "sourceDir = '" .. app.sourceDir .. "'\n"
		str = str .. "debugDir = '" .. app.debugDir .. "'\n"
		str = str .. "addLink = '" .. boolToString(app.addLink) .. "'\n"
		str = str .. "cppDialect = '" .. app.cppDialect .. "'\n"
		str = str .. "rtti = '" .. app.rtti .. "'\n"
		str = str .. "exceptionHandling = '" .. app.exceptionHandling .. "'\n"
		str = str .. "usePCH = '" .. boolToString(app.usePCH) .. "'\n"
		str = str .. "pchHeader = '" .. app.pchHeader .. "'\n"
		str = str .. "pchSource = '" .. app.pchSource .. "'\n"
		str = str .. "warnings = '" .. app.warnings .. "'\n"
		str = str .. "privateIncludeDirs = '" .. #app.privateIncludeDirs .. "'\n"
		str = str .. "dependencies = '" .. #app.dependencies .. "'\n"
		str = str .. "states = '" .. #app.states .. "'\n"
		str = str .. "recursiveStates = '" .. #app.recursiveStates .. "'\n"
		str = str .. "files = '" .. #app.files .. "'\n"
		str = str .. "libs = '" .. #app.libs .. "'\n"
		str = str .. "flags = '" .. #app.flags .. "'"
		return str
	end
	
	app.GetLocalFilePath = function(file)
		return app.location .. file
	end
	
	app.GetAllIncludedDirectories = function(includeDirs)
		table.insert(includeDirs, app.GetLocalFilePath(app.includeDir))
		for name, dep in pairs(app.dependencies) do
			dep.GetAllIncludedDirectories(includeDirs)
		end
	end
	
	app.SetPCH = function(pchHeader, pchSource)
		app.usePCH = true
		app.pchHeader = pchHeader
		app.pchSource = pchSource
		if APP.IsVerbose() then
			print("Set PCH header to '" .. pchHeader .. "' and source to '" .. pchSource .. "' to '" .. app.name .. "'")
		end
	end
	
	app.AddPrivateIncludeDir = function(includeDir)
		table.insert(app.privateIncludeDirs, includeDir)
		if APP.IsVerbose() then
			print("Added private include dir '" .. includeDir .. "' to '" .. app.name .. "'")
		end
	end
	
	app.AddDependency = function(dependency)
		app.dependencies[dependency.name] = dependency
		if APP.IsVerbose() then
			print("Added dependency '" .. dependency.name .. "' to '" .. app.name .. "'")
		end
	end
	
	app.GetAllRecursiveStates = function(states)
		for _, recursiveState in pairs(app.recursiveStates) do
			table.insert(states, recursiveState)
		end
		for name, dep in pairs(app.dependencies) do
			dep.GetAllRecursiveStates(states)
		end
	end
	
	app.AddState = function(filter, func, isRecursive)
		if not isRecursive then
			isRecursive = false
		end
		
		if isRecursive then
			table.insert(app.recursiveStates, { filter = filter, func = func })
		else
			table.insert(app.states, { filter = filter, func = func })
		end
		
		if APP.IsVerbose() then
			if type(filter) == "table" then
				local str = "Added "
				if isRecursive then
					str = str .. "recursive "
				end
				str = str .. "state { "
				for i, flt in pairs(filter) do
					str = str .. "'" .. flt .. "'"
					if i < #filter then
						str = str .. ", "
					end
				end
				print(str .. " } to '" .. app.name .. "'")
			else
				if isRecursive then
					print("Added recursive state '" .. filter .. "' to '" .. app.name .. "'")
				else
					print("Added state '" .. filter .. "' to '" .. app.name .. "'")
				end
			end
		end
	end
	
	app.AddFile = function(file)
		table.insert(app.files, file)
		if APP.IsVerbose() then
			print("Added file '" .. file .. "' to '" .. app.name .. "'")
		end
	end
	
	app.AddLib = function(lib)
		table.insert(app.libs, lib)
		if APP.IsVerbose() then
			print("Added lib '" .. lib .. "' to '" .. app.name .. "'")
		end
	end
	
	app.AddFlag = function(flag)
		table.insert(app.flags, flag)
		if APP.IsVerbose() then
			print("Added flag '" .. flag .. "' to '" .. app.name .. "'")
		end
	end
	
	APP.apps[name] = app
	if APP.IsVerbose() then
		print("Created App '" .. name .. "'")
	end
	return app
end

function APP.PremakeApp(app)
	if app.premaked then
		return
	end
	
	local deps = {}
	local sysIncludeDirectories = {}
	for name, dep in pairs(app.dependencies) do
		APP.PremakeApp(dep)
		
		for _, lib in pairs(dep.libs) do
			table.insert(deps, dep.GetLocalFilePath(lib))
		end
		
		if dep.addLink then
			table.insert(deps, name)
		end
		
		dep.GetAllIncludedDirectories(sysIncludeDirectories)
	end
	
	if APP.IsVerbose() then
		print("Premake function called on app '" .. app.name .. "'")
	end
	group(app.group)
	
	project(app.name)
	
	cppdialect(app.cppDialect)
	rtti(app.rtti)
	exceptionhandling(app.exceptionHandling)
	flags(app.flags)
	
	location(app.location)
	objdir(app.objectDir)
	includedirs(app.GetLocalFilePath(app.includeDir))
	local PrivateIncludeDirs = {}
	for _, includeDir in pairs(app.privateIncludeDirs) do
		table.insert(PrivateIncludeDirs, app.GetLocalFilePath(includeDir))
	end
	includedirs(PrivateIncludeDirs)
	sysincludedirs(sysIncludeDirectories)
	local Files = {}
	for _, file in pairs(app.files) do
		table.insert(Files, app.GetLocalFilePath(file))
	end
	if #Files > 0 then
		files(Files)
	else
		files({
			app.GetLocalFilePath(app.includeDir .. "**.h"),
			app.GetLocalFilePath(app.includeDir .. "**.hpp"),
			app.GetLocalFilePath(app.sourceDir .. "**.h"),
			app.GetLocalFilePath(app.sourceDir .. "**.hpp"),
			app.GetLocalFilePath(app.sourceDir .. "**.c"),
			app.GetLocalFilePath(app.sourceDir .. "**.cpp")
		})
	end
	debugdir(app.GetLocalFilePath(app.debugDir))
	xcodebuildresources(app.GetLocalFilePath(app.debugDir))
	
	if app.usePCH then
		pchheader(app.pchHeader)
		pchsource(app.GetLocalFilePath(app.sourceDir .. app.pchSource))
	end
	
	links(deps)
	warnings(app.warnings)
	
	if app.kind then
		kind(app.kind)
	end
	
	for _, state in pairs(APP.state.globalStates) do
		if state then
			filter(state.filter)
			state.func(app)
		end
	end
	
	local recursiveStates = {}
	app.GetAllRecursiveStates(recursiveStates)
	for _, state in pairs(recursiveStates) do
		if state then
			filter(state.filter)
			state.func(app)
		end
	end
	
	for _, state in pairs(app.states) do
		if state then
			filter(state.filter)
			state.func(app)
		end
	end
	
	if project().kind == "StaticLib" or project().kind == "SharedLib" then
		targetdir(app.libraryDir)
	else
		targetdir(app.outputDir)
	end
	
	filter({})
	
	app.premaked = true
end

function APP.PremakeWorkspace()
	local startAppName
	if APP.startApp then
		startAppName = APP.startApp.name
	else
		if #APP.apps > 0 then
			startAppName = APP.apps[1].name
		else
			startAppName = ""
		end
	end
	
	if APP.IsVerbose() then
		print("Premake workspace called with '" .. startAppName .. "' as startup project")
	end
	
	workspace(APP.workspaceName)
	platforms(APP.platforms)
	configurations(APP.configurations)
	startproject(startAppName)
	for _, app in pairs(APP.apps) do
		APP.PremakeApp(app)
	end
end

AddDefaultPlatforms()

return APP