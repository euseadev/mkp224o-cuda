
#include "filters_common.inc.h"
#include "ifilter_bitsum.h"

#ifdef INTFILTER

# ifdef OMITMASK

static inline int filter_compare(const void *p1,const void *p2)
{
	if (((const struct intfilter *)p1)->f < ((const struct intfilter *)p2)->f)
		return -1;
	if (((const struct intfilter *)p1)->f > ((const struct intfilter *)p2)->f)
		return 1;
	return 0;
}

#  ifdef EXPANDMASK


int flattened = 0;


static void ifilter_addexpanded(
	struct intfilter *ifltr,
	register IFT newbits,
	register IFT notnewbits,
	register IFT newbitsum)
{
	flattened = 1;
	size_t i = VEC_LENGTH(filters);
	VEC_ADDN(filters,newbitsum + 1);
	register IFT x = ifltr->f;
	register IFT y = 0;
	for (size_t j = 0;;++j) {
		VEC_BUF(filters,i + j).f = x | y;
		if (j == newbitsum)
			break;
		y = ((y | notnewbits) + 1) & newbits;
	}
}


static void ifilter_expand(
	register IFT newbits,
	register IFT notnewbits,
	register IFT newbitsum)
{
	flattened = 1;
	size_t len = VEC_LENGTH(filters);
	VEC_ADDN(filters,newbitsum * len);
	size_t esz = newbitsum + 1; 
	for (size_t i = len - 1;;--i) {
		register IFT x = VEC_BUF(filters,i).f;
		register IFT y = 0;
		for (IFT j = 0;;++j) {
			VEC_BUF(filters,i * esz + j).f = x | y;
			if (j == newbitsum)
				break;
			y = ((y | notnewbits) + 1) & newbits;
		}
		if (i == 0)
			break;
	}
}

static inline void ifilter_addflatten(struct intfilter *ifltr,IFT mask)
{
	if (VEC_LENGTH(filters) == 0) {
		
		VEC_ADD(filters,*ifltr);
		ifiltermask = mask;
		return;
	}
	if (ifiltermask == mask) {
		
		VEC_ADD(filters,*ifltr);
		return;
	}

	IFT newbits = ifiltermask ^ mask;
	IFT notnewbits = ~newbits;
	IFT newbitsum = ifilter_bitsum(newbits);

	if (ifiltermask > mask) {
		
		
		ifilter_addexpanded(ifltr,newbits,notnewbits,newbitsum);
	}
	else {
		
		
		ifiltermask = mask;
		ifilter_expand(newbits,notnewbits,newbitsum);
		VEC_ADD(filters,*ifltr);
	}
}

#  endif 

# else 

static inline int filter_compare(const void *p1,const void *p2)
{
	return memcmp(p1,p2,sizeof(struct intfilter));
}

# endif 

static void filter_sort(void)
{
	size_t len = VEC_LENGTH(filters);
	if (len > 0)
		qsort(&VEC_BUF(filters,0),len,sizeof(struct intfilter),&filter_compare);
}

#endif 

#ifdef BINFILTER

static inline int filter_compare(const void *p1,const void *p2)
{
	const struct binfilter *b1 = (const struct binfilter *)p1;
	const struct binfilter *b2 = (const struct binfilter *)p2;

	size_t l = b1->len <= b2->len ? b1->len : b2->len;

	int cmp = memcmp(b1->f,b2->f,l);
	if (cmp != 0)
		return cmp;

	if (b1->len < b2->len)
		return -1;
	if (b1->len > b2->len)
		return +1;

	u8 cmask = b1->mask & b2->mask;
	if ((b1->f[l] & cmask) < (b2->f[l] & cmask))
		return -1;
	if ((b1->f[l] & cmask) > (b2->f[l] & cmask))
		return +1;

	if (b1->mask < b2->mask)
		return -1;
	if (b1->mask > b2->mask)
		return +1;

	return 0;
}

static void filter_sort(void)
{
	size_t len = VEC_LENGTH(filters);
	if (len > 0)
		qsort(&VEC_BUF(filters,0),len,sizeof(struct binfilter),&filter_compare);
}

#endif 


#ifndef PCRE2FILTER
static inline int filters_a_includes_b(size_t a,size_t b)
{
# ifdef INTFILTER
#  ifdef OMITMASK
	return VEC_BUF(filters,a).f == VEC_BUF(filters,b).f;
#  else 
	return VEC_BUF(filters,a).f == (VEC_BUF(filters,b).f & VEC_BUF(filters,a).m);
#  endif 
# else 
	const struct binfilter *fa = &VEC_BUF(filters,a);
	const struct binfilter *fb = &VEC_BUF(filters,b);

	if (fa->len > fb->len)
		return 0;
	size_t l = fa->len;

	int cmp = memcmp(fa->f,fb->f,l);
	if (cmp != 0)
		return 0;

	if (fa->len < fb->len)
		return 1;

	if (fa->mask > fb->mask)
		return 0;

	return fa->f[l] == (fb->f[l] & fa->mask);
# endif 
}

static void filters_dedup(void)
{
	size_t last = ~(size_t)0; 
	size_t chk;               
	size_t st;                

	size_t len = VEC_LENGTH(filters);
	for (size_t i = 1;i < len;++i) {
		if (last != i) {
			if (filters_a_includes_b(i - 1,i)) {
				if (last != ~(size_t)0) {
					memmove(&VEC_BUF(filters,st),
						&VEC_BUF(filters,last),
						(i - last) * VEC_ELSIZE(filters));
					st += i - last;
				}
				else
					st = i;
				chk = i - 1;
				last = i + 1;
			}
		}
		else {
			if (filters_a_includes_b(chk,i))
				last = i + 1;
		}
	}
	if (last != ~(size_t)0) {
		memmove(&VEC_BUF(filters,st),
			&VEC_BUF(filters,last),
			(len - last) * VEC_ELSIZE(filters));
		st += len - last;
		VEC_SETLENGTH(filters,st);
	}
}
#endif 

static void filters_clean(void)
{
#ifdef PCRE2FILTER
	for (size_t i = 0;i < VEC_LENGTH(filters);++i) {
		pcre2_code_free(VEC_BUF(filters,i).re);
		free(VEC_BUF(filters,i).str);
	}
#endif
	VEC_FREE(filters);
}

size_t filters_count(void)
{
	return VEC_LENGTH(filters);
}

static void filters_print(void)
{
	if (quietflag)
		return;
	size_t i,l;
	l = VEC_LENGTH(filters);
	if (l)
		fprintf(stderr,"filters:\n");

	for (i = 0;i < l;++i) {
#ifdef NEEDBINFILTER
		char buf0[256],buf1[256];
		u8 bufx[128];
#endif

		if (!verboseflag && i >= 20) {
			size_t notshown = l - i;
			fprintf(stderr,"[another " FSZ " %s not shown]\n",
				notshown,notshown == 1 ? "filter" : "filters");
			break;
		}

#ifdef INTFILTER
		size_t len = 0;
		u8 *imraw;

# ifndef OMITMASK
		imraw = (u8 *)&VEC_BUF(filters,i).m;
# else
		imraw = (u8 *)&ifiltermask;
# endif
		while (len < sizeof(IFT) && imraw[len] != 0x00) ++len;
		u8 mask = imraw[len-1];
		u8 *ifraw = (u8 *)&VEC_BUF(filters,i).f;
#endif 

#ifdef BINFILTER
		size_t len = VEC_BUF(filters,i).len + 1;
		u8 mask = VEC_BUF(filters,i).mask;
		u8 *ifraw = VEC_BUF(filters,i).f;
#endif 
#ifdef NEEDBINFILTER
		base32_to(buf0,ifraw,len);
		memcpy(bufx,ifraw,len);
		bufx[len - 1] |= ~mask;
		base32_to(buf1,bufx,len);
		char *a = buf0,*b = buf1;
		while (*a && *a == *b)
			++a, ++b;
		*a = 0;
		fprintf(stderr,"\t%s\n",buf0);
#endif 
#ifdef PCRE2FILTER
		fprintf(stderr,"\t%s\n",VEC_BUF(filters,i).str);
#endif 
	}
	fprintf(stderr,"in total, " FSZ " %s\n",l,l == 1 ? "filter" : "filters");
}

void filters_add(const char *filter)
{
#ifdef NEEDBINFILTER
	struct binfilter bf;
	size_t ret;
# ifdef INTFILTER
	union intconv {
		IFT i;
		u8 b[sizeof(IFT)];
	} fc,mc;
# endif

	
	if (*filter == '^')
		++filter;

	memset(&bf,0,sizeof(bf));

	if (!base32_valid(filter,&ret)) {
		fprintf(stderr,"filter \"%s\" is not valid base32 string\n",filter);
		fprintf(stderr,"        ");
		while (ret--)
			fputc(' ',stderr);
		fprintf(stderr,"^\n");
		return;
	}

	ret = BASE32_FROM_LEN(ret);
	if (!ret)
		return;
# ifdef INTFILTER
	size_t maxsz = sizeof(IFT);
# else
	size_t maxsz = sizeof(bf.f);
# endif
	if (ret > maxsz) {
		fprintf(stderr,"filter \"%s\" is too long\n",filter);
		fprintf(stderr,"        ");
		maxsz = (maxsz * 8) / 5;
		while (maxsz--)
			fputc(' ',stderr);
		fprintf(stderr,"^\n");
		return;
	}
	base32_from(bf.f,&bf.mask,filter);
	bf.len = ret - 1;

# ifdef INTFILTER
	mc.i = 0;
	for (size_t i = 0;i < bf.len;++i)
		mc.b[i] = 0xFF;
	mc.b[bf.len] = bf.mask;
	memcpy(fc.b,bf.f,sizeof(fc.b));
	fc.i &= mc.i;

	struct intfilter ifltr = {
		.f = fc.i,
#  ifndef OMITMASK
		.m = mc.i,
#  endif
	};

#  ifdef OMITMASK
	ifilter_addflatten(&ifltr,mc.i);
#  else 
	VEC_ADD(filters,ifltr);
#  endif 
# endif 

# ifdef BINFILTER
	VEC_ADD(filters,bf);
# endif 
#endif 

#ifdef PCRE2FILTER
	int errornum;
	PCRE2_SIZE erroroffset;
	pcre2_code *re;

	re = pcre2_compile((PCRE2_SPTR8)filter,PCRE2_ZERO_TERMINATED,
		PCRE2_NO_UTF_CHECK | PCRE2_ANCHORED,&errornum,&erroroffset,0);
	if (!re) {
		PCRE2_UCHAR buffer[1024];
		pcre2_get_error_message(errornum,buffer,sizeof(buffer));
		fprintf(stderr,"PCRE2 compilation failed at offset " FSZ ": %s\n",
			(size_t)erroroffset,buffer);
		return;
	}

	
	(void) pcre2_jit_compile(re,PCRE2_JIT_COMPLETE);

	struct pcre2filter f;
	memset(&f,0,sizeof(f));
	f.re = re;
	size_t fl = strlen(filter) + 1;
	f.str = (char *) malloc(fl);
	if (!f.str)
		abort();
	memcpy(f.str,filter,fl);
	VEC_ADD(filters,f);
#endif 
}

static void filters_prepare(void)
{
#ifndef PCRE2FILTER
	if (!quietflag)
		fprintf(stderr,"sorting filters...");
	filter_sort();
	if (wantdedup) {
		if (!quietflag)
			fprintf(stderr," removing duplicates...");
		filters_dedup();
	}
	if (!quietflag)
		fprintf(stderr," done.\n");
#endif
}

static bool loadfilterfile(const char *fname)
{
	char buf[128];
	FILE *f = fopen(fname,"r");
	if (!f) {
		fprintf(stderr,"failed to load filter file \"%s\": %s\n",fname,strerror(errno));
		return false;
	}
	while (fgets(buf,sizeof(buf),f)) {
		for (char *p = buf;*p;++p) {
			if (*p == '\n') {
				*p = 0;
				break;
			}
		}
		if (*buf && *buf != '#' && memcmp(buf,"//",2) != 0)
			filters_add(buf);
	}
	int fe = ferror(f);
	fclose(f);
	if (fe != 0) {
		fprintf(stderr,"failure while reading filter file \"%s\": %s\n",fname,strerror(fe));
		return false;
	}
	return true;
}
