local projectName = "Input"

target(projectName)
    set_kind("static")
    set_languages("cxx20")
    set_exceptions("cxx")
    add_rules("ue4ss.dependency")

    add_includedirs("include", { public = true })
    add_headerfiles("include/**.hpp")

    add_files("src/**.cpp|Platform/**.cpp")

    add_deps("DynamicOutput")

    if is_plat("windows") then
        add_files("src/Platform/Win32AsyncInputSource.cpp")
        add_files("src/Platform/GLFW3InputSource.cpp")
        add_files("src/Platform/QueueInputSource.cpp")
    end
