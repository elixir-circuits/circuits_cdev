#ifndef ENIF_GPIO_COMMON_H
#define ENIF_GPIO_COMMON_H

#include "erl_nif.h"

int common_make_int_array_from_list(ErlNifEnv *env, ERL_NIF_TERM list, int length, int buff[]);

ERL_NIF_TERM common_make_and_release_resource(ErlNifEnv *env, void *obj);

ERL_NIF_TERM common_make_error(ErlNifEnv *env, ERL_NIF_TERM term);

#endif
