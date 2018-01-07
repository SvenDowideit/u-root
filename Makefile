KERNEL=$(shell uname -r)

build:
	#u-root -format=cpio -build=source -o initramfs.cpio
	u-root -format=cpio -build=bb -o initramfs.cpio

run:
	#-kernel /boot/vmlinuz-$(KERNEL)
	qemu-system-x86_64 \
		-nographic -serial mon:stdio -display none -curses \
		-append "console=ttyS0 " \
		-net nic,vlan=0,model=virtio \
		-net user,vlan=0,hostfwd=tcp::2222-:22,hostname=u-boot \
		-kernel kernel/kernel \
		-initrd initramfs.cpio

kill:
	killall qemu-system-x86_64
