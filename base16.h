
char *base16_to(char *dst,const u8 *src,size_t slen);

#define BASE16_TO_LEN(l) (((l) * 8 + 3) / 4)

size_t base16_from(u8 *dst,u8 *dmask,const char *src);

#define BASE16_FROM_LEN(l) (((l) * 4 + 7) / 8)

int base16_valid(const char *src,size_t *count);
