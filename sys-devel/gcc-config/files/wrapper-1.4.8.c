/*
 * Copyright 1999-2005 Gentoo Foundation
 * Distributed under the terms of the GNU General Public License v2
 * $Header: /var/cvsroot/gentoo-x86/sys-devel/gcc-config/files/wrapper-1.4.8.c,v 1.1 2007/04/11 08:51:31 vapier Exp $
 * Author: Martin Schlemmer <azarah@gentoo.org>
 * az's lackey: Mike Frysinger <vapier@gentoo.org>
 */

#define _REENTRANT
#define _GNU_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/param.h>
#include <unistd.h>
#include <sys/wait.h>
#include <libgen.h>
#include <string.h>
#include <stdarg.h>
#include <errno.h>

#define GCC_CONFIG "/usr/bin/gcc-config"
#define ENVD_BASE  "/etc/env.d/05gcc"

struct wrapper_data {
	char name[MAXPATHLEN + 1];
	char fullname[MAXPATHLEN + 1];
	char bin[MAXPATHLEN + 1];
	char tmp[MAXPATHLEN + 1];
	char *path;
};

static struct {
	char *alias;
	char *target;
} wrapper_aliases[] = {
	{ "cc",  "gcc" },
	{ "f77", "g77" },
	{ NULL, NULL }
};

static const char *wrapper_strerror(int err, struct wrapper_data *data)
{
	/* this app doesn't use threads and strerror
	 * is more portable than strerror_r */
	strncpy(data->tmp, strerror(err), sizeof(data->tmp));
	return data->tmp;
}

static void wrapper_exit(char *msg, ...)
{
	va_list args;
	fprintf(stderr, "gcc-config error: ");
	va_start(args, msg);
	vfprintf(stderr, msg, args);
	va_end(args);
	exit(1);
}

/* check_for_target checks in path for the file we are seeking
 * it returns 1 if found (with data->bin setup), 0 if not and
 * negative on error
 */
static int check_for_target(char *path, struct wrapper_data *data)
{
	struct stat sbuf;
	int result;
	char str[MAXPATHLEN + 1];
	size_t len = strlen(path) + strlen(data->name) + 2;

	snprintf(str, len, "%s/%s", path, data->name);

	/* Stat possible file to check that
	 * 1) it exist and is a regular file, and
	 * 2) it is not the wrapper itself, and
	 * 3) it is in a /gcc-bin/ directory tree
	 */
	result = stat(str, &sbuf);
	if ((result == 0) && \
	    ((sbuf.st_mode & S_IFREG) || (sbuf.st_mode & S_IFLNK)) && \
	    (strcmp(str, data->fullname) != 0) && \
	    (strstr(str, "/gcc-bin/") != 0)) {

		strncpy(data->bin, str, MAXPATHLEN);
		data->bin[MAXPATHLEN] = 0;
		result = 1;
	} else
		result = 0;

	return result;
}

static int find_target_in_path(struct wrapper_data *data)
{
	char *token = NULL, *state;
	char str[MAXPATHLEN + 1];

	if (data->path == NULL) return 0;

	/* Make a copy since strtok_r will modify path */
	snprintf(str, MAXPATHLEN + 1, "%s", data->path);

	token = strtok_r(str, ":", &state);

	/* Find the first file with suitable name in PATH.  The idea here is
	 * that we do not want to bind ourselfs to something static like the
	 * default profile, or some odd environment variable, but want to be
	 * able to build something with a non default gcc by just tweaking
	 * the PATH ... */
	while ((token != NULL) && strlen(token)) {
		if (check_for_target(token, data))
			return 1;
		token = strtok_r(NULL, ":", &state);
	}

	return 0;
}

/* find_target_in_envd parses /etc/env.d/05gcc, and tries to
 * extract PATH, which is set to the current profile's bin
 * directory ...
 */
static int find_target_in_envd(struct wrapper_data *data, int cross_compile)
{
	FILE *envfile = NULL;
	char *token = NULL, *state;
	char str[MAXPATHLEN + 1];
	char *strp = str;
	char envd_file[MAXPATHLEN + 1];

	if (!cross_compile) {
		snprintf(envd_file, MAXPATHLEN, "%s", ENVD_BASE);
	} else {
		char *ctarget, *end = strrchr(data->name, '-');
		if (end == NULL)
			return 0;
		ctarget = strdup(data->name);
		ctarget[end - data->name] = '\0';
		snprintf(envd_file, MAXPATHLEN, "%s-%s", ENVD_BASE, ctarget);
		free(ctarget);
	}
	envfile = fopen(envd_file, "r");
	if (envfile == NULL)
		return 0;

	while (0 != fgets(strp, MAXPATHLEN, envfile)) {
		/* Keep reading ENVD_FILE until we get a line that
		 * starts with 'PATH='
		 */
		if (((strp) && (strlen(strp) > strlen("PATH=")) &&
		    !strncmp("PATH=", strp, strlen("PATH=")))) {

			token = strtok_r(strp, "=", &state);
			if ((token != NULL) && strlen(token))
				/* The second token should be the value of PATH .. */
				token = strtok_r(NULL, "=", &state);
			else
				goto bail;

			if ((token != NULL) && strlen(token)) {
				strp = token;
				/* A bash variable may be unquoted, quoted with " or
				 * quoted with ', so extract the value without those ..
				 */
				token = strtok(strp, "\n\"\'");

				while (token != NULL) {
					if (check_for_target(token, data)) {
						fclose(envfile);
						return 1;
					}

					token = strtok(NULL, "\n\"\'");
				}
			}
		}
		strp = str;
	}

bail:
	fclose(envfile);
	return (cross_compile ? 0 : find_target_in_envd(data, 1));
}

static void find_wrapper_target(struct wrapper_data *data)
{
	FILE *inpipe = NULL;
	char str[MAXPATHLEN + 1];

	if (find_target_in_path(data))
		return;

	if (find_target_in_envd(data, 0))
		return;

	/* Only our wrapper is in PATH, so
	   get the CC path using gcc-config and
	   execute the real binary in there... */
	inpipe = popen(GCC_CONFIG " --get-bin-path", "r");
	if (inpipe == NULL)
		wrapper_exit(
			"Could not open pipe: %s\n",
			wrapper_strerror(errno, data));

	if (fgets(str, MAXPATHLEN, inpipe) == 0)
		wrapper_exit(
			"Could not get compiler binary path: %s\n",
			wrapper_strerror(errno, data));

	strncpy(data->bin, str, sizeof(data->bin) - 1);
	data->bin[strlen(data->bin) - 1] = '/';
	strncat(data->bin, data->name, sizeof(data->bin) - 1);
	data->bin[MAXPATHLEN] = 0;

	pclose(inpipe);
}

/* This function modifies PATH to have gcc's bin path appended */
static void modify_path(struct wrapper_data *data)
{
	char *newpath = NULL, *token = NULL, *state;
	char dname_data[MAXPATHLEN + 1], str[MAXPATHLEN + 1];
	char *str2 = dname_data, *dname = dname_data;
	size_t len = 0;

	if (data->bin == NULL)
		return;

	snprintf(str2, MAXPATHLEN + 1, "%s", data->bin);

	if ((dname = dirname(str2)) == NULL)
		return;

	if (data->path == NULL)
		return;

	/* Make a copy since strtok_r will modify path */
	snprintf(str, MAXPATHLEN + 1, "%s", data->path);

	token = strtok_r(str, ":", &state);

	/* Check if we already appended our bin location to PATH */
	if ((token != NULL) && strlen(token)) {
		if (!strcmp(token, dname))
			return;
	}

	len = strlen(dname) + strlen(data->path) + 2 + strlen("PATH") + 1;

	newpath = (char *)malloc(len);
	if (newpath == NULL)
		wrapper_exit("out of memory\n");
	memset(newpath, 0, len);

	snprintf(newpath, len, "PATH=%s:%s", dname, data->path);
	putenv(newpath);
}

static char *abi_flags[] = {
	"-m32", "-m64", "-mabi", NULL
};
static char **build_new_argv(char **argv, const char *newflags_str)
{
#define MAX_NEWFLAGS 32
	char *newflags[MAX_NEWFLAGS];
	char **retargv;
	unsigned int argc, i;
	char *state, *flags_tokenized;

	retargv = argv;

	/* make sure user hasn't specified any ABI flags already ...
	 * if they have, lets just get out of here */
	for (argc = 0; argv[argc]; ++argc)
		for (i = 0; abi_flags[i]; ++i)
			if (!strncmp(argv[argc], abi_flags[i], strlen(abi_flags[i])))
				return retargv;

	/* Tokenize the flag list and put it into newflags array */
	flags_tokenized = strdup(newflags_str);
	if (flags_tokenized == NULL)
		return retargv;
	i = 0;
	newflags[i] = strtok_r(flags_tokenized, " \t\n", &state);
	while (newflags[i] != NULL && i < MAX_NEWFLAGS-1)
		newflags[++i] = strtok_r(NULL, " \t\n", &state);

	/* allocate memory for our spiffy new argv */
	retargv = (char**)calloc(argc + i + 1, sizeof(char*));
	/* start building retargv */
	retargv[0] = argv[0];
	/* insert the ABI flags first so cmdline always overrides ABI flags */
	memcpy(retargv+1, newflags, i * sizeof(char*));
	/* copy over the old argv */
	if (argc > 1)
		memcpy(retargv+1+i, argv+1, (argc-1) * sizeof(char*));

	return retargv;
}

int main(int argc, char *argv[])
{
	struct wrapper_data data;
	size_t size;
	int i;
	char **newargv = argv;

	memset(&data, 0, sizeof(data));

	if (getenv("PATH")) {
		data.path = strdup(getenv("PATH"));
		if (data.path == NULL)
			wrapper_exit("%s wrapper: out of memory\n", argv[0]);
	}

	/* What should we find ? */
	strcpy(data.name, basename(argv[0]));

	/* Allow for common compiler names like cc->gcc */
	for (i = 0; wrapper_aliases[i].alias; ++i)
		if (!strcmp(data.name, wrapper_aliases[i].alias))
			strcpy(data.name, wrapper_aliases[i].target);

	/* What is the full name of our wrapper? */
	size = sizeof(data.fullname);
	i = snprintf(data.fullname, size, "/usr/bin/%s", data.name);
	if ((i == -1) || (i > (int)size))
		wrapper_exit("invalid wrapper name: \"%s\"\n", data.name);

	find_wrapper_target(&data);

	modify_path(&data);

	if (data.path)
		free(data.path);
	data.path = NULL;

	/* Set argv[0] to the correct binary, else gcc can't find internal headers
	 * http://bugs.gentoo.org/show_bug.cgi?id=8132 */
	argv[0] = data.bin;

	/* If this is g{cc,++}{32,64}, we need to add -m{32,64}
	 * otherwise  we need to add ${CFLAGS_${ABI}}
	 */
	size = strlen(data.bin) - 2;
	if(!strcmp(data.bin + size, "32") ) {
		*(data.bin + size) = '\0';
		newargv = build_new_argv(argv, "-m32");
	} else if (!strcmp(data.bin + size, "64") ) {
		*(data.bin + size) = '\0';
		newargv = build_new_argv(argv, "-m64");
	} else if(getenv("ABI")) {
		char envvar[50];

		/* We use CFLAGS_${ABI} for gcc, g++, g77, etc as they are
		 * the same no matter which compiler we are using.
		 */
		snprintf(envvar, sizeof(envvar), "CFLAGS_%s", getenv("ABI"));

		if (getenv(envvar)) {
			newargv = build_new_argv(argv, getenv(envvar));
			if(!newargv)
				wrapper_exit("%s wrapper: out of memory\n", argv[0]);
		}
	}

	/* Ok, lets do it one more time ... */
	if (execv(data.bin, newargv) < 0)
		wrapper_exit("Could not run/locate \"%s\"\n", data.name);

	return 0;
}
