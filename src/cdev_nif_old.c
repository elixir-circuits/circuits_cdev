
// static ERL_NIF_TERM close_chip_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
// {
//     struct cdev_priv *priv = enif_priv_data(env);
//     struct gpio_chip *chip;

//     if (argc != 1 || !enif_get_resource(env, argv[0], priv->gpio_chip_rt, (void **)&chip))
//         return enif_make_badarg(env);

//     close(chip->fd);
//     chip->fd = -1;

//     return enif_make_atom(env, "ok");
// }

// /**
//  * Will update to do many offsets, just going this route while doing
//  * initial development
//  */
// static ERL_NIF_TERM request_linehandle_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
// {
//     struct cdev_priv *priv = enif_priv_data(env);
//     struct gpio_chip *chip;
//     char consumer[32];
//     int rv, lineoffset, flags, default_value;

//     if (argc != 5 || !enif_get_resource(env, argv[0], priv->gpio_chip_rt, (void **)&chip) || !enif_get_int(env, argv[1], &lineoffset) || !enif_get_int(env, argv[2], &default_value) || !enif_get_int(env, argv[3], &flags) || !enif_get_string(env, argv[4], consumer, sizeof(consumer), ERL_NIF_LATIN1))
//         return enif_make_badarg(env);

//     struct gpiohandle_request *req = enif_alloc_resource(priv->gpiohandle_request_rt, sizeof(struct gpiohandle_request));

//     memset(req, 0, sizeof(struct gpiohandle_request));

//     req->flags = flags;
//     req->lines = 1;
//     req->lineoffsets[0] = lineoffset;
//     req->default_values[0] = default_value;
//     strncpy(req->consumer_label, consumer, sizeof(req->consumer_label) - 1);

//     rv = ioctl(chip->fd, GPIO_GET_LINEHANDLE_IOCTL, req);

//     if (rv < 0)
//         return enif_make_atom(env, "error"); // make better

//     ERL_NIF_TERM linehandle_resource = enif_make_resource(env, req);
//     enif_release_resource(req);

//     ERL_NIF_TERM ok_atom = enif_make_atom(env, "ok");

//     return enif_make_tuple2(env, ok_atom, linehandle_resource);
// }

// static ERL_NIF_TERM set_value_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
// {
//     struct cdev_priv *priv = enif_priv_data(env);
//     struct gpiohandle_request *req;
//     struct gpiohandle_data data;
//     int rv, new_value;

//     if (argc != 2 || !enif_get_resource(env, argv[0], priv->gpiohandle_request_rt, (void **)&req) || !enif_get_int(env, argv[1], &new_value))
//         return enif_make_badarg(env);

//     data.values[0] = new_value;

//     rv = ioctl(req->fd, GPIOHANDLE_SET_LINE_VALUES_IOCTL, &data);

//     if (rv < 0)
//         return enif_make_atom(env, "error"); // make better

//     return enif_make_atom(env, "ok");
// }

// static ERL_NIF_TERM get_value_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
// {
//     struct cdev_priv *priv = enif_priv_data(env);
//     struct gpiohandle_request *req;
//     struct gpiohandle_data data;
//     int rv;

//     if (argc != 1 || !enif_get_resource(env, argv[0], priv->gpiohandle_request_rt, (void **)&req))
//         return enif_make_badarg(env);

//     memset(&data, 0, sizeof(data));

//     rv = ioctl(req->fd, GPIOHANDLE_GET_LINE_VALUES_IOCTL, &data);

//     if (rv < 0)
//         return enif_make_atom(env, "error"); // make better

//     ERL_NIF_TERM value = enif_make_int(env, data.values[0]);
//     ERL_NIF_TERM ok_atom = enif_make_atom(env, "ok");

//     return enif_make_tuple2(env, ok_atom, value);
// }

// int offsets_for_req(ErlNifEnv *env, struct gpiohandle_request *req, ERL_NIF_TERM offsets)
// {
//     ERL_NIF_TERM head, tail;
//     ERL_NIF_TERM list = offsets;
//     int offsets_length;

//     if (!enif_get_list_length(env, offsets, &offsets_length))
//         return -1;

//     for (int i = 0; i < offsets_length; i++)
//     {
//         int offset;
//         if (!enif_get_list_cell(env, list, &head, &tail))
//             return -1;

//         if (!enif_get_int(env, head, &offset))
//             return -1;

//         req->lineoffsets[i] = offset;

//         list = tail;
//     }

//     return 0;
// }

// int defaults_for_req(ErlNifEnv *env, struct gpiohandle_request *req, ERL_NIF_TERM defaults)
// {
//     ERL_NIF_TERM head, tail;
//     ERL_NIF_TERM list = defaults;
//     int defaults_length;

//     if (!enif_get_list_length(env, defaults, &defaults_length))
//         return -1;

//     for (int i = 0; i < defaults_length; i++)
//     {
//         int default_value;
//         if (!enif_get_list_cell(env, list, &head, &tail))
//             return -1;

//         if (!enif_get_int(env, head, &default_value))
//             return -1;

//         req->default_values[i] = default_value;

//         list = tail;
//     }

//     return 0;
// }

// static ERL_NIF_TERM request_lineevent_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
// {
//     struct cdev_priv *priv = enif_priv_data(env);
//     struct gpio_chip *chip;
//     int flags, lineoffset;
//     char consumer[32];

//     if (argc != 5)
//         return enif_make_badarg(env);

//     if (!enif_get_resource(env, argv[0], priv->gpio_chip_rt, (void **)&chip))
//         return enif_make_badarg(env);

//     if (!enif_get_int(env, argv[1], &lineoffset))
//         return enif_make_badarg(env);

//     if (!enif_get_int(env, argv[2], &flags))
//         return enif_make_badarg(env);

//     if (!enif_get_string(env, argv[3], consumer, sizeof(consumer), ERL_NIF_LATIN1))
//         return enif_make_badarg(env);

//     struct gpioevent_request *req = enif_alloc_resource(priv->gpioevent_request_rt, sizeof(struct gpioevent_request));
//     memset(req, 0, sizeof(struct gpioevent_request));

//     req->lineoffset = lineoffset;
//     req->handleflags = GPIOHANDLE_REQUEST_INPUT; // Output does not make sense here
//     req->eventflags = GPIOEVENT_REQUEST_BOTH_EDGES;
//     strncpy(req->consumer_label, consumer, sizeof(req->consumer_label) - 1);

//     int rv = ioctl(chip->fd, GPIO_GET_LINEEVENT_IOCTL, req);

//     if (rv < 0)
//         return enif_make_string(env, strerror(errno), ERL_NIF_LATIN1); // make better

//     ///////// SELECT //////

//     struct gpioevent_data *data = enif_alloc_resource(priv->gpioevent_data_rt, sizeof(struct gpioevent_data));
//     memset(data, 0, sizeof(struct gpioevent_data));
//     int select_rv = enif_select(env, req->fd, ERL_NIF_SELECT_READ, data, NULL, argv[4]);

//     if (select_rv < 0)
//         return enif_make_int(env, select_rv); // make better

//     ERL_NIF_TERM lineevent_resource = enif_make_resource(env, req);
//     enif_release_resource(req);

//     ERL_NIF_TERM ok_atom = enif_make_atom(env, "ok");

//     return enif_make_tuple2(env, ok_atom, lineevent_resource);
// }

// // clean up below code
// static ERL_NIF_TERM request_linehandle_multi_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
// {
//     struct cdev_priv *priv = enif_priv_data(env);
//     struct gpio_chip *chip;
//     char consumer[32];
//     int rv, flags, offset_list_len;

//     if (argc != 5)
//         return enif_make_badarg(env);

//     if (!enif_get_list_length(env, argv[1], &offset_list_len))
//         return enif_make_atom(env, "bad_offset_list");

//     if (!enif_get_int(env, argv[3], &flags))
//         return enif_make_atom(env, "bad_flags");

//     struct gpiohandle_request *req = enif_alloc_resource(priv->gpiohandle_request_rt, sizeof(struct gpiohandle_request));

//     memset(req, 0, sizeof(struct gpiohandle_request));

//     req->flags = flags;
//     req->lines = offset_list_len;
//     strncpy(req->consumer_label, consumer, sizeof(req->consumer_label) - 1);

//     if (offsets_for_req(env, req, argv[1]) < 0)
//         return enif_make_atom(env, "bad_offset_setting");

//     if (defaults_for_req(env, req, argv[2]) < 0)
//         return enif_make_atom(env, "bad_defaults_setting");

//     if (!enif_get_resource(env, argv[0], priv->gpio_chip_rt, (void **)&chip))
//         return enif_make_atom(env, "bad_chip");

//     rv = ioctl(chip->fd, GPIO_GET_LINEHANDLE_IOCTL, req);

//     if (rv < 0)
//     {
//         ERL_NIF_TERM rv_ioctl = enif_make_int(env, rv);
//         ERL_NIF_TERM error_atom = enif_make_atom(env, "error");

//         return enif_make_tuple2(env, error_atom, rv_ioctl);
//     }

//     ERL_NIF_TERM linehandle_resource = enif_make_resource(env, req);
//     enif_release_resource(req);

//     ERL_NIF_TERM ok_atom = enif_make_atom(env, "ok");

//     return enif_make_tuple2(env, ok_atom, linehandle_resource);
// }

// static ERL_NIF_TERM set_values_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
// {
//     struct cdev_priv *priv = enif_priv_data(env);
//     struct gpiohandle_request *req;
//     struct gpiohandle_data data;
//     int rv, values_list_length;
//     ERL_NIF_TERM head, tail;

//     ERL_NIF_TERM new_values = argv[1];

//     if (argc != 2 || !enif_get_resource(env, argv[0], priv->gpiohandle_request_rt, (void **)&req))
//         return enif_make_badarg(env);

//     if (!enif_get_list_length(env, new_values, &values_list_length))
//         return enif_make_atom(env, "list_error");

//     for (int i = 0; i < values_list_length; i++)
//     {
//         int new_value;

//         if (!enif_get_list_cell(env, new_values, &head, &tail))
//             return enif_make_atom(env, "list_cell_error");

//         if (!enif_get_int(env, head, &new_value))
//             return enif_make_atom(env, "new_value_error");

//         data.values[i] = new_value;

//         new_values = tail;
//     }

//     rv = ioctl(req->fd, GPIOHANDLE_SET_LINE_VALUES_IOCTL, &data);

//     if (rv < 0)
//         return enif_make_atom(env, "ioctl_error"); // make better

//     return enif_make_atom(env, "ok");
// }

// static ERL_NIF_TERM read_interrupt_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
// {
//     struct cdev_priv *priv = enif_priv_data(env);
//     if (argc != 3)
//         return enif_make_badarg(env);

//     struct gpioevent_request *req;

//     if (!enif_get_resource(env, argv[1], priv->gpioevent_request_rt, (void **)&req))
//         return enif_make_badarg(env);

//     struct gpioevent_data data;

//     read(req->fd, &data, sizeof(data));

//     ERL_NIF_TERM id = enif_make_int(env, data.id);
//     ERL_NIF_TERM timestamp = enif_make_int(env, data.timestamp);

//     ///////// SELECT //////

//     // struct gpioevent_data *new_data = enif_alloc_resource(priv->gpioevent_data_rt, sizeof(struct gpioevent_data));
//     int select_rv = enif_select(env, req->fd, ERL_NIF_SELECT_READ, (void *)argv[0], NULL, argv[2]);

//     if (select_rv < 0)
//         return enif_make_int(env, select_rv); // make better

//     return enif_make_tuple2(env, id, timestamp);
// }

// static ErlNifFunc nif_funcs[] = {
//     {"open", 1, open_chip},
//     {"close", 1, close_chip_nif},
//     {"get_info", 1, get_info_nif},
//     {"get_line_info", 2, get_line_info_nif},
//     {"request_linehandle", 5, request_linehandle_nif},
//     {"set_value", 2, set_value_nif},
//     {"get_value", 1, get_value_nif},
//     {"request_linehandle_multi", 5, request_linehandle_multi_nif},
//     {"request_lineevent", 5, request_lineevent_nif},
//     {"read_interrupt", 3, read_interrupt_nif},
//     {"set_values", 2, set_values_nif}
// };

// ERL_NIF_INIT(Elixir.Circuits.GPIO.Chip.Nif, nif_funcs, load, NULL, NULL, NULL)
