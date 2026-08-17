#include "postgres.h"

#include "ivfflat.h"
#include "vector.h"

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>

int
main(int argc, char **argv)
{
	char	   *end;
	long		dimensions;

	if (argc != 2)
	{
		fprintf(stderr, "usage: %s DIMENSIONS\n", argv[0]);
		return 2;
	}

	errno = 0;
	dimensions = strtol(argv[1], &end, 10);
	if (errno != 0 || *end != '\0' || dimensions <= 0 || dimensions > INT_MAX)
	{
		fprintf(stderr, "dimensions must be a positive integer\n");
		return 2;
	}

	printf("vector_array_data_bytes=%zu\n", sizeof(VectorArrayData));
	printf("vector_header_bytes=%zu\n", offsetof(Vector, x));
	printf("max_alignment_bytes=%d\n", MAXIMUM_ALIGNOF);
	printf("vector_item_bytes=%zu\n", (size_t) VECTOR_SIZE(dimensions));
	printf("aligned_vector_item_bytes=%zu\n", (size_t) MAXALIGN(VECTOR_SIZE(dimensions)));

	return 0;
}
