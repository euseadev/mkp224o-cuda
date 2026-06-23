
#ifndef INTFILTER
# define BINFILTER
#endif

#ifdef PCRE2FILTER
# undef BINFILTER
# undef INTFILTER
#endif

#ifdef INTFILTER
# ifdef BINSEARCH
#  ifndef BESORT
#   define OMITMASK
#  endif
# endif
#endif

#ifdef OMITMASK
# define EXPANDMASK
#endif

#ifdef BINFILTER
# define NEEDBINFILTER
#endif
#ifdef INTFILTER
# define NEEDBINFILTER
#endif

#ifdef NEEDBINFILTER

# ifndef BINFILTERLEN
#  define BINFILTERLEN PUBLIC_LEN
# endif

struct binfilter {
	u8 f[BINFILTERLEN];
	size_t len; 
	u8 mask;
} ;

VEC_STRUCT(bfiltervec,struct binfilter);

#ifdef BINFILTER
extern struct bfiltervec filters;
#endif

#endif 


#ifdef INTFILTER

struct intfilter {
	IFT f;
# ifndef OMITMASK
	IFT m;
# endif
} ;

VEC_STRUCT(ifiltervec,struct intfilter);

extern struct ifiltervec filters;

# ifdef OMITMASK
extern IFT ifiltermask;
# endif

#endif 


#ifdef PCRE2FILTER

#define PCRE2_CODE_UNIT_WIDTH 8
#include <pcre2.h>

struct pcre2filter {
	char *str;
	pcre2_code *re;
} ;

VEC_STRUCT(pfiltervec,struct pcre2filter);

extern struct pfiltervec filters;

#endif 

extern int flattened;

extern void filters_init(void);
extern void filters_add(const char *filter);
extern size_t filters_count(void);
