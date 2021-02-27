/*
 * Erlang Nif and GPIO character device driver functions
 */
#ifndef GPIO_CHIP_H
#define GPIO_CHIP_H

#include <linux/gpio.h>
#include "erl_nif.h"

#define GPIO_CHIP_LINE_INPUT 0x00
#define GPIO_CHIP_LINE_OUTPUT 0x01

#define GPIO_CHIP_ACTIVE_HIGH 0x00
#define GPIO_CHIP_ACTIVE_LOW 0x01

/*
 * Struct to encapsulate details about a GPIO chip
 */
struct gpio_chip {
    unsigned int num_lines;
    int fd;
    char name[32];
    char label[32];

    int has_info;
};

/*
 * Struct for a line handle
 */
struct gpio_chip_line_handle {
    int num_lines;
    int handle_fd;
};

/*
 * Struct for a line event handle
 */
struct gpio_chip_event_handle {
    int fd;
};

/*
 * Struct for event data
 */
struct gpio_chip_event_data {
    int timestamp;
    int id;
};

/*
 * Struct for line information
 */
struct gpio_chip_line_info {
    int direction;
    int active_low;

    char name[32];
    char consumer[32];
};

/*
 * Close the GPIO chip
 */
void chip_close(struct gpio_chip *chip);

/*
 * Close the event handle 
 */
void chip_event_handle_close(struct gpio_chip_event_handle *handle);

/*
 * Get the chip info
 */
int chip_get_info(struct gpio_chip *chip);

/*
 * Get information about a line
 */
int chip_get_line_info(struct gpio_chip *chip, int offset, struct gpio_chip_line_info *line_info);

/*
 * Close a line handle
 */
void chip_line_handle_close(struct gpio_chip_line_handle *handle);

/*
 * Open the chip
 */
int chip_open(struct gpio_chip *chip, const char *path);

/*
 * Read event data into the data struct from the event handle
 */
int chip_read_event_data(struct gpio_chip_event_handle *handle, struct gpio_chip_event_data *data);

/*
 * Read the values from a line handle
 */
int chip_read_values(struct gpio_chip_line_handle *handle, int *buff);

/*
 * Request an event handle
 */
int chip_request_event(struct gpio_chip *chip, int offset, struct gpio_chip_event_handle *handle);

/*
 * Request a line handle
 */
int chip_request_lines(struct gpio_chip *chip, int offsets[], int direction, struct gpio_chip_line_handle *handle);

/*
 * Set the values of the GPIO lines
 */
int chip_set_values(struct gpio_chip_line_handle *handle, int values[]);

#endif