# Defaults
debug       ?= 0
optimize    ?= 1
#inline determined below, defaults to !debug
CPU         ?= X64
winnt       ?= 1
winregistry ?= 1
wfmo        ?= 1
qos         ?= 1

include $(ACE_ROOT)/include/makeinclude/platform_win32_msvc.GNU
