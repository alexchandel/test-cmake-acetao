# Distributed under the OpenDDS License. See accompanying LICENSE
# file or http://www.opendds.org/license.html for details.

macro(_tao_append_runtime_lib_dir_to_path dst)
  if (MSVC)
    set(${dst} "PATH=")
    if (DEFINED ENV{PATH})
      set(${dst} "${${dst}}$ENV{PATH};")
    endif()
    set(${dst} "${${dst}}${TAO_BIN_DIR}")
  else()
    set(${dst} "LD_LIBRARY_PATH=")
    if (DEFINED ENV{LD_LIBRARY_PATH})
      string(REPLACE "\\" "/" tmp "$ENV{LD_LIBRARY_PATH}")
      set(${dst} "${${dst}}${tmp}:")
    endif()
    string(REPLACE "\\" "/" tmp ${TAO_LIB_DIR})
    set(${dst} "\"${${dst}}${tmp}\"")
  endif()
endmacro()

set(TAO_VERSIONING_IDL_FLAGS
  -Wb,versioning_begin=TAO_BEGIN_VERSIONED_NAMESPACE_DECL
  -Wb,versioning_end=TAO_END_VERSIONED_NAMESPACE_DECL
)

if (CORBA_E_MICRO)
  list(APPEND TAO_CORBA_IDL_FLAGS -DCORBA_E_MICRO -Gce)
endif()

if (CORBA_E_COMPACT)
  list(APPEND TAO_CORBA_IDL_FLAGS -DCORBA_E_COMPACT -Gce)
endif()

if (MINIMUM_CORBA)
  list(APPEND TAO_CORBA_IDL_FLAGS -DTAO_HAS_MINIMUM_POA -Gmc)
endif()

if (TAO_NO_IIOP)
  list(APPEND TAO_CORBA_IDL_FLAGS -DTAO_LACKS_IIOP)
endif()

if (GEN_OSTREAM)
  list(APPEND TAO_CORBA_IDL_FLAGS -Gos)
endif()

if (NOT TAO_HAS_OPTIMIZE_COLLOCATED_INVOCATIONS)
  list(APPEND TAO_CORBA_IDL_FLAGS -Sp -Sd)
endif()

# tao_idl_command(<target> [IDL_FLAGS <flag> ...] IDL_FILES <idl_file> ...)
# The default output directory is the IDL file's.
function(tao_idl_command target)
  set(multiValueArgs IDL_FLAGS IDL_FILES)
  cmake_parse_arguments(_arg "" "" "${multiValueArgs}" ${ARGN})

  set(_arg_IDL_FLAGS ${_arg_IDL_FLAGS})

  if (NOT _arg_IDL_FILES)
    message(FATAL_ERROR "called tao_idl_command(${target}) without specifying IDL_FILES")
  endif()

  set(_working_binary_dir ${CMAKE_CURRENT_BINARY_DIR})
  set(_working_source_dir ${CMAKE_CURRENT_SOURCE_DIR})

  set(optionArgs -Sch -Sci -Scc -Ssh -SS -GA -GT -GX -Gxhst -Gxhsk)
  cmake_parse_arguments(_idl_cmd_arg "${optionArgs}" "-o;-oS;-oA" "" ${_arg_IDL_FLAGS})

  foreach(idl_file ${_arg_IDL_FILES})
    get_filename_component(idl_file_path "${idl_file}" ABSOLUTE)
    get_filename_component(idl_file_dir "${idl_file_path}" DIRECTORY)
    get_filename_component(idl_filename_no_ext "${idl_file}" NAME_WE)

    # Get absolute paths to output files, for CMake
    if(_idl_cmd_arg_-o)
      cmake_path(ABSOLUTE_PATH _idl_cmd_arg_-o
                 BASE_DIRECTORY "${idl_file_dir}"
                 OUTPUT_VARIABLE stub_output_dir)
    else()
      set(stub_output_dir "${idl_file_dir}")
    endif()
    set(stub_output_prefix "${stub_output_dir}/${idl_filename_no_ext}")

    if(_idl_cmd_arg_-oS)
      cmake_path(ABSOLUTE_PATH _idl_cmd_arg_-oS
                 BASE_DIRECTORY "${idl_file_dir}"
                 OUTPUT_VARIABLE skel_output_dir)
    else()
      set(skel_output_dir "${idl_file_dir}")
    endif()
    set(skel_output_prefix "${skel_output_dir}/${idl_filename_no_ext}")

    if(_idl_cmd_arg_-oA)
      cmake_path(ABSOLUTE_PATH _idl_cmd_arg_-oA
                 BASE_DIRECTORY "${idl_file_dir}"
                 OUTPUT_VARIABLE anyop_output_dir)
    else()
      set(anyop_output_dir "${idl_file_dir}")
    endif()
    set(anyop_output_prefix "${anyop_output_dir}/${idl_filename_no_ext}")

    set(_STUB_HEADER_FILES)
    set(_SKEL_HEADER_FILES)

    if (NOT _idl_cmd_arg_-Sch)
      set(_STUB_HEADER_FILES "${stub_output_prefix}C.h")
    endif()

    if (NOT _idl_cmd_arg_-Sci)
      list(APPEND _STUB_HEADER_FILES "${stub_output_prefix}C.inl")
    endif()

    if (NOT _idl_cmd_arg_-Scc)
      set(_STUB_CPP_FILES "${stub_output_prefix}C.cpp")
    endif()

    if (NOT _idl_cmd_arg_-Ssh)
      set(_SKEL_HEADER_FILES "${skel_output_prefix}S.h")
    endif()

    if (NOT _idl_cmd_arg_-SS)
      set(_SKEL_CPP_FILES "${skel_output_prefix}S.cpp")
    endif()

    if (_idl_cmd_arg_-GA)
      set(_ANYOP_HEADER_FILES "${anyop_output_prefix}A.h")
      set(_ANYOP_CPP_FILES "${anyop_output_prefix}A.cpp")
    elseif (_idl_cmd_arg_-GX)
      set(_ANYOP_HEADER_FILES "${anyop_output_prefix}A.h")
    endif()

    if (_idl_cmd_arg_-GT)
      list(APPEND _SKEL_HEADER_FILES
        "${skel_output_prefix}S_T.h"
        "${skel_output_prefix}S_T.cpp")
    endif()

    if (_idl_cmd_arg_-Gxhst)
      list(APPEND _STUB_HEADER_FILES ${CMAKE_CURRENT_BINARY_DIR}/${idl_cmd_arg-wb-stub_export_file})
    endif()

    if (_idl_cmd_arg_-Gxhsk)
      list(APPEND _SKEL_HEADER_FILES ${CMAKE_CURRENT_BINARY_DIR}/${idl_cmd_arg-wb-skel_export_file})
    endif()

    set(GPERF_LOCATION $<TARGET_FILE:ace_gperf>)
    if(CMAKE_CONFIGURATION_TYPES)
      get_target_property(is_gperf_imported ace_gperf IMPORTED)
      if (is_gperf_imported)
        set(GPERF_LOCATION $<TARGET_PROPERTY:ace_gperf,LOCATION>)
      endif(is_gperf_imported)
    endif(CMAKE_CONFIGURATION_TYPES)

    if (BUILD_SHARED_LIB AND TARGET TAO_IDL_BE)
      set(tao_idl_shared_libs TAO_IDL_BE TAO_IDL_FE)
    endif()

    set(_OUTPUT_FILES
      ${_STUB_HEADER_FILES}
      ${_SKEL_HEADER_FILES}
      ${_ANYOP_HEADER_FILES}
      ${_STUB_CPP_FILES}
      ${_SKEL_CPP_FILES}
      ${_ANYOP_CPP_FILES})

    _tao_append_runtime_lib_dir_to_path(_tao_extra_lib_dirs)

    add_custom_command(
      OUTPUT ${_OUTPUT_FILES}
      DEPENDS tao_idl ${tao_idl_shared_libs} ace_gperf
      MAIN_DEPENDENCY ${idl_file_path}
      COMMAND ${CMAKE_COMMAND} -E env "TAO_ROOT=${TAO_INCLUDE_DIR}"
        "${_tao_extra_lib_dirs}"
        $<TARGET_FILE:tao_idl> -g ${GPERF_LOCATION} ${TAO_CORBA_IDL_FLAGS} -Sg
        -Wb,pre_include=ace/pre.h -Wb,post_include=ace/post.h
        --idl-version 4 -as --unknown-annotations ignore
        -I${TAO_INCLUDE_DIR} -I${_working_source_dir}
        ${_arg_IDL_FLAGS}
        ${idl_file_path}
      WORKING_DIRECTORY "${idl_file_dir}"
    )

    set_property(SOURCE ${idl_file_path} APPEND PROPERTY
      OPENDDS_CPP_FILES
        ${_STUB_CPP_FILES}
        ${_SKEL_CPP_FILES}
        ${_ANYOP_CPP_FILES})

    set_property(SOURCE ${idl_file_path} APPEND PROPERTY
      OPENDDS_HEADER_FILES
        ${_STUB_HEADER_FILES}
        ${_SKEL_HEADER_FILES}
        ${_ANYOP_HEADER_FILES})
  endforeach()
endfunction()
