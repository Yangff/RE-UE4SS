-- We should use `get_config("ue4ssRoot")` instead of `os.projectdir()` or `$(projectdir)`.
-- This is because os.projectdir() will return a higher parent dir
-- when UE4SS is sub-moduled/`include("UE4SS")` in another xmake project.
set_config("ue4ssRoot", os.scriptdir())

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

-- Any lua modules in this directory can be imported in the script scope by using
-- /modules/my_module.lua           import("my_module")
-- /modules/rules/my_module.lua     import("rules.my_module")
add_moduledirs("tools/xmakescripts/modules")

-- Load the build_configs file into the global scope.
includes("tools/xmakescripts/build_configs.lua")

-- Generate the modes and add them to all targets.
local modes = generate_compilation_modes()

for _, mode in ipairs(modes) do
    -- add_rules() expects the format `mode.Game__Shipping__Win64`
    add_rules("mode."..mode)
end

if is_plat("windows") then
    -- Globally set the runtimes for all targets.
    set_runtimes(is_mode_debug() and "MDd" or "MD")
end

-- Restrict the compilation modes/configs.
-- These restrictions are inherited upstream and downstream.
-- Any project that `includes("UE4SS")` will inherit these global restrictions.
set_allowedplats("windows")
set_allowedarchs("x64")
set_allowedmodes(modes)

if is_plat("windows") then
    set_defaultmode("Game__Shipping__Win64")
end

includes("deps")
includes("UE4SS")

if is_plat("windows") then
    includes("UVTD")
end
