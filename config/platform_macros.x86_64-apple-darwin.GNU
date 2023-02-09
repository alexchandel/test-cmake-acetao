debug		= 0
inline		= 1
optimize	= 1
static_libs	= 1
shared_libs	= 1
ssl			= 0
buildbits	= 64

OCFLAGS		+= -Oz -Wno-deprecated-declarations
OCCFLAGS	+= -Oz -Wno-deprecated-declarations
CFLAGS		+= -Wno-deprecated-declarations
CCFLAGS		+= -Wno-deprecated-declarations
LDFLAGS		+=

# include $(ACE_ROOT)/include/makeinclude/platform_macosx_mojave.GNU
include $(ACE_ROOT)/include/makeinclude/platform_macosx_monterey.GNU
