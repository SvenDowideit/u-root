KERNEL=4.14.14

build:
	u-root -format=cpio -build=source -o initramfs.cpio
	#u-root -format=cpio -build=bb -o initramfs.cpio

build-elvish:
	u-root \
		-format=cpio \
		-build=bb \
		-o initramfs.cpio \
		./cmds/* \
		github.com/elves/elvish

build-alpine:
	scripts/get-image alpine:latest
	cd root-fs && find . | cpio -H newc --create > ../alpine.cpio
	u-root \
		-base alpine.cpio \
		-format=cpio \
		-build=bb \
		-o initramfs.cpio

build-debian:
	rm -rf root-fs
	scripts/get-image debian:latest
	cd root-fs && find . | cpio -H newc --create > ../debian.cpio
	u-root \
		-base debian.cpio \
		-format=cpio \
		-build=bb \
		-o initramfs.cpio \
		./cmds/* \
		github.com/SvenDowideit/u-root/_examples/uinit

build-docker:
	# TODO: clear root-fs
	scripts/get-image alpine:latest
	scripts/get-image docker:latest
	scripts/get-image linuxkit/containerd:e58a382c33bb509ba3e0e8170dfaa5a100504c5b
	cd root-fs && find . | cpio -H newc --create > ../docker.cpio
	u-root \
		-base docker.cpio \
		-format=cpio \
		-build=bb \
		-o initramfs.cpio \
		./cmds/* \
		github.com/SvenDowideit/u-root/_examples/uinit

build-ctr:
	scripts/get-image linuxkit/runc:abc3f292653e64a2fd488e9675ace19a55ec7023
	scripts/get-image linuxkit/containerd:e58a382c33bb509ba3e0e8170dfaa5a100504c5b
	u-root \
		-format=cpio \
		-build=bb \
		-o initramfs.cpio \
		-files "root-fs/usr/bin/runc:usr/bin/runc root-fs/usr/bin/ctr:usr/bin/ctr root-fs/usr/bin/containerd:usr/bin/containerd root-fs/usr/bin/containerd-shim:usr/bin/containerd-shim root-fs/etc/containerd/config.toml:etc/containerd/config.toml" \
		./cmds/* \
		github.com/SvenDowideit/u-root/_examples/uinit
#		github.com/gliderlabs/ssh/_examples/ssh-simple

run:
	#-kernel /boot/vmlinuz-$(KERNEL)
	qemu-system-x86_64 \
		-m 4096M \
		-nographic -serial mon:stdio -display none -curses \
		-append "console=ttyS0 " \
		-net nic,vlan=0,model=virtio \
		-net user,vlan=0,hostfwd=tcp::2222-:2222,hostname=u-boot \
		-kernel kernel/kernel \
		-initrd initramfs.cpio

kill:
	killall qemu-system-x86_64

get-kernel:
	docker pull linuxkit/kernel:$(KERNEL)
	docker rm -f linux-$(KERNEL) | true
	docker create --name linux-$(KERNEL) linuxkit/kernel:$(KERNEL) ls
	rm -rf kernel
	mkdir -p kernel
	docker export linux-$(KERNEL) | tar -C kernel -xvf -
	docker rm -f linux-$(KERNEL) | true
