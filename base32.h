
char *base32_to(char *dst,const u8 *src,size_t slen);

#define BASE32_TO_LEN(l) (((l) * 8 + 4) / 5)

size_t base32_from(u8 *dst,u8 *dmask,const char *src);

#define BASE32_FROM_LEN(l) (((l) * 5 + 7) / 8)

int base32_valid(const char *src,size_t *count);
