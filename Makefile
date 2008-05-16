KERNELDIR = /lib/modules/$(shell uname -r)/build
KVERREL = $(patsubst /lib/modules/%/build,%,$(KERNELDIR))

DESTDIR=

INSTALLDIR = $(patsubst %/build,%/extra,$(KERNELDIR))
ORIGMODDIR = $(patsubst %/build,%/kernel,$(KERNELDIR))

LINUX = ../linux-2.6

KVER = $(shell uname -r)
KERNELDIR = /lib/modules/$(KVER)/build
LINUX = ../linux-2.6

hack = mv $1 $1.orig && \
	awk -f hack-module.awk $1.orig > $1 && rm $1.orig

all::
	$(MAKE) -C $(KERNELDIR) M=`pwd` "$$@"

sync:
	mkdir -p include/linux
	cp -a "$(LINUX)"/drivers/virtio/*.[ch] .
	cp -a "$(LINUX)"/include/linux/virtio*.h include/linux/
	cp -a "$(LINUX)"/drivers/block/virtio_blk.c .
	cp -a "$(LINUX)"/drivers/net/virtio_net.c .
	$(call hack, virtio.c)
	$(call hack, virtio_pci.c)
	$(call hack, virtio_net.c)
	$(call hack, virtio_blk.c)

install:
	mkdir -p $(DESTDIR)/$(INSTALLDIR)
	cp *.ko $(DESTDIR)/$(INSTALLDIR)
	for i in $(ORIGMODDIR)/drivers/virtio/*.ko \
                 $(ORIGMODDIR)/drivers/net/virtio_net.ko \
                 $(ORIGMODDIR)/drivers/block/virtio_blk.ko; do \
		if [ -f "$$i" ]; then mv "$$i" "$$i.orig"; fi; \
	done
	/sbin/depmod -a

clean:
	$(MAKE) -C $(KERNELDIR) M=`pwd` $@
	rm -f Module.symvers

realclean: clean
	$(RM) -r *.c include/ *~

