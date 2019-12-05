NIF = ./priv/cdev_nif.so

all:
	mkdir -p priv
	gcc -o $(NIF) -I/usr/lib/erlang/erts-10.4/include -fpic -shared src/cdev_nif.c

clean:
	rm -r priv
