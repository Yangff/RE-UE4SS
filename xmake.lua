-- We should use `get_config("ue4ssRoot")` instead of `os.projectdir()` or `$(projectdir)`.
-- This is because os.projectdir() will return a higher parent dir
-- when UE4SS is sub-moduled/`include("UE4SS")` in another xmake project.
set_config("ue4ssRoot", os.scriptdir())

-- All non-binary outputs are written to the Intermediates dir.
set_config("buildir", "Intermediates")

-- Any lua modules in this directory can be imported in the script scope by using
-- /modules/my_module.lua           import("my_module")
-- /modules/rules/my_module.lua     import("rules.my_module")
add_moduledirs("tools/xmakescripts/modules")

-- Load the build_rules file into the global scope.
includes("tools/xmakescripts/rules/build_rules.lua")

-- Generate the mode rules.
local modes = generate_compilation_modes()

-- Enter the existing ue4ss.base rule scope in order to add all xxx__xxx__xxx modes
-- to the ue4ss.base rule.
rule("ue4ss.base")
    for _, mode in ipairs(modes) do
        -- add_rules() expects the format `mode.Game__Shipping__Win64`
        add_deps("mode."..mode)
    end
rule_end()

-- Add the ue4ss.core rule to all targets within the UE4SS repository.
add_rules("ue4ss.core")

-- Restrict the compilation modes/configs.
-- These restrictions are inherited upstream and downstream.
-- Any project that `includes("UE4SS")` will inherit these global restrictions.
set_allowedplats("windows", "linux")
set_allowedarchs("x64", "x86_64", "x86_64-unknown-linux-gnu")
set_allowedmodes(modes)

option("zig")
    set_showmenu(true)
    set_description("Use the Zig compiler.")
    set_default(false)
option_end()

toolchain("zigcross")
    if is_host("windows") then
        set_toolset("cc", "$(projectdir)/tools/zig/zig-cc.bat")
        set_toolset("cxx", "$(projectdir)/tools/zig/zig-c++.bat")
        set_toolset("ld", "$(projectdir)/tools/zig/zig-c++.bat")
        set_toolset("sh", "$(projectdir)/tools/zig/zig-c++.bat")
        set_toolset("ar", "$(projectdir)/tools/zig/zig-ar.bat")
    else
        set_toolset("cc", "$(projectdir)/tools/zig/zig-cc.bat")
        set_toolset("cxx", "$(projectdir)/tools/zig/zig-c++.bat")
        set_toolset("ld", "$(projectdir)/tools/zig/zig-c++.bat")
        set_toolset("sh", "$(projectdir)/tools/zig/zig-c++.bat")
        set_toolset("ar", "$(projectdir)/tools/zig/zig-ar.bat")
    end
    add_cxflags("-fexperimental-library")
    add_cxflags("-fno-delete-null-pointer-checks")
    add_cxflags("-gdwarf")
    add_cxflags("-fno-sanitize=undefined") -- can also use O2 to avoid this, but I'd prefer getting clear binary for now
    add_shflags("-z", "lazy")
toolchain_end()

if is_plat("linux") then
    if has_config("zig") then
        set_toolchains("zigcross", "rust")
        if is_host("windows") then
            set_arch("x86_64-unknown-linux-gnu")
            add_rcflags("-C", "linker=$(projectdir)/tools/zig/zig-cc.bat", {force = true})
        end
    else
        set_toolchains("clang", "rust")
    end
    set_defaultmode("Game__Shipping__Linux")
end

if is_plat("windows") then
    set_defaultmode("Game__Shipping__Win64")
end

-- Override the `xmake install` behavior for all targets.
-- Targets can re-override the on_install() function to implement custom installation behavior.
on_install(function(target) end)

includes("deps")
includes("UE4SS")
-- includes("UVTD")

-- TODO: Remove this before the next release. It only exists to maintain backwards compat
-- warnings for older mod templates.
set_config("scriptsRoot", path.join(os.scriptdir(), "tools/xmakescripts"))
