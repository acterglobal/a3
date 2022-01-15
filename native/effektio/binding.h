#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

int32_t echo(int64_t port, const char *url);

int32_t error_message_utf8(char *buf, int32_t length);

int32_t last_error_length(void);

#ifdef __cplusplus
} // extern "C"
#endif // __cplusplus
