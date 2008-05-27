/^MODULE_DESCRIPTION\("Virtio network driver"\);/ {
    print "#ifdef COMPAT_modaliases"
    print "MODULE_ALIAS(\"virtio:d00000001v*\");"
    print "#endif"
}

/^MODULE_DESCRIPTION\("Virtio block driver"\);/ {
    print "#ifdef COMPAT_modaliases"
    print "MODULE_ALIAS(\"virtio:d00000002v*\");"
    print "#endif"
}

/^static int virtio_uevent\(/ {
    virtio_uevent = 1;
    print "#ifdef COMPAT_kobject_uevent_env";
    print "static int virtio_uevent(struct device *_dv, char **envp, int num_envp,";
    print "                         char *buffer, int buffer_size)";
    print "{";
    print "	struct virtio_device *dev = container_of(_dv,struct virtio_device,dev);";
    print "	int cur_index = 0, cur_len = 0;";
    print "";
    print "	return add_uevent_var(envp, num_envp, &cur_index, buffer, buffer_size,";
    print "			      &cur_len, \"MODALIAS=virtio:d%08Xv%08X\",";
    print "			      dev->id.device, dev->id.vendor);";
    print "}";
    print "#else"
}

/^static int virtnet_poll\(/ {
    print "#ifdef COMPAT_napi";
    print "static int virtnet_poll(struct net_device *dev, int *budget)";
    print "{";
    print "	struct virtnet_info *vi = netdev_priv(dev);";
    print "	int max_received = min(dev->quota, *budget);";
    print "	bool no_work;";
    print "	struct sk_buff *skb = NULL;";
    print "	unsigned int len, received = 0;";
    print "";
    print "again:";
    print "	while (received < max_received &&";
    print "	       (skb = vi->rvq->vq_ops->get_buf(vi->rvq, &len)) != NULL) {";
    print "		__skb_unlink(skb, &vi->recv);";
    print "		receive_skb(vi->dev, skb, len);";
    print "		vi->num--;";
    print "		received++;";
    print "	}";
    print "";
    print "	/* FIXME: If we oom and completely run out of inbufs, we need";
    print "	 * to start a timer trying to fill more. */";
    print "	if (vi->num < vi->max / 2)";
    print "		try_fill_recv(vi);";
    print "";
    print "	/* Out of packets? */";
    print "	if (skb) {";
    print "		*budget -= received;";
    print "		dev->quota -= received;";
    print "		return 1;";
    print "	}";
    print "";
    print "	netif_rx_complete(vi->dev);";
    print "	no_work = vi->rvq->vq_ops->enable_cb(vi->rvq);";
    print "";
    print "	if (!no_work && netif_rx_schedule_prep(vi->dev)) {";
    print "		vi->rvq->vq_ops->disable_cb(vi->rvq);";
    print "		__netif_rx_schedule(vi->dev);";
    print "		goto again;";
    print "	}";
    print "";
    print "	dev->quota -= received;";
    print "	*budget -= received;";
    print "";
    print "	return 0;";
    print "}";
    print "#else";
    virtnet_poll = 1
}

/\tnetif_rx_schedule\(/ {
    print "#ifdef COMPAT_napi";
    print "	vi->rvq->vq_ops->enable_cb(vi->rvq);";
    print "	if (netif_rx_schedule_prep(vi->dev)) {";
    print "		vi->rvq->vq_ops->disable_cb(vi->rvq);";
    print "		__netif_rx_schedule(vi->dev);";
    print "	} else";
    print "		vi->rvq->vq_ops->enable_cb(vi->rvq);";
    print "#else";
    need_endif = 1
}

/netif_rx_schedule_prep/ {
    print "#ifdef COMPAT_napi";
    print "\tif (netif_rx_schedule_prep(vi->dev)) {";
    print "#else";
    need_endif = 1
}

/__netif_rx_schedule/ {
    print "#ifdef COMPAT_napi";
    print "\t\t__netif_rx_schedule(vi->dev);";
    print "#else";
    need_endif = 1
}

/dev->stats/ {
    print "#ifndef COMPAT_net_stats";
    need_endif = 1
}

/^static enum hrtimer_restart kick_xmit\(/ {
    print "#ifdef COMPAT_hrtimer_func";
    print "static int kick_xmit(struct hrtimer *t)";
    print "#else";
    need_endif = 1
}

/flags \& VIRTIO_NET_HDR_F_NEEDS_CSUM\)/ {
    print "#ifdef COMPAT_csum_offset";
    print "\tif (hdr->flags & VIRTIO_NET_HDR_F_NEEDS_CSUM) {";
    print "\t\tskb->ip_summed = CHECKSUM_UNNECESSARY;";
    print "\t}";
    print "#else"
    need_endif_indent_brace = 1
}

/ip_summed == CHECKSUM_PARTIAL\)/ {
    print "#ifdef COMPAT_csum_offset";
    print "\tif (skb->ip_summed == CHECKSUM_HW) {"
    print "#else"
    need_endif = 1;
}

/hdr->csum_start = skb->csum_start/ {
    print "#ifdef COMPAT_csum_offset";
    print "\t\thdr->csum_start = skb->h.raw - skb->data;";
    print "\t\thdr->csum_offset = skb->csum;";
    print "#else"
    need_endif = 1;
}

/skb_transport_header/ {
    print "#ifdef COMPAT_transport_header";
    print "\t\thdr->hdr_len = skb->h.raw - skb->data;";
    print "#else";
    need_endif = 1;
}

{ sub(/\<pci_dev->revision\>/, "pci_dev_revision(pci_dev)") }

{ print }

/^	\}$/ && need_endif_indent_brace {
    print "#endif";
    need_endif_indent_brace = 0
}

need_endif {
    print "#endif";
    need_endif = 0
}

/\}/ && virtio_uevent {
    print "#endif";
    virtio_uevent = 0
}

/^\}$/ && virtnet_poll {
    print "#endif";
    virtnet_poll = 0
}
