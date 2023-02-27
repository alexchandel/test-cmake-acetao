#ifndef ACE_CONFIG_CUSTOM_H
#define ACE_CONFIG_CUSTOM_H

#if defined(WIN32) || defined(_WIN32) || defined(__WIN32__) || defined(__NT__)
  #include "ace/config-windows.h"
#elif __APPLE__
  #ifndef __GNUC__
    #define __GNUC__ 4
  #endif
  #ifndef __GNUC_MINOR__
    #define __GNUC_MINOR__ 2
  #endif
  #define ACE_HAS_STANDARD_CPP_LIBRARY 1
  #include "ace/config-macosx-mojave.h"
#elif __linux__
  #include "ace/config-linux.h"
#else
  #error "No target configured in config.h"
#endif

#endif // ACE_CONFIG_CUSTOM_H
