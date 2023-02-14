include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(AceTaoMPC
    REQUIRED_VARS MPC_ROOT
)
include(FetchContent)
FetchContent_Declare(AceTaoMPC
    GIT_REPOSITORY      https://github.com/alexchandel/MPC.git
    GIT_TAG             cmake-idl
    SOURCE_DIR          "${MPC_ROOT}"
    CONFIGURE_COMMAND   ""
    BUILD_COMMAND       ""
    INSTALL_COMMAND     ""
)
FetchContent_MakeAvailable(AceTaoMPC)
