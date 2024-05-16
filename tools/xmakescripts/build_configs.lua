-- TODO: This file should be deleted before the next release?
-- It helps people with old mod templates upgrade to the new template.
local build_configs = build_configs or {}

-- The target/config/platform tables map unreal modes (Game__Shipping__Win64, etc.) to build settings.
-- The keys within each type should be a setting that xmake understands.
-- Example: ["defines"] = { "UE_GAME" } is equivalent to add_defines("UE_GAME") or target:add("defines", "UE_GAME")
-- All possible modes are generated from these target/config/platform tables.

local TARGET_TYPES = {
    ["Game"] = {
        ["defines"] = {
            table.unpack(gameDefines)
        }
    },
    ["CasePreserving"] = {
        ["defines"] = {
            "WITH_CASE_PRESERVING_NAME",
            table.unpack(gameDefines)
        }
    }
}

local CONFIG_TYPES = {
    ["Dev"] = {
        ["symbols"] = {"debug"},
        ["defines"] = {
            "UE_BUILD_DEVELOPMENT",
            "STATS"
        },
        ["optimize"] = {"none"},
    },
    ["Debug"] = {
        ["symbols"] = {"debug"},
        ["defines"] = {
            "UE_BUILD_DEBUG"
        },
        ["optimize"] = {"none"},
    },
    ["Shipping"] = {
        ["symbols"] = {"debug"},
        ["defines"] = {
            "UE_BUILD_SHIPPING"
        },
        ["optimize"] = {"fastest"}
    },
    ["Test"] = {
        ["symbols"] = {"debug"},
        ["defines"] = {
            "UE_BUILD_TEST",
            "STATS"
        },
        ["optimize"] = {"none"}
    }
}

local PLATFORM_TYPES = {
    ["Win64"] = {
        ["defines"] = {
            "PLATFORM_WINDOWS",
            "PLATFORM_MICROSOFT",
            "OVERRIDE_PLATFORM_HEADER_NAME=Windows",
            "UBT_COMPILED_PLATFORM=Win64",
            "UNICODE",
            "_UNICODE",
            "DLLEXT=.dll"
        },
        ["cxflags"] = {
            "clang_cl::-gcodeview"
        }
    },
    ["Linux"] = {
        ["defines"] = {
            "PLATFORM_LINUX",
            "PLATFORM_UNIX",
            "LINUX",
            "OVERRIDE_PLATFORM_HEADER_NAME=Linux",
            "UBT_COMPILED_PLATFORM=Linux",
            "printf_s=printf",
            "DLLEXT=.so"
        },
        ["cxflags"] = {
            "clang::-fno-delete-null-pointer-checks"
        }
    }
}

-- The compile option tables map define what flags should be passed to each compiler.
-- The keys within each type should be a setting that xmake understands.
-- Example: ["cxflags"] = { "-g" } is equivalent to add_cxflags("-g") or target:add("cxflags", "-g")

local CLANG_COMPILE_OPTIONS = {
    ["cxflags"] = {
        "-g",
        "-fcolor-diagnostics",
        "-Wno-unknown-pragmas",
        "-Wno-unused-parameter",
        "-fms-extensions",
        "-Wignored-attributes",
        "-fPIC"
    },
    ["ldflags"] = {
        "-g"
    },
    ["shflags"] = {
        "-g"
    }
}

local GNU_COMPILE_OPTIONS = {
    ["cxflags"] = {
        "-fms-extensions"
    }
}

local MSVC_COMPILE_OPTIONS = {
    ["cxflags"] = {
        "/MP",
        "/W3",
        "/wd4005",
        "/wd4251",
        "/wd4068",
        "/Zc:inline",
        "/Zc:strictStrings",
        "/Zc:preprocessor"
    },
    ["ldflags"] = {
        "/DEBUG:FULL"
    },
    ["shflags"] = {
        "/DEBUG:FULL"
    }
}

--- Generate xmake modes for each of the target__config__platform permutations.
---@return table modes Table containing all target__config__platform permutations.
function generate_compilation_modes()
    local config_modes = {}
    for target_type, _ in pairs(TARGET_TYPES) do
        for config_type, _ in pairs(CONFIG_TYPES) do
            for platform_type, _ in pairs(PLATFORM_TYPES) do
                local config_name = target_type .. "__" .. config_type .. "__" .. platform_type
                table.append(config_modes, config_name)

                -- Modes are defined as rules with the `mode.` prefix. Ex: mode.Game__Shipping__Win64
                rule("mode."..config_name)
                    -- Only trigger the mode-specific logic if we are configured for this mode with `xmake f -m "Game__Shipping__Win64".
                    if is_mode(config_name) then
                        -- Inherit our base rule that should run regardless of the configured mode.
                        add_deps("ue4ss.mode.base")

                        -- Apply the config options for this specific mode.
                        on_config(function(target)
                            import("mode_builder")
                            mode_builder.apply_mode_options(target, TARGET_TYPES[target_type])
                            mode_builder.apply_mode_options(target, CONFIG_TYPES[config_type])
                            mode_builder.apply_mode_options(target, PLATFORM_TYPES[platform_type])
                        end)
                    end
                rule_end()
            end
        end
function config(self, target)
    if target:name() == "Unreal" then
        _warn_unreal_submod_outdated()
    else
        _warn_mod_template_outdated(target)
    end
end

function set_output_dir(self, target)
    if target:name() == "Unreal" then
        _warn_unreal_submod_outdated()
    else
        _warn_mod_template_outdated(target)
    end
end

function clean_output_dir(self, target)
    if target:name() == "Unreal" then
        _warn_unreal_submod_outdated()
    else
        _warn_mod_template_outdated(target)
    end
end

-- Get runtime for current mode
function get_mode_runtimes()
    local is_debug = is_mode_debug()
    if is_plat("windows") then
        return is_debug and "MDd" or "MD"
    end
    -- we don't care about runtime on linux
    return ""
end
-- This rule is used to modify settings for ALL modes regardless of which mode is configured.
-- All modes (Game__Shipping__Win64, etc) inherit this mode.
rule("ue4ss.mode.base")
    on_config(function(target)
        import("mode_builder")
        -- Compiler flags are set in this rule since unreal modes currently do not change any compiler flags.
        mode_builder.apply_compiler_options(target, GNU_COMPILE_OPTIONS, {"gcc", "ld"})
        mode_builder.apply_compiler_options(target, CLANG_COMPILE_OPTIONS, {"clang", "lld"})
        mode_builder.apply_compiler_options(target, MSVC_COMPILE_OPTIONS, { "clang_cl", "cl", "link" })
    end)
function _warn_mod_template_outdated(target)
    print("SUGGESTED TEMPLATE:")
    print(format('target("%s")', target:name()))
    print('    add_rules("ue4ss.mod")')
    print('    add_includedirs(".")')
    print('    add_files("*.cpp")')
    raise("Your mod's xmake.lua file needs updating.")
end

function _warn_unreal_submod_outdated()
    raise("Unreal submodule needs updating.")
end

return build_configs