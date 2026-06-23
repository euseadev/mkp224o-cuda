#ifndef SC_H
#define SC_H


#define sc_reduce CRYPTO_NAMESPACE(sc_reduce)
#define sc_muladd CRYPTO_NAMESPACE(sc_muladd)

extern void sc_reduce(unsigned char *);
extern void sc_muladd(unsigned char *,const unsigned char *,const unsigned char *,const unsigned char *);

#endif
