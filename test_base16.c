#include <stddef.h>
#include <stdint.h>
#include "types.h"
#include "base16.h"
#include <string.h>
#include <assert.h>
#include <stdio.h>


struct texttestcase {
	const char *in;
	const char *out;
	const char *rev;
} tests0[] = {
	{"", "", ""},
	{"f", "66", "f"},
	{"fo", "666F", "fo"},
	{"foo", "666F6F", "foo"},
	{"foob", "666F6F62", "foob"},
	{"fooba", "666F6F6261", "fooba"},
	{"foobar", "666F6F626172", "foobar"},
};

int main(void)
{
	char buf[1024], buf2[1024], mask;
	size_t r;
	for (size_t i = 0; i < sizeof(tests0)/sizeof(tests0[0]); ++i) {
		base16_to(buf, (const u8 *)tests0[i].in, strlen(tests0[i].in));
		assert(strcmp(buf, tests0[i].out) == 0);
		r = base16_from((u8 *)buf2, (u8 *)&mask, buf);
		buf2[r] = 0;
		
		
		
		
		assert(strcmp(buf2, tests0[i].rev) == 0);
	}

	return 0;
}
