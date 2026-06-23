AC_INIT(mkp224o)
AC_CONFIG_SRCDIR([main.c])
oldcflags="$CFLAGS"
AC_PROG_CC
ver=""
if test -r "$srcdir/version.txt"
then
	ver=`cat "$srcdir/version.txt"`
elif test -d "$srcdir/.git"
then
	if git --version >/dev/null 2>&1
	then
		ver=`git -C "$srcdir" describe --tags --exact-match 2>/dev/null`
		if test -z "$ver"
		then
			ver=`git -C "$srcdir" rev-parse HEAD 2>/dev/null`
			if test -n "$ver"
			then
				ver=git-$ver
			fi
		fi
		if test -n "$ver"
		then
			if ! git -C "$srcdir" diff --exit-code >/dev/null 2>&1
			then
				ver="$ver"'*'
			fi
		fi
	fi
fi
if test -z "$ver"
then
	ver=unknown
fi
if test x"$oldcflags" != x"$CFLAGS"
then
	oldcflags="-O3"
	CFLAGS="-march=native"
	AC_MSG_CHECKING([whether CC supports -march=native])
	AC_COMPILE_IFELSE([AC_LANG_PROGRAM([])],
		[AC_MSG_RESULT([yes])]
		[oldcflags="$oldcflags -march=native"],
		[AC_MSG_RESULT([no])]
	)
	CFLAGS="-fomit-frame-pointer"
	AC_MSG_CHECKING([whether CC supports -fomit-frame-pointer])
	AC_COMPILE_IFELSE([AC_LANG_PROGRAM([])],
		[AC_MSG_RESULT([yes])]
		[oldcflags="$oldcflags -fomit-frame-pointer"],
		[AC_MSG_RESULT([no])]
	)
	CFLAGS="$oldcflags"
fi
pie=""
oldcflags="$CFLAGS"
CFLAGS="-fPIE -Werror"
AC_MSG_CHECKING([whether CC supports -fPIE])
AC_LINK_IFELSE([AC_LANG_PROGRAM([])],
	[AC_MSG_RESULT([yes])]
	[pie="-fPIE"],
	[AC_MSG_RESULT([no])]
)
CFLAGS="$oldcflags"
MYDEFS=""
MAINLIB=""
ed25519impl=""
AC_ARG_ENABLE([ref10],
	[AS_HELP_STRING([--enable-ref10],
		[use SUPERCOP ref10 ed25519 implementation @<:@default=no@:>@])],
	[
		AS_IF([test x"$ed25519impl" != x"" -a "$ed25519impl" != "ref10"],
			[AC_MSG_ERROR(only one ed25519 implementation can be defined)])
		ed25519impl="ref10"
	],
	[]
)
AC_ARG_ENABLE([amd64-51-30k],
	[AS_HELP_STRING([--enable-amd64-51-30k],
		[use SUPERCOP amd64-51-30k ed25519 implementation @<:@default=no@:>@])],
	[
		AS_IF([test x"$ed25519impl" != x"" -a "$ed25519impl" != "amd64_51_30k"],
			[AC_MSG_ERROR(only one ed25519 implementation can be defined)])
		ed25519impl="amd64_51_30k"
	],
	[]
)
AC_ARG_ENABLE([amd64-64-24k],
	[AS_HELP_STRING([--enable-amd64-64-24k],
		[use SUPERCOP amd64-64-24k ed25519 implementation @<:@default=no@:>@])],
	[
		AS_IF([test x"$ed25519impl" != x"" -a "$ed25519impl" != "amd64_64_24k"],
			[AC_MSG_ERROR(only one ed25519 implementation can be defined)])
		ed25519impl="amd64_64_24k"
	],
	[]
)
AC_ARG_ENABLE([donna],
	[AS_HELP_STRING([--enable-donna],
		[use ed25519-donna implementation @<:@default=yes@:>@])],
	[
		AS_IF([test x"$ed25519impl" != x"" -a "$ed25519impl" != "donna"],
			[AC_MSG_ERROR(only one ed25519 implementation can be defined)])
		ed25519impl="donna"
	],
	[]
)
AC_ARG_ENABLE([donna-sse2],
	[AS_HELP_STRING([--enable-donna-sse2],
		[use ed25519-donna SSE2 implementation @<:@default=no@:>@])],
	[
		AS_IF([test x"$ed25519impl" != x"" -a "$ed25519impl" != "donna-sse2"],
			[AC_MSG_ERROR(only one ed25519 implementation can be defined)])
		ed25519impl="donna-sse2"
	],
	[]
)
AS_IF([test x"$ed25519impl" = x""],[ed25519impl="donna"])
if test "$ed25519impl" = "donna-sse2"
then
	ed25519impl="donna"
	MYDEFS="$MYDEFS -DED25519_SSE2"
	CFLAGS="$CFLAGS -msse2"
fi
AC_ARG_ENABLE([intfilter],
	[AS_HELP_STRING([--enable-intfilter@<:@=(32|64|128|native)@:>@],
		[use integers of specific size @<:@default=64@:>@ for filtering. faster but limits filter length to: 6 for 32-bit, 12 for 64-bit, 24 for 128-bit @<:@default=no@:>@])],
	[], [enable_intfilter=no]
)
AC_ARG_ENABLE([intfilter32],
	[AS_HELP_STRING([--enable-intfilter32], [deprecated. use --enable-intfilter=32 instead])],
	[enable_intfilter=32]
	[AC_MSG_WARN([--enable-intfilter32 option is deprecated. use --enable-intfilter=32 instead])],
	[]
)
case "$enable_intfilter" in
32)
	intfiltertype="u32"
	;;
64|yes)
	intfiltertype="u64"
	;;
128)
	intfiltertype="unsigned __int128"
	;;
native)
	intfiltertype="size_t"
	;;
no|"")
	intfiltertype=""
	;;
*)
	AC_MSG_WARN([unrecognised intfilter type: $enable_intfilter])
	intfiltertype=""
	;;
esac
if test -n "$intfiltertype"
then
	MYDEFS="$MYDEFS -DINTFILTER -DIFT='$intfiltertype'"
fi
AC_ARG_ENABLE([batchnum],
	[AS_HELP_STRING([--enable-batchnum=number],
		[number of elements to batch when using -B @<:@default=2048@:>@])],
	[], []
)
if test -n "$enable_batchnum" -a x"$enable_batchnum" != x"no"
then
	MYDEFS="$MYDEFS -DBATCHNUM=$enable_batchnum"
fi
cstd=""
c99=""
oldcflags="$CFLAGS"
CFLAGS="-std=c99"
AC_MSG_CHECKING([whether CC supports -std=c99])
AC_COMPILE_IFELSE([AC_LANG_PROGRAM([])],
	[AC_MSG_RESULT([yes])]
	[c99="yes"]
	[cstd="-std=c99"],
	[AC_MSG_RESULT([no])]
)
CFLAGS="$cstd -Wall"
AC_MSG_CHECKING([whether CC supports -Wall])
AC_COMPILE_IFELSE([AC_LANG_PROGRAM([])],
	[AC_MSG_RESULT([yes])]
	[cstd="$cstd -Wall"],
	[AC_MSG_RESULT([no])]
)
CFLAGS="$cstd -Wextra"
AC_MSG_CHECKING([whether CC supports -Wextra])
AC_COMPILE_IFELSE([AC_LANG_PROGRAM([])],
	[AC_MSG_RESULT([yes])]
	[cstd="$cstd -Wextra"],
	[AC_MSG_RESULT([no])]
)
CFLAGS="$cstd -Wno-maybe-uninitialized -Werror"
AC_MSG_CHECKING([whether CC supports -Wno-maybe-uninitialized])
AC_COMPILE_IFELSE([AC_LANG_PROGRAM([])],
	[AC_MSG_RESULT([yes])]
	[cstd="$cstd -Wno-maybe-uninitialized"],
	[AC_MSG_RESULT([no])]
)
if test x"$c99" = x"yes" -a x"$ed25519impl" != x"donna" -a x"$enable_intfilter" != x"128"
then
	CFLAGS="$cstd -pedantic"
	AC_MSG_CHECKING([whether CC supports -pedantic])
	AC_COMPILE_IFELSE([AC_LANG_PROGRAM([])],
		[AC_MSG_RESULT([yes])]
		[cstd="$cstd -pedantic"],
		[AC_MSG_RESULT([no])]
	)
fi
CFLAGS="$cstd -Wno-format -Wno-pedantic-ms-format -Werror"
AC_MSG_CHECKING([whether CC supports and needs -Wno-format -Wno-pedantic-ms-format])
AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[
	[AC_MSG_RESULT([yes])]
	[cstd="$cstd -Wno-format -Wno-pedantic-ms-format"],
	[AC_MSG_RESULT([no])]
)
if test x"$ed25519impl" = x"donna"
then
	CFLAGS="$cstd -Wno-unused-function -Werror"
	AC_MSG_CHECKING([whether CC supports -Wno-unused-function])
	AC_COMPILE_IFELSE([AC_LANG_PROGRAM([])],
		[AC_MSG_RESULT([yes])]
		[cstd="$cstd -Wno-unused-function"],
		[AC_MSG_RESULT([no])]
	)
fi
if test x"$ed25519impl" = x"amd64_64_24k"
then
	CFLAGS="$cstd -Wno-unused-const-variable -Werror"
	AC_MSG_CHECKING([whether CC supports -Wno-unused-const-variable])
	AC_COMPILE_IFELSE([AC_LANG_PROGRAM([])],
		[AC_MSG_RESULT([yes])]
		[cstd="$cstd -Wno-unused-const-variable"],
		[AC_MSG_RESULT([no])]
	)
fi
CFLAGS="$cstd -Wmissing-prototypes -Werror"
AC_MSG_CHECKING([whether CC supports -Wmissing-prototypes])
AC_COMPILE_IFELSE([AC_LANG_PROGRAM([])],
	[AC_MSG_RESULT([yes])]
	[cstd="$cstd -Wmissing-prototypes"],
	[AC_MSG_RESULT([no])]
)
CFLAGS="$cstd -Wstrict-prototypes -Werror"
AC_MSG_CHECKING([whether CC supports -Wstrict-prototypes])
AC_COMPILE_IFELSE([AC_LANG_SOURCE([[int main(void) { return 0; }]])],
	[AC_MSG_RESULT([yes])]
	[cstd="$cstd -Wstrict-prototypes"],
	[AC_MSG_RESULT([no])]
)
CFLAGS="$oldcflags"
AC_ARG_ENABLE([binfilterlen],
	[AS_HELP_STRING([--enable-binfilterlen=VAL],
		[set binary string filter length (if you don't use intfilter) @<:@default=32@:>@])],
	[], [enable_binfilterlen=no]
)
if test x"$enable_binfilterlen" != x"yes" -a x"$enable_binfilterlen" != x"no"
then
	MYDEFS="$MYDEFS -DBINFILTERLEN=$enable_binfilterlen"
fi
AC_ARG_ENABLE([binsearch],
	[AS_HELP_STRING([--enable-binsearch],
		[enable binary search algoritm; MUCH faster if there are a lot of filters @<:@default=no@:>@])],
	[], [enable_binsearch=no]
)
if test x"$enable_binsearch" = x"yes"
then
	MYDEFS="$MYDEFS -DBINSEARCH"
fi
AC_ARG_ENABLE([besort],
	[AS_HELP_STRING([--enable-besort],
		[force intfilter binsearch case to use big endian sorting and not omit masks from filters; useful if your filters aren't of same length @<:@default=no@:>@])],
	[], [enable_besort=no]
)
if test x"$enable_besort" = x"yes"
then
	MYDEFS="$MYDEFS -DBESORT"
fi
AC_ARG_ENABLE([statistics],
	[AS_HELP_STRING([--enable-statistics],
		[collect statistics @<:@default=yes@:>@])],
	[], [enable_statistics=yes]
)
if test x"$enable_statistics" = x"yes"
then
	MYDEFS="$MYDEFS -DSTATISTICS"
fi
AC_ARG_WITH([pcre2],[AS_HELP_STRING([--with-pcre2],[pcre2-config executable @<:@default=pcre2-config@:>@])],[],[with_pcre2="pcre2-config"])
AC_ARG_ENABLE([regex],[AS_HELP_STRING([--enable-regex],[whether to enable regex engine. currently possible values are "pcre2" and "yes" which defaults to "pcre2" @<:@default=no@:>@])],[],[enable_regex=no])
case "$enable_regex" in
no|"")
	;;
yes|pcre2)
	AC_MSG_CHECKING([pcre2])
	V=""
	if test "$with_pcre2" != "yes"
	then
		V=`"$with_pcre2" --version 2>/dev/null`
	fi
	if test -n "$V"
	then
		AC_MSG_RESULT([$V])
		MYDEFS="$MYDEFS -DPCRE2FILTER"
		CF=`"$with_pcre2" --cflags`
		if test -n "$CF"
		then
			CFLAGS="$CFLAGS $CF"
		fi
		LF=`"$with_pcre2" --libs8`
		if test -n "$LF"
		then
			MAINLIB="$MAINLIB $LF"
		fi
	else
		AC_MSG_RESULT([not found])
		AC_MSG_ERROR(pcre2-config cannot be executed)
	fi
	;;
*)
	AC_MSG_WARN([unrecognised regex engine type: $enable_regex])
	;;
esac
AC_MSG_CHECKING([whether ARGON2ID13 is supported by libsodium])
AC_COMPILE_IFELSE(
	[AC_LANG_PROGRAM(
		[[
		[[int alg = crypto_pwhash_ALG_ARGON2ID13;(void) alg;]]
	)],
	[AC_MSG_RESULT([yes])]
	[MYDEFS="$MYDEFS -DPASSPHRASE"],
	[AC_MSG_RESULT([no])]
)
NVCC=""
CUDAOBJ=""
CUDALIB=""
CUDALINK='$(CC)'
CUDALINKCF='$(CFLAGS)'
CUDAFLAGS=""
AC_ARG_ENABLE([cuda],
	[AS_HELP_STRING([--enable-cuda],
		[build the CUDA GPU key-generation worker (requires nvcc + a CUDA GPU) @<:@default=no@:>@])],
	[], [enable_cuda=no])
AC_ARG_ENABLE([cuda-batchnum],
	[AS_HELP_STRING([--enable-cuda-batchnum=number],
		[keys per GPU thread batch (default 64; bigger = more local memory per thread) @<:@default=64@:>@])],
	[], [enable_cuda_batchnum=64])
AC_ARG_ENABLE([cuda-tpb],
	[AS_HELP_STRING([--enable-cuda-tpb=number],
		[CUDA threads per block (default 64) @<:@default=64@:>@])],
	[], [enable_cuda_tpb=64])
AC_ARG_ENABLE([cuda-arch],
	[AS_HELP_STRING([--enable-cuda-arch=flag],
		[nvcc -arch flag (default native; e.g. sm_75, compute_80) @<:@default=native@:>@])],
	[], [enable_cuda_arch=native])
if test x"$enable_cuda" = x"yes"
then
	AC_PATH_PROG([NVCC],[nvcc],[no])
	if test x"$NVCC" = x"no"
	then
		AC_MSG_ERROR([--enable-cuda requires nvcc in PATH. Install the CUDA toolkit or pass NVCC=/path/to/nvcc])
	fi
	MYDEFS="$MYDEFS -DCUDA_ENABLE"
	CUDAOBJ="cuda_worker.cu.o"
	CUDALINK='$(NVCC)'
	CUDALINKCF=''
	CUDALIB="-lcudart -lcurand"
	CUDAFLAGS="-DCUDA_ENABLE -DSTATISTICS -DCUDA_BATCH=$enable_cuda_batchnum -DCUDA_TPB=$enable_cuda_tpb -arch=$enable_cuda_arch -O3 -I$srcdir"
	AC_MSG_NOTICE([CUDA enabled: nvcc=$NVCC, batch=$enable_cuda_batchnum, tpb=$enable_cuda_tpb, arch=$enable_cuda_arch])
	AC_MSG_NOTICE([On Windows/MSYS2 you may need: ./configure NVCC='nvcc -ccbin /mingw64/bin/gcc' --enable-cuda])
fi
AC_SUBST([NVCC])
AC_SUBST([CUDAOBJ])
AC_SUBST([CUDALIB])
AC_SUBST([CUDALINK])
AC_SUBST([CUDALINKCF])
AC_SUBST([CUDAFLAGS])
(cd "$srcdir" && find ed25519 -type d) | xargs mkdir -p
AC_SUBST(CSTD,["$cstd"])
AC_SUBST(ED25519IMPL,["$ed25519impl"])
AC_SUBST(MYDEFS,["$MYDEFS"])
AC_SUBST(MAINLIB,["$MAINLIB"])
AC_SUBST(PIE,["$pie"])
AC_SUBST(SRCDIR,["$srcdir"])
AC_SUBST(VERSION,["$ver"])
AC_CONFIG_FILES([GNUmakefile])
AC_OUTPUT
