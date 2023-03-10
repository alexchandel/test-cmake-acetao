cmake_minimum_required(VERSION 3.25)

project(
    TrivialTest
    VERSION 1.0
    LANGUAGES CXX
)



# set global variables
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/cmake)

set(ACE_ROOT "${CMAKE_CURRENT_LIST_DIR}/opt/ACE_wrappers")
find_package(AceTao)


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

add_dependencies(TrivialTest tao_cosnaming)

install(TARGETS TrivialTest tao_cosnaming RUNTIME)
install(FILES
    $<TARGET_RUNTIME_DLLS:TrivialTest>
    $<TARGET_RUNTIME_DLLS:tao_cosnaming>
    TYPE BIN
)
