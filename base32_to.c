#include <stddef.h>
#include <stdint.h>
#include "types.h"
#include "base32.h"

static const char base32t[32] = {
	'a', 'b', 'c', 'd', 
	'e', 'f', 'g', 'h', 
	'i', 'j', 'k', 'l', 
	'm', 'n', 'o', 'p', 
	'q', 'r', 's', 't', 
	'u', 'v', 'w', 'x', 
	'y', 'z', '2', '3', 
	'4', '5', '6', '7', 
};



char *base32_to(char *dst,const u8 *src,size_t slen)
{
	
	
	
	
	
	size_t i;
	for (i = 0; i + 4 < slen; i += 5) {
		
		
		*dst++ = base32t[src[i+0] >> 3];
		*dst++ = base32t[((src[i+0] & 7) << 2) | (src[i+1] >> 6)];
		*dst++ = base32t[(src[i+1] >> 1) & 31];
		*dst++ = base32t[((src[i+1] & 1) << 4) | (src[i+2] >> 4)];
		*dst++ = base32t[((src[i+2] & 15) << 1) | (src[i+3] >> 7)];
		*dst++ = base32t[((src[i+3]) >> 2) & 31];
		*dst++ = base32t[((src[i+3] & 3) << 3) | (src[i+4] >> 5)];
		*dst++ = base32t[src[i+4] & 31];
		
	}
	
	if (i < slen) {
		
		*dst++ = base32t[src[i+0] >> 3];
		if (i + 1 < slen) {
			
			*dst++ = base32t[((src[i+0] & 7) << 2) | (src[i+1] >> 6)];
			*dst++ = base32t[(src[i+1] >> 1) & 31];
			if (i + 2 < slen) {
				
				*dst++ = base32t[((src[i+1] & 1) << 4) | (src[i+2] >> 4)];
				if (i + 3 < slen) {
					
					*dst++ = base32t[((src[i+2] & 15) << 1) | (src[i+3] >> 7)];
					*dst++ = base32t[(src[i+3] >> 2) & 31];
					*dst++ = base32t[(src[i+3] & 3) << 3];
				}
				else {
					*dst++ = base32t[(src[i+2] & 15) << 1];
				}
			}
			else
				*dst++ = base32t[(src[i+1] & 1) << 4];
		}
		else
			*dst++ = base32t[(src[i+0] & 7) << 2];
	}
	
	*dst = 0;
	return dst;
}
