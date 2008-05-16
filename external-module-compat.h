#ifndef _LINUX_EXTMOD_COMPAT_H
#define _LINUX_EXTMOD_COMPAT_H

#include <linux/compiler.h>
#include <linux/version.h>
#include <linux/types.h>
#include <linux/scatterlist.h>
#include <linux/blkdev.h>
#include <linux/netdevice.h>
#include <linux/etherdevice.h>

#ifndef CONFIG_HIGH_RES_TIMERS
#define COMPAT_cb_softirq
#endif

#define COMPAT_csum_offset

#if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,24)

struct virtio_device_id {
	__u32 device;
	__u32 vendor;
};

#define VIRTIO_DEV_ANY_ID	0xffffffff

#define COMPAT_kobject_uevent_env

#define sg_page(sg)	((sg)->page)

static inline void sg_init_table(struct scatterlist *sgl, unsigned int nents)
{
	memset(sgl, 0, sizeof(*sgl) * nents);
}

static inline void end_dequeued_request(struct request *rq, int uptodate)
{
	if (!end_that_request_first(rq, uptodate, rq->hard_nr_sectors)) {
		add_disk_randomness(rq->rq_disk);
		end_that_request_last(rq, uptodate);
	}
}

#define DECLARE_MAC_BUF(var) char var[18] __maybe_unused

#define MAC_FMT "%02x:%02x:%02x:%02x:%02x:%02x"

static inline char *print_mac(char *buf, const u8 *addr)
{
	sprintf(buf, MAC_FMT,
		addr[0], addr[1], addr[2], addr[3], addr[4], addr[5]);
	return buf;
}

#define COMPAT_napi

struct napi_struct {
	int dummy;
};

#define napi_enable(napi) netif_poll_enable(dev)
#define napi_disable(napi) netif_poll_disable(dev)
#define napi_schedule(napi) netif_rx_schedule(dev, NULL)
#define netif_napi_add(dev, napi, pollfn, weightval)	\
do {							\
	(dev)->poll = (pollfn);				\
	(dev)->weight = 16;				\
} while(0)
#define netif_rx_schedule(dev, napi) netif_rx_schedule(dev)

#if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,23)

#define scsi_cmd_ioctl(filp, rq, gendisk, cmd, data) \
        scsi_cmd_ioctl(filp, gendisk, cmd, data)

#define task_pid_nr(current) (0)

#define __mandatory_lock(ino) (0)

#if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,22)

#define COMPAT_INIT_WORK
#define COMPAT_f_dentry
#define COMPAT_net_stats
#define COMPAT_transport_header

#define __maybe_unused

#define uninitialized_var(x) x = x

#define list_first_entry(ptr, type, member) \
	list_entry((ptr)->next, type, member)

static inline void * __must_check krealloc(const void *data, size_t size,
					   gfp_t gfp)
{
	void *ret;

	ret = kmalloc(size, gfp);
	if (ret == NULL)
		return ret;
	memcpy(ret, data, min(size, (size_t)ksize(data)));
	kfree((void *)data);

	return ret;
}

extern int skb_to_sgvec(struct sk_buff *skb, struct scatterlist *sg, int offset, int len);

#if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,21)

#define HRTIMER_MODE_REL HRTIMER_REL

#define hrtimer_is_queued(timer) hrtimer_active(timer)

#define COMPAT_hrtimer_func

#if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,19)

typedef _Bool bool;

#define true (1)
#define false (0)

#define vp_interrupt(irq, opaque) \
	vp_interrupt(irq, opaque, struct pt_regs *regs)

#endif
#endif
#endif
#endif
#endif

#include "include/linux/virtio.h"
#include "include/linux/virtio_ring.h"
#include "include/linux/virtio_config.h"
#include "include/linux/virtio_pci.h"
#include "include/linux/virtio_net.h"
#include "include/linux/virtio_blk.h"

#include <linux/pci_regs.h>
#include <linux/pci.h>

static inline u8 pci_dev_revision(struct pci_dev *dev)
{
	u32 class;

	pci_read_config_dword(dev, PCI_CLASS_REVISION, &class);
	return class & 0xff;
}

#if LINUX_VERSION_CODE <= KERNEL_VERSION(2,6,23)

static inline unsigned long sg_phys(struct scatterlist *sg)
{
	return page_to_phys(sg_page(sg)) + sg->offset;
}

#endif

#endif
