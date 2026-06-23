#include <string.h>
#include "crypto_sign.h"
#include "crypto_hash_sha512.h"
#include "ge25519.h"

int crypto_sign(
    unsigned char *sm,unsigned long long *smlen,
    const unsigned char *m,unsigned long long mlen,
    const unsigned char *sk
    )
{
  unsigned char pk[32];
  unsigned char nonce[64];
  unsigned char hram[64];
  sc25519 sck, scs, scsk;
  ge25519 ger;

  
  crypto_sign_pubkey(pk,sk);
  

  *smlen = mlen + 64;
  memmove(sm + 64,m,mlen);
  memmove(sm + 32,sk + 32,32);
  

  crypto_hash_sha512(nonce, sm+32, mlen+32);
  

  sc25519_from64bytes(&sck, nonce);
  ge25519_scalarmult_base(&ger, &sck);
  ge25519_pack(sm, &ger);
  
  
  memmove(sm + 32,pk,32);
  

  crypto_hash_sha512(hram,sm,mlen + 64);
  

  sc25519_from64bytes(&scs, hram);
  sc25519_from32bytes(&scsk, sk);
  sc25519_mul(&scs, &scs, &scsk);
  sc25519_add(&scs, &scs, &sck);
  

  sc25519_to32bytes(sm + 32,&scs);
  

  return 0;
}
