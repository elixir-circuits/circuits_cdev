#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <sys/ioctl.h>
#include <linux/gpio.h>

#include "cdev_nif.h"
#include "enif_gpio_common.h"
#include "gpio_chip.h"

static void chip_res_destructor(ErlNifEnv *env, void *res)
{
    chip_close((struct gpio_chip *) res);
}

static void line_res_destructor(ErlNifEnv *env, void *res)
{
    chip_line_handle_close((struct gpio_chip_line_handle *) res);
}

static void event_res_destructor(ErlNifEnv *env, void *res)
{
    chip_event_handle_close((struct gpio_chip_event_handle *) res);
}

static void event_data_res_destructor(ErlNifEnv *env, void *res) {}

static int load(ErlNifEnv *env, void **priv_data, ERL_NIF_TERM info)
{
    chip_priv_t *priv = enif_alloc(sizeof(chip_priv_t));

    if (!priv) {
        return 1;
    }

    priv->atom_error = enif_make_atom(env, "error");
    priv->atom_ok = enif_make_atom(env, "ok");

    priv->gpio_chip_rt = enif_open_resource_type(env, NULL, "gpio_chip", chip_res_destructor, ERL_NIF_RT_CREATE, NULL);
    priv->gpio_chip_line_handle_rt = enif_open_resource_type(env, NULL, "gpio_line_handle", line_res_destructor, ERL_NIF_RT_CREATE, NULL);
    priv->gpio_chip_event_handle_rt= enif_open_resource_type(env, NULL, "gpio_event_handle", event_res_destructor, ERL_NIF_RT_CREATE, NULL);
    priv->gpio_chip_event_data_rt = enif_open_resource_type(env, NULL, "gpio_event_data", event_data_res_destructor, ERL_NIF_RT_CREATE, NULL);

    *priv_data = (void *) priv;

    return 0;
}

static ERL_NIF_TERM chip_open_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
{
    chip_priv_t *priv = enif_priv_data(env);
    char chip_path[16];
    memset(&chip_path, '\0', sizeof(chip_path));

    if (!enif_get_string(env, argv[0], chip_path, sizeof(chip_path), ERL_NIF_LATIN1))
        return enif_make_badarg(env);

    struct gpio_chip *chip = enif_alloc_resource(priv->gpio_chip_rt, sizeof(struct gpio_chip));

    int rv = chip_open(chip, chip_path);

    if (rv < 0)
        return common_make_error(env, enif_make_atom(env, "open_failed"));

    ERL_NIF_TERM chip_res = common_make_and_release_resource(env, chip);

    return enif_make_tuple2(env, priv->atom_ok, chip_res);
}

static ERL_NIF_TERM get_chip_info_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
{
    chip_priv_t *priv = enif_priv_data(env);
    struct gpio_chip *chip;

    if (argc != 1 || !enif_get_resource(env, argv[0], priv->gpio_chip_rt, (void **)&chip))
        return enif_make_badarg(env);

    int rv = chip_get_info(chip);

    if (rv < 0)
        return common_make_error(env, enif_make_atom(env, "info_get_failed"));

    ERL_NIF_TERM name = enif_make_string(env, chip->name, ERL_NIF_LATIN1);
    ERL_NIF_TERM label = enif_make_string(env, chip->label, ERL_NIF_LATIN1);
    ERL_NIF_TERM number_lines = enif_make_int(env, (int)chip->num_lines);

    return enif_make_tuple4(env, priv->atom_ok, name, label, number_lines);
}

static ERL_NIF_TERM get_line_info_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
{
    chip_priv_t *priv = enif_priv_data(env);
    struct gpio_chip *chip;
    int offset;

    if (argc != 2
            || !enif_get_resource(env, argv[0], priv->gpio_chip_rt, (void **)&chip)
            || !enif_get_int(env, argv[1], &offset))
        return enif_make_badarg(env);

    struct gpio_chip_line_info line_info;

    int rv = chip_get_line_info(chip, offset, &line_info);

    if (rv == -1)
        return common_make_error(env, enif_make_atom(env, "line_info_get_failed"));

    ERL_NIF_TERM direction = enif_make_int(env, line_info.direction);
    ERL_NIF_TERM active_low = enif_make_int(env, line_info.active_low);
    ERL_NIF_TERM name = enif_make_string(env, line_info.name, ERL_NIF_LATIN1);
    ERL_NIF_TERM consumer = enif_make_string(env, line_info.consumer, ERL_NIF_LATIN1);

    return enif_make_tuple5(env, priv->atom_ok, name, consumer, direction, active_low);
}

static ERL_NIF_TERM listen_event_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
{
    chip_priv_t *priv = enif_priv_data(env);
    struct gpio_chip_event_handle *handle;
    struct gpio_chip_event_data *data;

    if (argc != 3
            || !enif_get_resource(env, argv[0], priv->gpio_chip_event_handle_rt, (void **)&handle)
            || !enif_get_resource(env, argv[1], priv->gpio_chip_event_data_rt, (void **)&data))
        return enif_make_badarg(env);

    int select_rv = enif_select(env, handle->fd, ERL_NIF_SELECT_READ, data, NULL, argv[2]);

    if (select_rv < 0)
        return common_make_error(env, enif_make_atom(env, "failed_to_listen_for_events"));

    return priv->atom_ok;
}

static ERL_NIF_TERM make_event_data_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
{
    chip_priv_t *priv = enif_priv_data(env);
    struct gpio_chip_event_handle *handle;

    if (argc != 1
            || !enif_get_resource(env, argv[0], priv->gpio_chip_event_handle_rt, (void **)&handle))
        return enif_make_badarg(env);

    struct enif_event_data *data = enif_alloc_resource(priv->gpio_chip_event_data_rt, sizeof(struct gpio_chip_event_data));
    memset(data, 0, sizeof(struct gpio_chip_event_data));

    ERL_NIF_TERM data_res = common_make_and_release_resource(env, data);

    return enif_make_tuple2(env, priv->atom_ok, data_res);
}

static ERL_NIF_TERM read_event_data_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
{
    chip_priv_t *priv = enif_priv_data(env);
    struct gpio_chip_event_handle *handle;
    struct gpio_chip_event_data *event_data;

    if (argc != 2
            || !enif_get_resource(env, argv[0], priv->gpio_chip_event_handle_rt, (void **)&handle)
            || !enif_get_resource(env, argv[1], priv->gpio_chip_event_data_rt, (void **)&event_data))
        return enif_make_badarg(env);

    int rv = chip_read_event_data(handle, event_data);

    if (rv != 0)
        return common_make_error(env, enif_make_atom(env, "read_event_data_failed"));

    ERL_NIF_TERM value = enif_make_int(env, event_data->id);
    ERL_NIF_TERM timestamp = enif_make_int(env, event_data->timestamp);

    return enif_make_tuple3(env, priv->atom_ok, value, timestamp);

    return priv->atom_ok;
}

static ERL_NIF_TERM read_values_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
{
    chip_priv_t *priv = enif_priv_data(env);
    struct gpio_chip_line_handle *handle;

    if (argc != 1 || !enif_get_resource(env, argv[0], priv->gpio_chip_line_handle_rt, (void **)&handle))
        return enif_make_badarg(env);

    int buff[handle->num_lines];

    int rv = chip_read_values(handle, buff);

    if (rv != 0)
        return common_make_error(env, enif_make_atom(env, "read_values_failed"));

    ERL_NIF_TERM term_array[handle->num_lines];

    for (int i = 0; i < handle->num_lines; i++) {
        ERL_NIF_TERM value = enif_make_int(env, buff[i]);
        term_array[i] = value;
    }

    ERL_NIF_TERM values_list = enif_make_list_from_array(env, term_array, handle->num_lines);

    return enif_make_tuple2(env, priv->atom_ok, values_list);
}

static ERL_NIF_TERM request_event_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
{
    chip_priv_t *priv = enif_priv_data(env);
    struct gpio_chip *chip;
    int offset;

    if (argc != 2
            || !enif_get_resource(env, argv[0], priv->gpio_chip_rt, (void **)&chip)
            || !enif_get_int(env, argv[1], &offset))
        return enif_make_badarg(env);

    struct gpio_chip_event_handle *handle = enif_alloc_resource(priv->gpio_chip_event_handle_rt, sizeof(struct gpio_chip_event_handle));

    int rv = chip_request_event(chip, offset, handle);

    if (rv != 0)
        return common_make_error(env, enif_make_atom(env, "event_request_failed"));

    ERL_NIF_TERM handle_res = common_make_and_release_resource(env, handle);

    return enif_make_tuple2(env, priv->atom_ok, handle_res);
}

static ERL_NIF_TERM request_lines_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
{
    chip_priv_t *priv = enif_priv_data(env);
    struct gpio_chip *chip;
    int direction;
    int num_offsets;

    if (argc != 3
            || !enif_get_resource(env, argv[0], priv->gpio_chip_rt, (void **)&chip)
            || !enif_get_int(env, argv[2], &direction)
            || !enif_get_list_length(env, argv[1], &num_offsets))
        return enif_make_badarg(env);

    int offsets_array[num_offsets];

    int pv = common_make_int_array_from_list(env, argv[1], num_offsets, offsets_array);

    if (pv != 0)
        return enif_make_badarg(env);

    struct gpio_chip_line_handle *line_handle = enif_alloc_resource(priv->gpio_chip_line_handle_rt, sizeof(struct gpio_chip_line_handle));

    line_handle->num_lines = num_offsets;

    int rv = chip_request_lines(chip, offsets_array, direction, line_handle);

    if (rv != 0)
        return common_make_error(env, enif_make_atom(env, "lines_request_failed"));

    ERL_NIF_TERM line_handle_res = common_make_and_release_resource(env, line_handle);

    return enif_make_tuple2(env, priv->atom_ok, line_handle_res);
}

static ERL_NIF_TERM set_values_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
{
    chip_priv_t *priv = enif_priv_data(env);
    struct gpio_chip_line_handle *handle;
    int num_values;

    if (argc != 2
            || !enif_get_resource(env, argv[0], priv->gpio_chip_line_handle_rt, (void **)&handle)
            || !enif_get_list_length(env, argv[1], &num_values))
        return enif_make_badarg(env);

    if (handle->num_lines != num_values) {
        ERL_NIF_TERM msg = enif_make_atom(env, "different_number_of_lines");
        ERL_NIF_TERM err = enif_make_tuple3(env, msg, handle->num_lines, num_values);
        return common_make_error(env, err);
    }

    int values_array[num_values];

    int ar = common_make_int_array_from_list(env, argv[1], num_values, values_array);

    if (ar != 0)
        return common_make_error(env, enif_make_atom(env, "failed_to_parse_values_list"));

    int rv = chip_set_values(handle, values_array);

    if (rv != 0)
        return common_make_error(env, enif_make_atom(env, "failed_to_set_values"));

    return priv->atom_ok;
}

static ErlNifFunc nif_funcs[] = {
    {"chip_open_nif", 1, chip_open_nif, 0},
    {"get_chip_info_nif", 1, get_chip_info_nif, 0},
    {"get_line_info_nif", 2, get_line_info_nif, 0},
    {"listen_event_nif", 3, listen_event_nif, 0},
    {"make_event_data_nif", 1, make_event_data_nif, 0},
    {"read_event_data_nif", 2, read_event_data_nif, 0},
    {"read_values_nif", 1, read_values_nif, 0},
    {"request_event_nif", 2, request_event_nif, 0},
    {"request_lines_nif", 3, request_lines_nif, 0},
    {"set_values_nif", 2, set_values_nif, 0}
};

ERL_NIF_INIT(Elixir.Circuits.GPIO.Chip.Nif, nif_funcs, load, NULL, NULL, NULL)