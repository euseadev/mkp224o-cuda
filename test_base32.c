#include <stddef.h>
#include <stdint.h>
#include "types.h"
#include "base32.h"
#include <string.h>
#include <assert.h>
#include <stdio.h>
#include <sodium/randombytes.h>

struct texttestcase {
	const char *in;
	const char *out;
	const char *rev;
} tests0[] = {
	{"", "", ""},
	{"f", "my", "f"},
	{"fo", "mzxq", "fo"},
	{"foo", "mzxw6", "foo"},
	{"foob", "mzxw6yq", "foob"},
	{"fooba", "mzxw6ytb", "fooba"},
	{"foobar", "mzxw6ytboi", "foobar"},
};



int main(void)
{
	char buf[1024], buf2[1024], mask;
	size_t r;
	for (size_t i = 0; i < sizeof(tests0)/sizeof(tests0[0]); ++i) {
		base32_to(buf, (const u8 *)tests0[i].in, strlen(tests0[i].in));
		assert(strcmp(buf, tests0[i].out) == 0);
		r = base32_from((u8 *)buf2, (u8 *)&mask, buf);
		buf2[r] = 0;
		if (r > 0) {
			assert((buf2[r-1] & ~mask) == 0);
		}
		
		
		
		
		assert(strcmp(buf2, tests0[i].rev) == 0);
	}

	
	
	

	return 0;
}
