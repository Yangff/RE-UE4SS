local projectName = "SinglePassSigScanner"

target(projectName)
    set_kind("static")
    set_languages("cxx20")
    set_exceptions("cxx")
    add_rules("ue4ss.dependency")

    add_includedirs("include", { public = true })
    add_headerfiles("include/**.hpp")

    -- *? is not supported?
    add_files("src/**.cpp|SinglePassSigScannerWin32.cpp|SinglePassSigScannerLinux.cpp")
    
    if is_plat("windows") then
        add_headerfiles("include/SigScanner/SinglePassSigScannerWin32.hpp")
        add_files("src/SinglePassSigScannerWin32.cpp")
    elseif is_plat("linux") then
        add_headerfiles("include/SigScanner/SinglePassSigScannerLinux.hpp")
        add_files("src/SinglePassSigScannerLinux.cpp")
    end

    add_deps("Profiler")
