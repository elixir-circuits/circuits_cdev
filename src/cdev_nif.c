#include <fcntl.h>
#include <sys/ioctl.h>
#include <linux/gpio.h>
#include <string.h>
#include <unistd.h>

#include <errno.h>
#include <stdio.h>

#include "erl_nif.h"

struct cdev_priv {
    ErlNifResourceType *gpio_chip_rt;
    ErlNifResourceType *gpiohandle_request_rt;
};

struct gpio_chip {
    int fd;
};

struct gpio_line_req_handle {
    int fd;
};

static void gpio_chip_dtor(ErlNifEnv *env, void *obj)
{
    struct gpio_chip *chip = (struct gpio_chip*) obj;

    close(chip->fd);
}

static void linehandle_request_dtor(ErlNifEnv *env, void *obj)
{
    struct gpiohandle_request *req = (struct gpiohandle_request*) obj;

    close(req->fd);
}

static int load(ErlNifEnv *env, void **priv_data, const ERL_NIF_TERM info)
{
    (void) info;
    struct cdev_priv *priv = enif_alloc(sizeof(struct cdev_priv));

    if (!priv) {
        return 1;
    }

    priv->gpio_chip_rt = enif_open_resource_type(env, NULL, "gpio_chip", gpio_chip_dtor, ERL_NIF_RT_CREATE, NULL);
    priv->gpiohandle_request_rt = enif_open_resource_type(env, NULL, "gpiohandle_request", linehandle_request_dtor, ERL_NIF_RT_CREATE, NULL);

    if (priv->gpio_chip_rt == NULL) {
        return 2;
    }

    *priv_data = (void *) priv;

    return 0;
}

static ERL_NIF_TERM open_chip(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
{
    struct cdev_priv *priv = enif_priv_data(env);
    char chip_path[16];
    memset(&chip_path, '\0', sizeof(chip_path));
    if (!enif_get_string(env, argv[0], chip_path, sizeof(chip_path), ERL_NIF_LATIN1)) {
        return enif_make_badarg(env);
    }

    struct gpio_chip *chip = enif_alloc_resource(priv->gpio_chip_rt, sizeof(struct gpio_chip));

    chip->fd = open(chip_path, O_RDWR);

    ERL_NIF_TERM chip_resource = enif_make_resource(env, chip);
    enif_release_resource(chip);

    ERL_NIF_TERM ok_atom = enif_make_atom(env, "ok");

    return enif_make_tuple2(env, ok_atom, chip_resource);
}

static ERL_NIF_TERM get_info_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
{
    struct cdev_priv *priv = enif_priv_data(env);
    struct gpio_chip *chip;
    struct gpiochip_info info;

    if (argc != 1 || !enif_get_resource(env, argv[0], priv->gpio_chip_rt, (void **) &chip))
        return enif_make_badarg(env);

    int rv = ioctl(chip->fd, GPIO_GET_CHIPINFO_IOCTL, &info);

    if (rv < 0) {
        return enif_make_atom(env, "error");
    }

    ERL_NIF_TERM chip_name = enif_make_string(env, info.name, ERL_NIF_LATIN1);
    ERL_NIF_TERM chip_label = enif_make_string(env, info.label, ERL_NIF_LATIN1);
    ERL_NIF_TERM number_lines = enif_make_int(env, (int) info.lines);

    return enif_make_tuple3(env, chip_name, chip_label, number_lines);
}

static ERL_NIF_TERM close_chip_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
{
    struct cdev_priv *priv = enif_priv_data(env);
    struct gpio_chip *chip;

    if (argc != 1 || !enif_get_resource(env, argv[0], priv->gpio_chip_rt, (void **) &chip))
        return enif_make_badarg(env);

    close(chip->fd);
    chip->fd = -1;

    return enif_make_atom(env, "ok");
}

static ERL_NIF_TERM get_line_info_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
{
    struct cdev_priv *priv = enif_priv_data(env);
    struct gpio_chip *chip;
    struct gpioline_info info;
    int rv, offset;

    if (argc != 2 || !enif_get_resource(env, argv[0], priv->gpio_chip_rt, (void **) &chip) || !enif_get_int(env, argv[1], &offset))
        return enif_make_badarg(env);

    info.line_offset = offset;

    rv = ioctl(chip->fd, GPIO_GET_LINEINFO_IOCTL, &info);

    ERL_NIF_TERM flags = enif_make_int(env, info.flags);
    ERL_NIF_TERM name = enif_make_string(env, info.name, ERL_NIF_LATIN1);
    ERL_NIF_TERM consumer = enif_make_string(env, info.consumer, ERL_NIF_LATIN1);

    return enif_make_tuple3(env, flags, name, consumer);
}

/**
 * Will update to do many offsets, just going this route while doing
 * initial development
 */
static ERL_NIF_TERM request_linehandle_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
{
    struct cdev_priv *priv = enif_priv_data(env);
    struct gpio_chip *chip;
    char consumer[32];
    int rv, lineoffset, flags, default_value;

    if (argc != 5
            || !enif_get_int(env, argv[0], &lineoffset)
            || !enif_get_int(env, argv[1], &flags)
            || !enif_get_int(env, argv[2], &default_value)
            || !enif_get_string(env, argv[3], consumer, sizeof(consumer), ERL_NIF_LATIN1)
            || !enif_get_resource(env, argv[4], priv->gpio_chip_rt, (void **) chip))
        return enif_make_badarg(env);

    struct gpiohandle_request *req = enif_alloc_resource(priv->gpiohandle_request_rt, sizeof(struct gpiohandle_request));

    req->flags = flags;
    req->lines = 1;
    req->lineoffsets[0] = lineoffset;
    req->default_values[0] = default_value;

    rv = ioctl(chip->fd, GPIO_GET_LINEHANDLE_IOCTL, req);

    if (rv < 0)
        return enif_make_atom(env, "error"); // make better

    ERL_NIF_TERM linehandle_resource = enif_make_resource(env, req);
    enif_release_resource(req);

    ERL_NIF_TERM ok_atom = enif_make_atom(env, "ok");

    return enif_make_tuple2(env, ok_atom, linehandle_resource);
}


static ErlNifFunc nif_funcs[] = {
    {"open", 1, open_chip},
    {"close", 1, close_chip_nif},
    {"get_info", 1, get_info_nif},
    {"get_line_info", 2, get_line_info_nif},
    {"request_linehandle", 5, request_linehandle_nif}
};

ERL_NIF_INIT(Elixir.Circuits.GPIO.Chip.Nif, nif_funcs, load, NULL, NULL, NULL)


