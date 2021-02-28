#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <string.h>
#include <linux/gpio.h>

#include "gpio_chip.h"

void chip_close(struct gpio_chip *chip)
{
    close(chip->fd);
}

void chip_event_handle_close(struct gpio_chip_event_handle *handle)
{
    close(handle->fd);
}

int chip_open(struct gpio_chip *chip, const char *path)
{
    int fd = open(path, O_RDWR);

    if (fd < 0)
        return fd;

    chip->fd = fd;

    return 0;
}

int chip_get_info(struct gpio_chip *chip) {
    if (chip->has_info == 1)
        return 0;

    struct gpiochip_info info;

    memset(&info, 0, sizeof(info));

    int rv = ioctl(chip->fd, GPIO_GET_CHIPINFO_IOCTL, &info);

    if (rv < 0)
        return rv;

    chip->num_lines = info.lines;

    strncpy(chip->name, info.name, sizeof(chip->name));

    if (info.label[0] == '\0')
        strncpy(chip->label, "unknown", sizeof(chip->label));
    else
        strncpy(chip->label, info.label, sizeof(chip->label));

    chip->has_info = 1;

    return 0;
}


void chip_line_handle_close(struct gpio_chip_line_handle *handle) {
    close(handle->handle_fd);
}

int chip_get_line_info(struct gpio_chip *chip, int offset, struct gpio_chip_line_info *line_info)
{
    struct gpioline_info info;

    memset(&info, 0, sizeof(info));

    info.line_offset = offset;

    int rv = ioctl(chip->fd, GPIO_GET_LINEINFO_IOCTL, &info);

    if (rv < 0)
        return -1;

    line_info->direction = info.flags & GPIOLINE_FLAG_IS_OUT
                                ? GPIO_CHIP_LINE_OUTPUT
                                : GPIO_CHIP_LINE_INPUT;

    line_info->active_low = info.flags & GPIOLINE_FLAG_ACTIVE_LOW
                                 ? GPIO_CHIP_ACTIVE_LOW
                                 : GPIO_CHIP_ACTIVE_HIGH;

    strncpy(line_info->name, info.name, sizeof(line_info->name));
    strncpy(line_info->consumer, info.consumer, sizeof(line_info->consumer));

    return 0;
}

int chip_read_event_data(struct gpio_chip_event_handle *handle, struct gpio_chip_event_data *data)
{
    struct gpioevent_data event_data;

    int bytes_read = read(handle->fd, &event_data, sizeof(event_data));

    if (bytes_read == -1)
        return -1;

    data->timestamp = event_data.timestamp;
    data->id = (int)event_data.id;

    return 0;
}

int chip_read_values(struct gpio_chip_line_handle *handle, int *buff)
{
    struct gpiohandle_data data;

    memset(&data, 0, sizeof(data));

    int rv = ioctl(handle->handle_fd, GPIOHANDLE_GET_LINE_VALUES_IOCTL, &data);

    if (rv < 0)
        return -1;

    for (int i = 0; i < handle->num_lines; i++) {
        buff[i] = (int)data.values[i];
    }

    return 0;
}

int chip_request_event(struct gpio_chip *chip, int offset, struct gpio_chip_event_handle *handle)
{
    struct gpioevent_request req;

    memset(&req, 0, sizeof(req));

    req.lineoffset = offset;
    req.handleflags = GPIOHANDLE_REQUEST_INPUT;
    req.eventflags = GPIOEVENT_REQUEST_BOTH_EDGES;

    strncpy(req.consumer_label, "circuits_cdev", sizeof(req.consumer_label - 1));

    int rv = ioctl(chip->fd, GPIO_GET_LINEEVENT_IOCTL, &req);

    if (rv < 0)
        return -1;

    handle->fd = req.fd;

    return 0;
}

int chip_request_lines(struct gpio_chip *chip, int offsets[], int direction, struct gpio_chip_line_handle *handle)
{
    if (handle->num_lines == 0)
        return 0;

    if (handle->num_lines >= GPIOHANDLES_MAX)
        return -2;

    int gpio_direction = -1;

    if (direction == 0) {
        gpio_direction = GPIOHANDLE_REQUEST_INPUT;
    } else if (direction == 1) {
        gpio_direction = GPIOHANDLE_REQUEST_OUTPUT;
    } else {
        return -1;
    }

    struct gpiohandle_request req;

    memset(&req, 0, sizeof(req));

    req.flags |= gpio_direction;
    req.lines = handle->num_lines;

    for (int i = 0; i < handle->num_lines; i++) {
        req.lineoffsets[i] = offsets[i];
    }

    for (int i = 0; i < handle->num_lines; i++) {
        req.default_values[i] = 0;
    }

    strcpy(req.consumer_label, "circuits_gpio_chip");

    int rv = ioctl(chip->fd, GPIO_GET_LINEHANDLE_IOCTL, &req);

    if (rv > 0)
        return -3;

    handle->handle_fd = req.fd;

    return 0;
}

int chip_set_values(struct gpio_chip_line_handle *handle, int values[])
{
    struct gpiohandle_data data;

    for (int i = 0; i < handle->num_lines; i++) {
        data.values[i] = values[i];
    }

    int rv = ioctl(handle->handle_fd, GPIOHANDLE_SET_LINE_VALUES_IOCTL, &data);

    if (rv < 0)
        return -1;

    return 0;
}

