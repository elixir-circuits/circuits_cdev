NIF = ./priv/cdev_nif.so

all:
	mkdir -p priv
	gcc -o $(NIF) -I$(ERL_INCLUDE_PATH) -fpic -shared src/cdev_nif.c

clean:
	rm -r priv
