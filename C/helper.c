#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <ctype.h>

#include "common.h"

void AttrMap_print (AttrMap** am, int nb_attributes)
{
	for (int i = 0; i < nb_attributes; i++) {
		AttrMap * m = am[i];
		printf("Attribute: %s, Value: %s\n", m->name, m->value);
	}
}

void AttrMap_free (AttrMap** am, int nb_attributes)
{
	for (int i = 0; i < nb_attributes; i++) {
		AttrMap * m = am[i];
		free ((char *)(m->value));
		free (m);
	}
	free(am);
}

// https://gist.github.com/diabloneo/9619917#gistcomment-3364033
void timespec_diff(struct timespec *a, struct timespec *b, struct timespec *result) {
	result->tv_sec  = a->tv_sec  - b->tv_sec;
	result->tv_nsec = a->tv_nsec - b->tv_nsec;
	if (result->tv_nsec < 0) {
		--result->tv_sec;
		result->tv_nsec += 1000000000L;
	}
}

char** str_split(char* a_str, const char a_delim)
{
	char** result	= NULL;
	size_t count	 = 0;
	char* tmp		= a_str;
	char* last_delim = NULL;
	char delim[2];
	delim[0] = a_delim;
	delim[1] = 0;

	/* Count how many elements will be extracted. */
	while (*tmp)
	{
		if (a_delim == *tmp)
		{
			count++;
			last_delim = tmp;
		}
		tmp++;
	}

	/* Add space for trailing token. */
	count += last_delim < (a_str + strlen(a_str) - 1);

	/* Add space for terminating null string so caller
	   knows where the list of returned strings ends. */
	count++;

	result = malloc(sizeof(char*) * count);

	if (result)
	{
		size_t idx  = 0;
		char* token = strtok(a_str, delim);

		while (token)
		{
			assert(idx < count);
			*(result + idx++) = strdup(token);
			token = strtok(0, delim);
		}
		assert(idx == count - 1);
		*(result + idx) = NULL;
	}

	return result;
}

char* url_encode(const char* str)
{
	char* encoded = malloc(strlen(str) * 3 + 1);  // Maximum size
	if (!encoded) return NULL; // Check for allocation failure

	char* p = encoded;
	while (*str) {
		if (isalnum(*str) || *str == '-' || *str == '_' || *str == '.' || *str == '~') {
			*p++ = *str;  // Keep safe characters
		} else {
			sprintf(p, "%%%02X", (unsigned char)*str);  // Encode the character
			p += 3; // Move pointer forward by 3 (e.g., %20)
		}
		str++;
	}
	*p = '\0'; // Null-terminate the string
	return encoded; // Return the newly allocated string
}
