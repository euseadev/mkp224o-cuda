#include "sc25519.h"
#include "index_heap.h"

void heap_init(unsigned long long *h, unsigned long long hlen, sc25519 *scalars)
{
  h[0] = 0;
  unsigned long long i=1;
  while(i<hlen)
    heap_push(h, &i, i, scalars);
}

void heap_extend(unsigned long long *h, unsigned long long oldlen, unsigned long long newlen, sc25519 *scalars)
{
  unsigned long long i=oldlen;
  while(i<newlen)
    heap_push(h, &i, i, scalars);
}

void heap_push(unsigned long long *h, unsigned long long *hlen, unsigned long long elem, sc25519 *scalars)
{
  
  
  signed long long pos = *hlen;
  signed long long ppos = (pos-1)/2;
  unsigned long long t;
  h[*hlen] = elem;
  while(pos > 0)
  {
    
    if(sc25519_lt(&scalars[h[ppos]], &scalars[h[pos]]))
    {
      t = h[ppos];
      h[ppos] = h[pos];
      h[pos] = t;
      pos = ppos;
      ppos = (pos-1)/2;
    }
    else break;
  } 
  (*hlen)++;
}

void heap_get2max(unsigned long long *h, unsigned long long *max1, unsigned long long *max2, sc25519 *scalars)
{
  *max1 = h[0];
  *max2 = h[1];
  if(sc25519_lt(&scalars[h[1]],&scalars[h[2]]))
    *max2 = h[2];
}



