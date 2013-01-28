static BN_ULONG e_0[1] = {
	0x0000000000010001, 
};

static BN_ULONG n_0[32] = {
	0x63a2705416a0d8e1, 0xdc9fca11c8ba757b, 
	0xb9c06510cbcb35e3, 0x39e3dfebba941433, 
	0x7bbae38a6c1fce9d, 0x205a5a73fefabba7, 
	0x53ea3e5a97839a2e, 0xfec8f5b661dc0170, 
	0xefe311d8d29a1004, 0x8c6a92d0a5156bb8, 
	0x9067cc767a6eb5cc, 0xd103580b0bd5b1ff, 
	0x4a563e848f3a2daf, 0xacd7cadb46b0943e, 
	0x5fabb688ebd1e198, 0x7e70c1d35916f173, 
	0xaaa8acc85d6ca84e, 0x1685c157e20fd4dc, 
	0xf9e9c9c7ad933f64, 0xbe6272edc5f59824, 
	0x585d9a7d53447bd1, 0x011a5b3f5b3bc30d, 
	0xf312b966ffbbf0e9, 0x2203fb37482c131b, 
	0x3e7c157d0dc38eab, 0xb04de1d6b39fcc8d, 
	0x4d9f013707fc0d84, 0xb075a241e13b5ac5, 
	0x0a9a9d488e56e153, 0xf2cff393f97054eb, 
	0x2a2ead68376024f2, 0xd657997188d35dce, 
};


struct pubkey {
	struct bignum_st e, n;
};

#define KEY(data) {				\
	.d = data,				\
	.top = sizeof(data)/sizeof(data[0]),	\
}

#define KEYS(e,n)	{ KEY(e), KEY(n), }

static struct pubkey keys[] = {
	KEYS(e_0, n_0),
};
