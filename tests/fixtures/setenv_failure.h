#include <stdlib.h>
#include <string.h>

/* Deterministically fail one valid name while preserving real OS behavior otherwise. */
static int vdotenv_test_setenv(const char *name, const char *value, int overwrite) {
    if (strcmp(name, "VDOTENV_FORCE_FAILURE") == 0) {
        /* Keeping an existing value is a successful operation, not a failure. */
        if (!overwrite && getenv(name) != NULL) return 0;
        return -1;
    }
    return setenv(name, value, overwrite);
}
#define setenv vdotenv_test_setenv
