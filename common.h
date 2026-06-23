#define SECRET_LEN 64
#define PUBLIC_LEN 32
#define SEED_LEN   32

#define PUBONION_LEN (PUBLIC_LEN + 3)

#define PKPREFIX_SIZE (29 + 3)
#define SKPREFIX_SIZE (29 + 3)

extern const char * const pkprefix;
extern const char * const skprefix;

#define FORMATTED_PUBLIC_LEN (PKPREFIX_SIZE + PUBLIC_LEN)
#define FORMATTED_SECRET_LEN (SKPREFIX_SIZE + SECRET_LEN)

#define ONION_LEN 62

extern pthread_mutex_t fout_mutex;
extern FILE *fout;

extern size_t onionendpos;   
extern size_t direndpos;     
extern size_t printstartpos; 
extern size_t printlen;      
