if (WIN32)
    set(DEFAULT_COMPILER_FLAGS "-g;-gcodeview;-fcolor-diagnostics;-Wno-unknown-pragmas;-Wno-unused-parameter;-fms-extensions;-Wignored-attributes" PARENT_SCOPE)
else()
    set(DEFAULT_COMPILER_FLAGS "-g;-fcolor-diagnostics;-Wno-unknown-pragmas;-Wno-unused-parameter;-fms-extensions;-Wignored-attributes;-fno-delete-null-pointer-checks" PARENT_SCOPE)
    set(CMAKE_INTERPROCEDURAL_OPTIMIZATION OFF)
endif()

set(LINKER_FLAGS "-g" PARENT_SCOPE)
set(DEFAULT_SHARED_LINKER_FLAGS "${LINKER_FLAGS}" PARENT_SCOPE)
set(DEFAULT_EXE_LINKER_FLAGS "${LINKER_FLAGS}" PARENT_SCOPE)

set(Shipping_FLAGS "" PARENT_SCOPE)