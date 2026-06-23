
char *base64_to(char *dst,const u8 *src,size_t slen);

#define BASE64_TO_LEN(l) ((((l) + 2) / 3) * 4)

size_t base64_from(u8 *dst,const char *src,size_t slen);

#define BASE64_FROM_LEN(l) ((l) / 4 * 3)

int base64_valid(const char *src,size_t *count);

#define BASE64_DATA_ALIGN(l) ((((l) + 2) / 3) * 3)
