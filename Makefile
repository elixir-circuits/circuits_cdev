NIF = ./priv/cdev_nif.so

all:
	mkdir -p priv
	gcc -o $(NIF) -I$(ERL_EI_INCLUDE_DIR) -fpic -shared src/cdev_nif.c

clean:
	rm -r priv

