#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.1.10
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-

CURRENT_DIR=$(pwd)

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
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # TODO: Add your kernel build steps here
    make -j 8 ARCH=$ARCH CROSS_COMPILE=${CROSS_COMPILE} mrproper
    make -j 8 ARCH=$ARCH CROSS_COMPILE=${CROSS_COMPILE} defconfig
    make -j 8 ARCH=$ARCH CROSS_COMPILE=${CROSS_COMPILE} dtbs
    make -j 8 ARCH=$ARCH CROSS_COMPILE=${CROSS_COMPILE} modules
    make -j 8 ARCH=$ARCH CROSS_COMPILE=${CROSS_COMPILE} all
fi

echo "Adding the Image in outdir"
cp ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ${OUTDIR}/

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories

cd $OUTDIR
mkdir rootfs
cd rootfs
mkdir bin dev etc home lib proc sbin sys tmp usr var
mkdir usr/bin usr/lib usr/sbin
mkdir var/log


cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    git switch -c ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
else
    cd busybox
fi

# busy box 
make distclean
make defconfig
make arch=ARM CROSS_COMPILE=${CROSS_COMPILE} -j 4
make install

echo "Library dependencies"
${CROSS_COMPILE}readelf -a _install/bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a _install/bin/busybox | grep "Shared library"

# TODO: Add library dependencies to rootfs
export SYSROOT=$(${CROSS_COMPILE}gcc -print-sysroot)
cd ${OUTDIR}/rootfs
cp -a $SYSROOT/lib/ld-linux-aarch64.so.1 lib
cp -a $SYSROOT/lib64/libm.so.6 lib
cp -a $SYSROOT/lib64/libm-2.31.so lib
cp -a $SYSROOT/lib64/libresolv.so.2 lib
cp -a $SYSROOT/lib64/libresolv-2.31.so lib
cp -a $SYSROOT/lib64/libc.so.6 lib
cp -a $SYSROOT/lib64/libc-2.31.so lib


cd $CURRENT_DIR
make clean
make arm

cp finder.sh $OUTDIR/rootfs/home
cp writer $OUTDIR/rootfs/home
cp writer.sh $OUTDIR/rootfs/home

# TODO: Make device nodes
cd ${OUTDIR}/rootfs
sudo mknod -m 666 dev/null c 1 3
sudo mknod -m 600 dev/console c 5 1


# TODO: Chown the root directory
sudo chown -R root:root ${OUTDIR}/rootfs/*

# TODO: Create initramfs.cpio.gz
cd ${OUTDIR}/rootfs
find . | cpio -H newc -ov --owner root:root > ../initramfs.cpio
cd ..
gzip initramfs.cpio
