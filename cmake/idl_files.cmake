#----------------------------------------------------------------------------
#
# Distributed under the OpenDDS License. See accompanying LICENSE
# file or http://www.opendds.org/license.html for details.
#
# This file provides handling of IDL files.  It was written specifically to
# work with MPC generated CMakeLists.txt files.  However, it is not limited
# to such uses.
#
#----------------------------------------------------------------------------

include(tao_idl_sources)

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
          get_source_file_property(cpps ${file} OPENDDS_CPP_FILES)
          get_source_file_property(cpp_headers ${file} OPENDDS_HEADER_FILES)
          target_sources(${target} ${scope} ${cpps} ${cpp_headers})
        endif()
      endforeach()
    endif()
  endforeach()
endmacro()
