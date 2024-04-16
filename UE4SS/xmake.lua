
if is_plat("windows") then
    includes("proxy_generator")
end

if has_config("GUI") then 
    add_requires("imgui v1.89", { debug = is_mode_debug(), configs = { win32 = true, dx11 = true, opengl3 = true, glfw_opengl3 = true, runtimes = get_mode_runtimes() } })
elseif has_config("TUI") then
    add_requires("imtui v1.0.5", { debug = is_mode_debug(), configs = { runtimes = get_mode_runtimes() } })
end

if has_config("UI") then
    add_requires("ImGuiTextEdit v1.0", { debug = is_mode_debug(), configs = { runtimes = get_mode_runtimes() } })
end

if has_config("GUI") then
    add_requires("IconFontCppHeaders v1.0", { debug = is_mode_debug(), configs = { runtimes = get_mode_runtimes() } })
    add_requires("glfw 3.3.9", { debug = is_mode_debug(), configs = { runtimes = get_mode_runtimes() } })
    add_requires("opengl", { debug = is_mode_debug(), configs = { runtimes = get_mode_runtimes() } })
end

option("ue4ssBetaIsStarted")
    set_default(true)
    set_showmenu(true)
    set_values(true, false)

    set_description("Have beta releases started for the current major version")

option("ue4ssIsBeta")
    set_default(true)
    set_showmenu(true)
    set_values(true, false)

    set_description("Is this a beta release")

local projectName = "UE4SS"

local function parse_version_string(str)
    local matches = {}
    for match in str:gmatch("(%d+)") do
        table.insert(matches, match)
    end

    return {
        ["major"] = matches[1],
        ["minor"] = matches[2],
        ["hotfix"] = matches[3],
        ["prerelease"] = matches[4],
        ["beta"] = matches[5]
    }
end

target(projectName)
    set_kind("shared")
    set_languages("cxx20")
    set_exceptions("cxx")
    set_default(true)

    add_options("ue4ssBetaIsStarted", "ue4ssIsBeta")

    add_includedirs("include", { public = true })
    add_includedirs("generated_include", { public = true })
    add_headerfiles("include/**.hpp")
    add_headerfiles("generated_include/*.hpp")

    add_files("src/**.cpp|Platform/**.cpp|GUI/**.cpp")
    
    if has_config("UI") then
        add_files("src/GUI/*.cpp")
        if is_plat("windows") then
            -- we think by deafult windows have everything just for easy... 
            -- but this maybe not the case
            add_files("src/GUI/Platform/D3D11/**.cpp")
            add_files("src/GUI/Platform/GLFW/**.cpp")
            add_files("src/GUI/Platform/GUI/**.cpp")
            add_files("src/GUI/Platform/Windows/**.cpp")
        else
            if has_config("GUI") then
                add_files("src/GUI/Platform/GUI/**.cpp")
                add_files("src/GUI/Platform/GLFW/**.cpp")
            end
            if has_config("TUI") then 
                add_files("src/GUI/Platform/TUI/**.cpp")
            end
        end
    end

    add_deps(
        "File", "DynamicOutput", "Unreal",
        "SinglePassSigScanner", "LuaMadeSimple", "Function",
        "IniParser", "JSON", 
        "Constructs", "Helpers", "MProgram",
        "ScopedTimer", "Profiler", "patternsleuth_bind",
        "glad", { public = true }
    )

    add_options("UI", "GUI", "TUI", "Input")

    add_deps("Input", { public = true })
    
    if is_plat("windows") then
        add_files("src/Platform/Win32/CrashDumper.cpp")
        add_files("src/Platform/Win32/EntryWin32.cpp")
        if has_config("GUI") then
            add_packages("ImGui", "ImGuiTextEdit", "IconFontCppHeaders", "glfw", "opengl", { public = true })
            add_links("d3d11", { public = true })
        end
    elseif is_plat("linux") then
        add_files("src/Platform/Linux/EntryLinux.cpp")
        if has_config("GUI") then
            add_packages("ImGui", "ImGuiTextEdit", "IconFontCppHeaders", "glfw", "opengl", { public = true })
        elseif has_config("TUI") then
            add_packages("imtui", "ImGuiTextEdit", { public = true })
        end
    end
    
    add_packages("glaze", "polyhook_2", { public = true })

    after_load(function (target)
        local projectRoot = get_config("ue4ssRoot")

        local scriptsRoot = get_config("scriptsRoot")
        import("build_configs", { rootdir = scriptsRoot })
        import("target_helpers", { rootdir = scriptsRoot })
        
        print("Project: " .. projectName .. " (SHARED)")

        build_configs:set_output_dir(target)
        build_configs:export_deps(target)

        target:add("defines", target_helpers.project_name_to_exports_define(projectName))
        
        local version_string = io.readfile(path.join(target:scriptdir(), "generated_src/version.cache"))
        local version = parse_version_string(version_string)

        target:add("defines", "UE4SS_LIB_VERSION_MAJOR=" .. version.major, { public = true })
        target:add("defines", "UE4SS_LIB_VERSION_MINOR=" .. version.minor, { public = true })
        target:add("defines", "UE4SS_LIB_VERSION_HOTFIX=" .. version.hotfix, { public = true })
        target:add("defines", "UE4SS_LIB_VERSION_PRERELEASE=" .. version.prerelease, { public = true })
        target:add("defines", "UE4SS_LIB_VERSION_BETA=" .. version.beta, { public = true })
        
        target:add("defines", "UE4SS_LIB_BETA_STARTED=" .. (get_config("ue4ssBetaIsStarted") and "1" or "0"), { public = true })
        target:add("defines", "UE4SS_LIB_IS_BETA=" .. (get_config("ue4ssIsBeta") and "1" or "0"), { public = true })

        local git_dir = path.join(projectRoot, ".git")
        local outdata, _ = os.iorunv("git", {"--git-dir=" .. git_dir, "--work-tree=" .. projectRoot, "rev-parse", "--short", "HEAD"})
        local commit_hash = outdata:gsub("%s+$", "")
        target:add("defines", "UE4SS_LIB_BUILD_GITSHA=\"" .. commit_hash .. "\"", { public = true })
        
        target:add("defines", "UE4SS_CONFIGURATION=\"" .. get_config("mode") .. "\"", { public = true })
    end)

