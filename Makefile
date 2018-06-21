.PHONY: xen-ocaml-build xen-posix-build
.DEFAULT: xen-posix-install xen-ocaml-install

xen-ocaml-build:
	cd xen-ocaml && $(MAKE) build

xen-ocaml-install:
	cd xen-ocaml && $(MAKE) install

xen-ocaml-uninstall:
	cd xen-ocaml && $(MAKE) uninstall

xen-posix-build:
	cd xen-posix && $(MAKE) build

xen-posix-install:
	cd xen-posix && $(MAKE) install

xen-posix-uninstall:
	cd xen-posix && $(MAKE) uninstall

clean:
	cd xen-posix && $(MAKE) clean
	cd xen-ocaml && $(MAKE) clean

