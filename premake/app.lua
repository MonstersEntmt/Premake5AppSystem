local globalApp = {}
if not apps then
	apps = {}
end

function globalApp.third_party_app(name, currentPath)
	if apps[name] then
		return apps[name]
	end
	
	local module_path = "Third_Party/" .. name .. "/premakeApp.lua"
	local app = assert(loadfile(module_path))(currentPath .. "Third_Party/" .. name .. "/")
	app.warnings = "Off"
	apps[app.name] = app
	
	return app
end

function globalApp.third_party_library(name, currentPath)
	if apps[name] then
		return apps[name]
	end
	
	local module_path = "Third_Party/" .. name .. ".lua"
	local app = assert(loadfile(module_path))(currentPath .. "Third_Party/" .. name .. "/")
	app.warnings = "Off"
	apps[app.name] = app
	
	return app
end

function globalApp.app(name, currentPath)
	if apps[name] then
		return apps[name]
	end
	
	local app = {}
	
	app.name = name
	app.currentPath = currentPath
	app.dependencies = {}
	app.group = "Libs"
	app.location = "Build/%{_ACTION}"
	app.objectDir = "Output/" .. name .. "/Obj/"
	app.targetDir = "Output/" .. name .. "/Bin/"
	app.includeDir = name .. "/Include/"
	app.sourceDir = name .. "/Source/"
	app.resourceDir = name .. "/Assets/"
	app.debugDir = name .. "/Run/"
	app.warnings = "Default"
	
	app.states = {}
	
	apps[name] = app
	print("Created app " .. name)
	return app
end

function globalApp.addDependency(app, dependency)
	app.dependencies[dependency.name] = dependency
	print("Added dependency " .. dependency.name .. " to " .. app.name)
end

function globalApp.addState(app, state)
	table.insert(app.states, state)
end

local function getAllIncludeDirectories(app, includeDirs)
	table.insert(includeDirs, app.currentPath .. app.includeDir)
	for name, dep in pairs(app.dependencies) do
		getAllIncludeDirectories(dep, includeDirs)
	end
end

function globalApp.premakeApp(app)
	if app.premaked then
		return
	end

	local deps = {}
	local sysincludedirectories = {}
	for name, dep in pairs(app.dependencies) do
		table.insert(deps, name)
		globalApp.premakeApp(dep)
		getAllIncludeDirectories(dep, sysincludedirectories)
	end
	
	print("Premake function called on app " .. app.name)
	group(app.group)
	project(app.name)
	debugdir(app.debugDir)
	links(deps)
	location(app.currentPath .. app.location)
	xcodebuildresources(app.currentPath .. app.resourceDir)
	warnings(app.warnings)
	targetdir(app.targetDir)
	objdir(app.objectDir)
	includedirs(app.currentPath .. app.includeDir)
	sysincludedirs(sysincludedirectories)
	if app.files then
		local Files = {}
		for i, file in pairs(app.files) do
			table.insert(Files, app.currentPath .. file)
		end
		files(Files)
	else
		files({
			app.currentPath .. app.includeDir .. "**.h",
			app.currentPath .. app.includeDir .. "**.hpp",
			app.currentPath .. app.sourceDir .. "**.c",
			app.currentPath .. app.sourceDir .. "**.cpp"
		})
	end
	if app.kind then
		kind(app.kind)
	end
	
	for i, state in pairs(app.states) do
		filter(state.filter)
		state.premakeState()
	end
	
	filter({})
	
	app.premaked = true
end

function globalApp.premakeWorkspace(WorkspaceName, Platforms, Configurations, startApp)
	print("Premake workspace called with " .. startApp.name .. " as startup")
	workspace(WorkspaceName)
	platforms(Platforms)
	configurations(Configurations)
	for name, app in pairs(apps) do
		globalApp.premakeApp(app)
	end
	workspace(WorkspaceName)
	startproject(startApp.name)
end

return globalApp