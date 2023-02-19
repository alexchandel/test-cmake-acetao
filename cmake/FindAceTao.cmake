include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(AceTao
    REQUIRED_VARS ACE_ROOT TARGET
)
include(FetchContent)

cmake_path(GET ACE_ROOT PARENT_PATH DOWNLOAD_DIR)
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
    include(InitAceTao)

    # load platform-specific configurations
    # these could technically be generated at build time
    file(COPY_FILE
        ${CMAKE_CURRENT_LIST_DIR}/AceTao/config.${TARGET}.h
        ${ACE_ROOT}/ace/config.h
        ONLY_IF_DIFFERENT
    )
    file(COPY_FILE
        ${CMAKE_CURRENT_LIST_DIR}/AceTao/platform_macros.${TARGET}.GNU
        ${ACE_ROOT}/include/makeinclude/platform_macros.GNU
        ONLY_IF_DIFFERENT
    )

    # Get latest MPC (capable of emitting CMake)
    if(NOT DEFINED MPC_ROOT)
        set(MPC_ROOT ${ACE_ROOT}/MPC)
    endif()
    find_package(AceTaoMPC)

    # Generate CMakeLists
    if((NOT EXISTS ${TAO_ROOT}/CMakeLists.txt) OR (${TAO_ROOT}/TAO_ACE.mwc IS_NEWER_THAN ${TAO_ROOT}/CMakeLists.txt))
        execute_process(
            COMMAND
                ${CMAKE_COMMAND} -E env "ACE_ROOT=${ACE_ROOT}" "TAO_ROOT=${TAO_ROOT}" "MPC_ROOT=${MPC_ROOT}"
                    perl "${ACE_ROOT}/bin/mwc.pl" -type cmake TAO_ACE.mwc
            WORKING_DIRECTORY "${TAO_ROOT}"
            COMMAND_ERROR_IS_FATAL ANY
        )
    endif()

    # HACK: fix TAO/TAO_IDL/CMakeLists.TAO_IDL_BE_VIS_[A-Z]
    set(IN_FILE ${TAO_ROOT}/TAO_IDL/CMakeLists.txt)
    if(EXISTS "${IN_FILE}")
        file(STRINGS ${IN_FILE} LINES)
        file(WRITE ${IN_FILE} "")
        foreach(LINE IN LISTS LINES)
            string(REGEX REPLACE "^include\\(CMakeLists.TAO_IDL_BE_VIS_[A-Z]\\)" "" STRIPPED "${LINE}")
            file(APPEND ${IN_FILE} "${STRIPPED}\n")
        endforeach()
    endif()

    if(NOT MSVC)
        add_compile_options(-Wno-deprecated-declarations)
    endif()
    # add_subdirectory(${ACE_ROOT} EXCLUDE_FROM_ALL)
    add_subdirectory(${ACE_ROOT}/TAO EXCLUDE_FROM_ALL)
    target_compile_features(ACE PUBLIC cxx_std_11)
    target_compile_features(TAO PUBLIC cxx_std_11)
    target_include_directories(ACE PUBLIC ${ACE_ROOT})
    target_include_directories(TAO PUBLIC ${ACE_ROOT}/TAO)
    target_include_directories(TAO PUBLIC ${ACE_ROOT}/TAO/orbsvcs)

endif()
