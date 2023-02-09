if(NOT DEFINED ACE_ROOT)
  message(SEND_ERROR "Failed to locate ACE_ROOT")
endif()
set(ACE_INCLUDE_DIRS "${ACE_ROOT}")
set(ACE_LIB_DIR "${ACE_ROOT}/lib")
set(ACE_BIN_DIR "${ACE_ROOT}/bin")


if(NOT DEFINED TAO_ROOT)
  if(EXISTS "${ACE_ROOT}/TAO")
    set(TAO_ROOT "${ACE_ROOT}/TAO")
  else()
    message(FATAL_ERROR "Failed to locate TAO_ROOT")
  endif()
endif()
set(TAO_INCLUDE_DIR "${TAO_ROOT}")
set(TAO_INCLUDE_DIRS
  "${TAO_INCLUDE_DIR}"
  "${TAO_INCLUDE_DIR}/orbsvcs"
)
set(TAO_LIB_DIR "${ACE_LIB_DIR}")
set(TAO_BIN_DIR "${ACE_BIN_DIR}")
