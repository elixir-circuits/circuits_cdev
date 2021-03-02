# circuits_cdev

Character device GPIO library for Elixir.

WARNING: This is under active development and not all features or bugs are worked
out yet, if you want to use GPIOs in Elixir please see [circuits_gpio](https://github.com/elixir-circuits/circuits_gpio).

Since Linux 4.8 the `sysfs` interface is deprecated in preference of the
character device GPIO API.

The advantages of the character device API over the `sysfs` interface are:

* The allocation of the GPIO is tied to the process that is using it, which
  prevents many process from trying to control a GPIO at once.
* Since the GPIO is tied to the process, if the process ends for any reason the
  GPIO will be cleaned up automatically.
* It is possible to read or write many GPIOs at once.
* It is possible to configure the state of the GPIO (open-source, open-drain, etc).
* The polling process to catch event is reliable.

The way to drive a GPIO line (a pin) is by requesting a line handle from a GPIO
chip. A system may have many GPIO chips and these can be named or they default
to using the name `gpiochipN` where `N` is the chip number starting a `0`.

For example the main GPIO chip on the Raspberry PI systems is `gpiochip0`
located at `"/dev/gpiochip0"`.

## Install

```elixir
def deps do
  [{:circuits_cdev, "~> 0.1.0"}]
end
```

## Controlling the output of a line

First request a line handle from the GPIO chip:

```elixir
{:ok, line_handle} = Circuits.GPIO.Chip.request_line("gpiochip0", 17, :output)
```

After getting a line handle can now set the value of the line:

```elixir
Circuits.GPIO.Chip.read_value(line_handle)
0
```

To set the value of the line:

```elixir
Circuits.GPIO.Chip.set_value(line_handle, 1)
:ok
```

## Controlling the output of many lines

First request a line handle from the GPIO chip:

```elixir
{:ok, line_handle} = Circuits.GPIO.Chip.request_line("gpiochip0", [17, 27 20], :output)
```

After getting the line handle you can set the values of the lines. Notice that
you to provide all the values in the same order as you requested the lines:

```elixir
Circuits.GPIO.Chip.set_values(line_handle, [0, 1, 1])
```

When reading the values of a line handle that controls more than one line you
will receive a list of values in the order of that you requested the lines:

```elixir
Circuits.GPIO.Chip.read_values(line_handle)
{:ok, [0, 1, 1]}
```

## Listen for events on a line

You can listen for events on an GPIO line by calling the `listen_event/2` function:

```elixir
Circuits.GPIO.Chip.listen_event("gpiochip0", 27)
:ok
```

When an event is received from the line it will be in the form of:

```
{:circuits_cdev, pin_number, timestamp, new_value}
```


