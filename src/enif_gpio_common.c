#include "enif_gpio_common.h"
#include "cdev_nif.h"

int common_make_int_array_from_list(ErlNifEnv *env, ERL_NIF_TERM list, int length, int buff[])
{
    ERL_NIF_TERM head;
    ERL_NIF_TERM tail;

    for (int i = 0; i < length; i++) {
        int value;

        enif_get_list_cell(env, list, &head, &tail);

        if (!enif_get_int(env, head, &value))
            return -1;

        buff[i] = value;

        list = tail;
    }

    return 0;
}

ERL_NIF_TERM common_make_and_release_resource(ErlNifEnv *env, void *obj)
{
    ERL_NIF_TERM resource = enif_make_resource(env, obj);
    enif_release_resource(obj);

    return resource;
}

ERL_NIF_TERM common_make_error(ErlNifEnv *env, ERL_NIF_TERM error)
{
    chip_priv_t *priv = enif_priv_data(env);

    return enif_make_tuple2(env, priv->atom_error, error);
}
