#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include "types.h"
#include "ioutil.h"
#include "vec.h"
#include <stdio.h>

#ifndef _WIN32

#include <errno.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

int writeall(FH fd,const u8 *data,size_t len)
{
	ssize_t wrote;
	while (len) {
		wrote = write(fd,data,len);
		if (wrote == -1) {
			if (errno == EAGAIN || errno == EWOULDBLOCK || errno == EINTR)
				continue;
			return -1;
		}
		len -= (size_t) wrote;
		data += wrote;
	}
	return 0;
}

FH createfile(const char *path,int secret)
{
	int fd;
	do {
		fd = open(path,O_WRONLY | O_CREAT | O_TRUNC,secret ? 0600 : 0666);
		if (fd < 0) {
			if (errno == EINTR)
				continue;
			return -1;
		}
	} while (0);
	return fd;
}

int closefile(FH fd)
{
	int cret;
	do {
		cret = close(fd);
		if (cret < 0) {
			if (errno == EINTR)
				continue;
			return -1;
		}
	} while (0);
	return 0;
}

int createdir(const char *path,int secret)
{
	return mkdir(path,secret ? 0700 : 0777);
}

static int syncwritefile(const char *filename,const char *tmpname,int secret,const u8 *data,size_t datalen)
{
	FH f = createfile(tmpname,secret);
	if (f == FH_invalid)
		return -1;

	if (writeall(f,data,datalen) < 0) {
		goto failclose;
	}

	int sret;
	do {
		sret = fsync(f);
		if (sret < 0) {
			if (errno == EINTR)
				continue;

			goto failclose;
		}
	} while (0);

	if (closefile(f) < 0) {
		goto failrm;
	}

	if (rename(tmpname,filename) < 0) {
		goto failrm;
	}

	return 0;

failclose:
	(void) closefile(f);
failrm:
	remove(tmpname);

	return -1;
}

int syncwrite(const char *filename,int secret,const u8 *data,size_t datalen)
{
	

	size_t fnlen = strlen(filename);

	VEC_STRUCT(,char) tmpnamebuf;
	VEC_INIT(tmpnamebuf);
	VEC_ADDN(tmpnamebuf,fnlen + 4  + 1 );
	memcpy(&VEC_BUF(tmpnamebuf,0),filename,fnlen);
	strcpy(&VEC_BUF(tmpnamebuf,fnlen),".tmp");
	const char *tmpname = &VEC_BUF(tmpnamebuf,0);

	

	int r = syncwritefile(filename,tmpname,secret,data,datalen);

	VEC_FREE(tmpnamebuf);

	if (r < 0)
		return r;

	VEC_STRUCT(,char) dirnamebuf;
	VEC_INIT(dirnamebuf);
	const char *dirname;

	for (ssize_t x = ((ssize_t)fnlen) - 1;x >= 0;--x) {
		if (filename[x] == '/') {
			if (x)
				--x;
			++x;
			VEC_ADDN(dirnamebuf,x + 1);
			memcpy(&VEC_BUF(dirnamebuf,0),filename,x);
			VEC_BUF(dirnamebuf,x) = '\0';
			dirname = &VEC_BUF(dirnamebuf,0);
			goto foundslash;
		}
	}
	
	dirname = ".";

foundslash:
	
	;

	int dirf;
	do {
		dirf = open(dirname,O_RDONLY);
		if (dirf < 0) {
			if (errno == EINTR)
				continue;

			
			goto skipdsync; 
		}
	} while (0);

	int sret;
	do {
		sret = fsync(dirf);
		if (sret < 0) {
			if (errno == EINTR)
				continue;

			
			break; 
		}
	} while (0);

	(void) closefile(dirf); 

skipdsync:
	VEC_FREE(dirnamebuf);

	return 0;
}

#else

int writeall(FH fd,const u8 *data,size_t len)
{
	DWORD wrote;
	BOOL success;
	while (len) {
		success = WriteFile(fd,data,
			len <= (DWORD)-1 ? (DWORD)len : (DWORD)-1,&wrote,0);
		if (!success)
			return -1;
		data += wrote;
		if (len >= wrote)
			len -= wrote;
		else
			len = 0;
	}
	return 0;
}

FH createfile(const char *path,int secret)
{
	
	
	(void) secret;
	return CreateFileA(path,GENERIC_WRITE,0,0,CREATE_ALWAYS,0,0);
}

int closefile(FH fd)
{
	return CloseHandle(fd) ? 0 : -1;
}

int createdir(const char *path,int secret)
{
	
	(void) secret;
	if (CreateDirectoryA(path,0))
		return 0;
	DWORD err = GetLastError();
	if (err == ERROR_ALREADY_EXISTS) {
		
		DWORD attr = GetFileAttributesA(path);
		if (attr != INVALID_FILE_ATTRIBUTES && (attr & FILE_ATTRIBUTE_DIRECTORY))
			return 0;
	}
	return -1;
}

static int syncwritefile(const char *filename,const char *tmpname,int secret,const u8 *data,size_t datalen)
{
	FH f = createfile(tmpname,secret);
	if (f == FH_invalid) {
		
		return -1;
	}

	if (writeall(f,data,datalen) < 0) {
		
		goto failclose;
	}

	if (FlushFileBuffers(f) == 0) {
		
		goto failclose;
	}

	if (closefile(f) < 0) {
		
		goto failrm;
	}

	if (MoveFileExA(tmpname,filename,MOVEFILE_REPLACE_EXISTING) == 0) {
		
		goto failrm;
	}

	return 0;

failclose:
	(void) closefile(f);
failrm:
	remove(tmpname);

	return -1;
}

int syncwrite(const char *filename,int secret,const u8 *data,size_t datalen)
{
	size_t fnlen = strlen(filename);

	VEC_STRUCT(,char) tmpnamebuf;
	VEC_INIT(tmpnamebuf);
	VEC_ADDN(tmpnamebuf,fnlen + 4  + 1 );
	memcpy(&VEC_BUF(tmpnamebuf,0),filename,fnlen);
	strcpy(&VEC_BUF(tmpnamebuf,fnlen),".tmp");
	const char *tmpname = &VEC_BUF(tmpnamebuf,0);

	int r = syncwritefile(filename,tmpname,secret,data,datalen);

	VEC_FREE(tmpnamebuf);

	if (r < 0)
		return r;

	

	return 0;
}

#endif

int writetofile(const char *path,const u8 *data,size_t len,int secret)
{
	FH fd = createfile(path,secret);
	int wret = writeall(fd,data,len);
	int cret = closefile(fd);
	if (cret == -1)
		return -1;
	return wret;
}
