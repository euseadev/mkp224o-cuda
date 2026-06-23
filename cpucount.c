#include "cpucount.h"

#ifndef BSD
#  ifndef __linux__

#    ifdef __FreeBSD__
#      undef BSD
#      define BSD
#    endif

#    ifdef __OpenBSD__
#      undef BSD
#      define BSD
#    endif

#    ifdef __NetBSD__
#      undef BSD
#      define BSD
#    endif

#    ifdef __DragonFly__
#      undef BSD
#      define BSD
#    endif
#  endif 

#  ifdef BSD
#    undef BSD
#    include <sys/param.h>
#    define SYS_PARAM_INCLUDED
#    ifndef BSD
#      define BSD
#    endif
#  endif
#endif 

#ifdef BSD
#  ifndef SYS_PARAM_INCLUDED
#    include <sys/param.h>
#  endif
#  include <sys/sysctl.h>
#endif

#include <string.h>

#ifndef _WIN32
#include <unistd.h>
#else
#define UNICODE 1
#include <windows.h>
#endif

#ifdef __linux__
#include <stdio.h>
#include <stdlib.h>
#include <strings.h>
static int parsecpuinfo(void)
{
	unsigned char cpubitmap[128];

	memset(cpubitmap,0,sizeof(cpubitmap));

	FILE *f = fopen("/proc/cpuinfo","r");
	if (!f)
		return -1;

	char buf[8192];
	while (fgets(buf,sizeof(buf),f)) {
		
		for (char *p = buf;*p;++p) {
			if (*p == '\n') {
				*p = 0;
				break;
			}
		}
		
		char *v = 0;
		for (char *p = buf;*p;++p) {
			if (*p == ':') {
				*p = 0;
				v = p + 1;
				break;
			}
		}
		
		size_t kl = strlen(buf);
		while (kl > 0 && (buf[kl - 1] == '\t' || buf[kl - 1] == ' ')) {
			--kl;
			buf[kl] = 0;
		}
		
		if (v) {
			while (*v && (*v == ' ' || *v == '\t'))
				++v;
		}
		
		if (strcasecmp(buf,"processor") == 0 && v) {
			char *endp = 0;
			long n = strtol(v,&endp,10);
			if (endp && endp > v && n >= 0 && (size_t)n < sizeof(cpubitmap) * 8)
				cpubitmap[n / 8] |= 1 << (n % 8);
		}
	}

	fclose(f);

	
	int ncpu = 0;
	for (size_t n = 0;n < sizeof(cpubitmap) * 8;++n)
		if (cpubitmap[n / 8] & (1 << (n % 8)))
			++ncpu;

	return ncpu;
}
#endif

int cpucount(void)
{
	int ncpu;
#ifdef _SC_NPROCESSORS_ONLN
	ncpu = (int)sysconf(_SC_NPROCESSORS_ONLN);
	if (ncpu > 0)
		return ncpu;
#endif
#ifdef __linux__
	
	
	ncpu = parsecpuinfo();
	if (ncpu > 0)
		return ncpu;
#endif
#ifdef BSD
	const int ctlname[2] = {CTL_HW,HW_NCPU};
	size_t ctllen = sizeof(ncpu);
	if (sysctl(ctlname,2,&ncpu,&ctllen,0,0) < 0)
		ncpu = -1;
	if (ncpu > 0)
		return ncpu;
#endif
#ifdef _WIN32
	SYSTEM_INFO sysinfo;
	GetSystemInfo(&sysinfo);
	ncpu = (int)sysinfo.dwNumberOfProcessors;
	if (ncpu > 0)
		return ncpu;
#endif
	(void) ncpu;
	return -1;
}
