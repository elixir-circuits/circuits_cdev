#ifndef CDEV_NIF_H
#define CDEV_NIF_H

#include "erl_nif.h"

typedef struct {
    ErlNifResourceType *gpio_chip_rt;
    ErlNifResourceType *gpio_chip_line_handle_rt;
    ErlNifResourceType *gpio_chip_event_handle_rt;
    ErlNifResourceType *gpio_chip_event_data_rt;

    ERL_NIF_TERM atom_ok;
    ERL_NIF_TERM atom_error;
} chip_priv_t;

#endif