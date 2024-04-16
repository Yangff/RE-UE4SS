set_config("ue4ssRoot", os.curdir())
set_config("scriptsRoot", path.join(os.curdir(), "tools/xmakescripts"))

includes("tools/xmakescripts/build_configs.lua")
includes("tools/xmakescripts/configurations.lua")

add_rules(get_unreal_rules())

-- Restrict the compilation modes/configs.
set_allowedplats("windows", "linux")
if is_plat("windows") then
    set_allowedarchs("x64")
elseif is_plat("linux") then
    set_allowedarchs("x86_64")
    set_defaultarchs("x86_64")
    set_toolchains("clang", "rust")
end
set_allowedmodes(get_compilation_modes())

if is_plat("windows") then
    set_defaultmode("Game__Shipping__Win64")
    set_runtimes(get_mode_runtimes())
elseif is_plat("linux") then
    set_defaultmode("Game__Shipping__Linux")
end

-- All non-binary outputs are stored in the Intermediates dir.
set_config("buildir", "Intermediates")

-- Tell WinAPI macros to map to unicode functions instead of ansi
add_defines("_UNICODE", "UNICODE")

after_load(function (target)
    import("build_configs", { rootdir = get_config("scriptsRoot") })
    import("target_helpers", { rootdir = get_config("scriptsRoot") })
    build_configs:set_output_dir(target)
    build_configs:export_deps(target)
end)

on_config(function (target)
    import("build_configs", { rootdir = get_config("scriptsRoot") })
    build_configs:config(target)
    build_configs:set_project_groups(target)
end)

after_clean(function (target)
    import("build_configs", { rootdir = get_config("scriptsRoot") })
    build_configs:clean_output_dir(target)
end)

includes("deps")
includes("UE4SS")

if is_plat("windows") then
    includes("UVTD")
end
