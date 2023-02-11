cmake_minimum_required(VERSION 3.25)

project(
    TrivialTest
    VERSION 1.0
    LANGUAGES CXX
)



list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/cmake)
set(ACE_ROOT "${CMAKE_CURRENT_LIST_DIR}/ACE_wrappers")
include(init)
include(idl_files)


block()
    set(CMAKE_CXX_STANDARD 11)
    add_compile_options(-Wno-deprecated-declarations)
    # add_subdirectory(ACE_wrappers EXCLUDE_FROM_ALL)
    add_subdirectory(ACE_wrappers/TAO EXCLUDE_FROM_ALL)
    target_compile_features(ACE PUBLIC cxx_std_11)
    target_compile_features(TAO PUBLIC cxx_std_11)
    target_include_directories(ACE PUBLIC ${ACE_ROOT})
    target_include_directories(TAO PUBLIC ${ACE_ROOT}/TAO)
endblock()

add_executable(TrivialTest main.cpp)
target_link_libraries(TrivialTest
    ACE
    ACE_ETCL
    ACE_ETCL_Parser
    TAO
    TAO_AnyTypeCode
    TAO_CodecFactory
    TAO_CosConcurrency
    TAO_CosEvent
    TAO_CosEvent_Serv
    TAO_CosEvent_Skel
    TAO_CosNaming
    TAO_CosNaming_Serv
    TAO_CosNaming_Skel
    TAO_CosNotification
    TAO_CosNotification_Serv
    TAO_CosNotification_Skel
    TAO_DynamicAny
    TAO_DynamicInterface
    TAO_ETCL
    TAO_IFR_Client
    TAO_IORTable
    TAO_Messaging
    TAO_PI
    TAO_PortableServer
    TAO_Svc_Utils
    TAO_Valuetype
)
