#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

typedef struct wire_Client {
  uint32_t field0;
} wire_Client;

typedef struct wire_uint_8_list {
  uint8_t *ptr;
  int32_t len;
} wire_uint_8_list;

typedef struct WireSyncReturnStruct {
  uint8_t *ptr;
  int32_t len;
  bool success;
} WireSyncReturnStruct;

typedef int64_t DartPort;

typedef bool (*DartPostCObjectFnType)(DartPort port_id, void *message);

void wire_avatar_url(int64_t port_, struct wire_Client *h);

void wire_logged_in(int64_t port_, struct wire_Client *h);

void wire_homeserver(int64_t port_, struct wire_Client *h);

void wire_new_client(int64_t port_, struct wire_uint_8_list *url);

void wire_echo(int64_t port_, struct wire_uint_8_list *url);

void wire_init(int64_t port_);

struct wire_Client *new_box_autoadd_client(void);

struct wire_uint_8_list *new_uint_8_list(int32_t len);

void free_WireSyncReturnStruct(struct WireSyncReturnStruct val);

void store_dart_post_cobject(DartPostCObjectFnType ptr);

static int64_t dummy_method_to_enforce_bundling(void) {
    int64_t dummy_var = 0;
    dummy_var ^= ((int64_t) (void*) wire_avatar_url);
    dummy_var ^= ((int64_t) (void*) wire_logged_in);
    dummy_var ^= ((int64_t) (void*) wire_homeserver);
    dummy_var ^= ((int64_t) (void*) wire_new_client);
    dummy_var ^= ((int64_t) (void*) wire_echo);
    dummy_var ^= ((int64_t) (void*) wire_init);
    dummy_var ^= ((int64_t) (void*) new_box_autoadd_client);
    dummy_var ^= ((int64_t) (void*) new_uint_8_list);
    dummy_var ^= ((int64_t) (void*) free_WireSyncReturnStruct);
    dummy_var ^= ((int64_t) (void*) store_dart_post_cobject);
    return dummy_var;
}