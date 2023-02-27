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


macro(_tao_append_runtime_lib_dir_to_path dst)
  if (MSVC)
    # prepend tao_idl bin + TAO dlls + MSVC bin dir
    cmake_path(GET CMAKE_CXX_COMPILER PARENT_PATH new_tao_dirs) # tao_idl calls cl.exe
    string(PREPEND new_tao_dirs "${TAO_BIN_DIR};${TAO_LIB_DIR};")
    cmake_path(CONVERT "${new_tao_dirs}" TO_NATIVE_PATH_LIST new_tao_dirs)
    set(${dst} "PATH=${new_tao_dirs}")

    # append rest of PATH, so that TAO dlls in PATH don't conflict
    if (DEFINED ENV{PATH})
      string(APPEND ${dst} ";$ENV{PATH}")
    endif()
  else()
    if(APPLE)
        set(LD_LIBRARY_PATH_VAR "DYLD_FALLBACK_LIBRARY_PATH")
    else()
        set(LD_LIBRARY_PATH_VAR "LD_LIBRARY_PATH")
    endif()
    set(${dst} "${LD_LIBRARY_PATH_VAR}=")
    if (DEFINED ENV{${LD_LIBRARY_PATH_VAR}})
      string(REPLACE "\\" "/" new_tao_dirs "$ENV{${LD_LIBRARY_PATH_VAR}}") # why??
      string(APPEND ${dst} "${new_tao_dirs}:")
    endif()
    string(REPLACE "\\" "/" new_tao_dirs ${TAO_LIB_DIR}) # why??
    set(${dst} "\"${${dst}}${new_tao_dirs}\"")
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
      set(tmp_idl_cmd_arg_list ${_arg_IDL_FLAGS})
      list(FILTER tmp_idl_cmd_arg_list INCLUDE REGEX "^-Wb,stub_export_file=.")
      if (tmp_idl_cmd_arg_list)
        list(GET tmp_idl_cmd_arg_list 0 tmp_stub_export_file)
        if (tmp_stub_export_file MATCHES "^-Wb,stub_export_file=([^;]+)")
          list(APPEND _STUB_HEADER_FILES ${stub_output_dir}/${CMAKE_MATCH_1})
        endif()
      endif()
    endif()

    if (_idl_cmd_arg_-Gxhsk)
      set(tmp_idl_cmd_arg_list ${_arg_IDL_FLAGS})
      list(FILTER tmp_idl_cmd_arg_list INCLUDE REGEX "^-Wb,skel_export_file=.")
      if (tmp_idl_cmd_arg_list)
        list(GET tmp_idl_cmd_arg_list 0 tmp_skel_export_file)
        if (tmp_skel_export_file MATCHES "^-Wb,skel_export_file=([^;]+)")
          list(APPEND _SKEL_HEADER_FILES ${skel_output_dir}/${CMAKE_MATCH_1})
        endif()
      endif()
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

# IDL_FILES_TARGET_SOURCES(<target>
#   <INTERFACE|PUBLIC|PRIVATE> <files>...
#   [<INTERFACE|PUBLIC|PRIVATE> <files>... ...]
#   [IDL_FILES_OPTIONS <option> ...])
macro(IDL_FILES_TARGET_SOURCES target)
  set(_multi_value_options PUBLIC PRIVATE INTERFACE IDL_FILES_OPTIONS)
  cmake_parse_arguments(_arg "" "" "${_multi_value_options}" ${ARGN})

  foreach(scope PUBLIC PRIVATE INTERFACE)
    set(_idl_sources_${scope})

    if(_arg_${scope})
      foreach(src ${_arg_${scope}})
        get_filename_component(src ${src} ABSOLUTE)

        if("${src}" MATCHES "\\.p?idl$")
          list(APPEND _idl_sources_${scope} ${src})
        endif()
      endforeach()
    endif()
  endforeach()

  foreach(scope PUBLIC PRIVATE INTERFACE)
    if (_idl_sources_${scope})
      foreach(file ${_idl_sources_${scope}})
        get_source_file_property(cpps ${file} OPENDDS_CPP_FILES)
        if (NOT cpps)
          tao_idl_command(${target}
                          IDL_FLAGS ${_arg_IDL_FILES_OPTIONS}
                          IDL_FILES ${file})
          # create object library to ensure dependency rules are generated:
          get_source_file_property(cpps ${file} OPENDDS_CPP_FILES)
          get_source_file_property(cpp_headers ${file} OPENDDS_HEADER_FILES)
          cmake_path(GET file STEM LAST_ONLY file_basename)
          add_library("${target}.${file_basename}" OBJECT ${cpps} ${cpp_headers})
          # add to target, if it exists
          if (TARGET ${target})
            target_sources(${target} ${scope} ${cpps} ${cpp_headers})
          endif()
        endif()
      endforeach()
    endif()
  endforeach()
endmacro()
