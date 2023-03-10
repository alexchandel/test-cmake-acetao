include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(AceTao
    REQUIRED_VARS ACE_ROOT
)
include(FetchContent)

cmake_path(GET ACE_ROOT PARENT_PATH DOWNLOAD_DIR)
set(AceTao_VERSION 7.0.11)
FetchContent_Declare(AceTao
    URL             https://github.com/DOCGroup/ACE_TAO/releases/download/ACE%2BTAO-7_0_11/ACE+TAO-7.0.11.zip
    URL_HASH        MD5=5451e46525b3075dbcc983e002b7d2b7
    DOWNLOAD_DIR    ${DOWNLOAD_DIR}
    SOURCE_DIR      ${ACE_ROOT}
)

FetchContent_GetProperties(AceTao)
if(NOT AceTao_POPULATED)
    FetchContent_Populate(AceTao)

    # Define ACE_ & TAO_ variables
    if(NOT DEFINED TAO_ROOT)
        if(EXISTS "${ACE_ROOT}/TAO")
            set(TAO_ROOT "${ACE_ROOT}/TAO")
        else()
            message(FATAL_ERROR "Failed to locate TAO_ROOT")
        endif()
    endif()

    # load platform-specific configurations
    # these could technically be generated at build time
    file(COPY_FILE
        ${CMAKE_CURRENT_LIST_DIR}/AceTao/config.h
        ${ACE_ROOT}/ace/config.h
        ONLY_IF_DIFFERENT
    )

    # Get latest MPC (capable of emitting CMake)
    if(NOT DEFINED MPC_ROOT)
        if(EXISTS "${ACE_ROOT}/MPC")
            set(MPC_ROOT ${ACE_ROOT}/MPC)
        else()
            message(FATAL_ERROR "Failed to locate MPC_ROOT")
        endif()
    endif()
    find_package(AceTaoMPC)

    # Generate CMakeLists
    find_package(Perl REQUIRED)
    if((NOT EXISTS ${TAO_ROOT}/CMakeLists.txt) OR (${TAO_ROOT}/TAO_ACE.mwc IS_NEWER_THAN ${TAO_ROOT}/CMakeLists.txt))
        execute_process(
            COMMAND
                ${CMAKE_COMMAND} -E env "ACE_ROOT=${ACE_ROOT}" "TAO_ROOT=${TAO_ROOT}" "MPC_ROOT=${MPC_ROOT}"
                    "${PERL_EXECUTABLE}" "${ACE_ROOT}/bin/mwc.pl" -type cmake TAO_ACE.mwc
            WORKING_DIRECTORY "${TAO_ROOT}"
            COMMAND_ERROR_IS_FATAL ANY
        )
    endif()

    # HACK: delete TAO/TAO_IDL/CMakeLists.TAO_IDL_BE_VIS_[A-Z] due to unhandled prop:static
    set(IN_FILE ${TAO_ROOT}/TAO_IDL/CMakeLists.txt)
    if(EXISTS "${IN_FILE}")
        file(STRINGS ${IN_FILE} LINES)
        file(WRITE ${IN_FILE} "")
        foreach(LINE IN LISTS LINES)
            string(REGEX REPLACE "^include\\(CMakeLists.TAO_IDL_BE_VIS_[A-Z]\\)" "" STRIPPED "${LINE}")
            file(APPEND ${IN_FILE} "${STRIPPED}\n")
        endforeach()
    endif()

    # Silence useless warnings on old releases
    if(NOT MSVC)
        add_compile_options(-Wno-deprecated-declarations)
    endif()

    # Finally, import the generated CMakeLists and create targets
    add_subdirectory(${ACE_ROOT}/TAO EXCLUDE_FROM_ALL)

    # Add public include folders to ACE+TAO targets (theirs are all private)
    target_include_directories(ACE PUBLIC ${ACE_ROOT})
    target_include_directories(TAO PUBLIC ${ACE_ROOT}/TAO)
    target_include_directories(TAO PUBLIC ${ACE_ROOT}/TAO/orbsvcs)

     # Fixup missing system dependencies in ACE+TAO
    if(CMAKE_DL_LIBS)
        target_link_libraries(ACE PUBLIC ${CMAKE_DL_LIBS})
    endif()
    find_package(Threads)
    if(Threads_FOUND)
        target_link_libraries(ACE PUBLIC Threads::Threads)
    endif()
    if(UNIX AND NOT APPLE)
        find_library(RT_LIBS rt)
        if(RT_LIBS)
            target_link_libraries(ACE PUBLIC ${RT_LIBS})
        endif()
    endif()

    # Backport CMake compatibility to older ACE+TAO versions
    if(${AceTao_VERSION} VERSION_LESS_EQUAL 7.0.11)
        target_compile_features(ACE PUBLIC cxx_std_11)
        target_compile_features(TAO PUBLIC cxx_std_11)

        if(WIN32)
            target_link_libraries(ACE PUBLIC iphlpapi)
            if(MSVC)
                target_compile_options(ACE PRIVATE /wd4355)
                target_compile_definitions(ACE PRIVATE
                    _CRT_SECURE_NO_WARNINGS _CRT_SECURE_NO_DEPRECATE _CRT_NONSTDC_NO_DEPRECATE
                    _SCL_SECURE_NO_WARNINGS _WINSOCK_DEPRECATED_NO_WARNINGS
                )
            endif()
        endif()
    else()
        # Fixup current ACE+TAO versions
        target_compile_features(ACE PUBLIC cxx_std_14) # >= 7.0.12
        target_compile_features(TAO PUBLIC cxx_std_14)
    endif()
endif()
