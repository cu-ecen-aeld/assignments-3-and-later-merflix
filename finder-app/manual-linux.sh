#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/luki
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.1.10
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-

ORIGINAL_DIR=$(pwd)

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
	# cp "$ORIGINAL_DIR/finder_app/dtc-multiple-definition.patch" "${OUTDIR}/linux-stable"
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # TODO: Add your kernel build steps here
    # cp "$ORIGINAL_DIR/dtc-multiple-definition.patch" "${OUTDIR}/linux-stable"
    # git apply dtc-multiple-definition.patch
    cp "$ORIGINAL_DIR/dtc-lexer.l" "${OUTDIR}/linux-stable/scripts/dtc/"
    export PATH=$PATH:/home/lukas/assignment1/install-lnx/gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu/bin
    echo "start mrproper"
    make ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- mrproper
    echo "create defconfig"
    make ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- defconfig
    echo "start scripts"
    make -j4 ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- scripts
    echo "start building"
    make -j4 ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- all
    echo "compile modules"
    make ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- modules
    echo "create device tree"
    make ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- dtbs
    cp "${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image" ${OUTDIR}
fi

echo "Adding the Image in outdir"

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories
mkdir -p my_root
mkdir -p my_root/bin my_root/dev my_root/etc my_root/home my_root/lib my_root/lib64 my_root/proc my_root/sbin my_root/sys my_root/tmp my_root/usr my_root/var my_root/conf
mkdir -p my_root/usr/bin my_root/usr/lib my_root/usr/sbin
mkdir -p my_root/var/log

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
    echo "********************* configure busybox *****************************"
    make distclean
    make defconfig
else
    cd busybox
fi

# TODO: Make and install busybox
echo "start compiling busybox"
echo "ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}"
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make CONFIG_PREFIX="${OUTDIR}/my_root" ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install
echo "finished compiling busybox"

where=$(pwd)
echo "Library dependencies, pwd=${where}"
${CROSS_COMPILE}readelf -a busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a busybox | grep "Shared library"

# TODO: Add library dependencies to rootfs
toolchain_bin=$(which "${CROSS_COMPILE}gcc")
toolchain_inst=$(dirname "$toolchain_bin")
toolchain_inst="${toolchain_inst%/}"
toolchain_inst=$(dirname "$toolchain_inst")
echo "toolchain_installation path is: $toolchain_inst"
cd ../my_root
cp "${toolchain_inst}/aarch64-none-linux-gnu/libc/lib/ld-linux-aarch64.so.1" "lib"
cp "${toolchain_inst}/aarch64-none-linux-gnu/libc/lib64/libm.so.6" "lib64"
cp "${toolchain_inst}/aarch64-none-linux-gnu/libc/lib64/libresolv.so.2" "lib64"
cp "${toolchain_inst}/aarch64-none-linux-gnu/libc/lib64/libc.so.6" "lib64"

# TODO: Make device nodes
echo "create device nodes"
if ! sudo rm -f dev/null; then
	echo "removed old dev/null file"
fi
if ! sudo rm -f dev/console; then
	echo "removed old dev/console file"
fi
sudo mknod -m 666 dev/null c 1 3
sudo mknod -m 600 dev/console c 5 1
echo "device nodes created"

# TODO: Clean and build the writer utility
cd ${ORIGINAL_DIR}
make clean
make all

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
echo "copying files"
cp "finder.sh" "${OUTDIR}/my_root/home"
cp "finder-test.sh" "${OUTDIR}/my_root/home"
cp "writer" "${OUTDIR}/my_root/home"
cp "writer.sh" "${OUTDIR}/my_root/home"
cp "autorun-qemu.sh" "${OUTDIR}/my_root/home"
mkdir -p "${OUTDIR}/my_root/home/conf"
cp "username.txt" "${OUTDIR}/my_root/home/conf"
cp "assignment.txt" "${OUTDIR}/my_root/conf"

# TODO: Chown the root directory
sudo chmod -R +rwx ${OUTDIR}/my_root

# TODO: Create initramfs.cpio.gz
cd "$OUTDIR/my_root"
find . | cpio -H newc -ov --owner root:root > ${OUTDIR}/initramfs.cpio
cd ${OUTDIR}
gzip -f initramfs.cpio

