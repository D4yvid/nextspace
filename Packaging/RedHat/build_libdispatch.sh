#!/bin/sh
# -*-Shell-script-*-

BUILD_RPM=1
. `dirname $0`/../functions.sh
. `dirname $0`/../environment.sh

SPEC_FILE=${PROJECT_DIR}/Packaging/RedHat/SPECS/libdispatch.spec
DISPATCH_VERSION=`rpm_version ${SPEC_FILE}`

# libdispatch
print_H1 " Building Grand Central Dispatch (libdispatch) package..."
print_H2 "===== Install libdispatch build dependencies..."
DEPS=`rpmspec -q --buildrequires ${SPEC_FILE} | awk -c '{print $1}'`
sudo yum -y install ${DEPS}

print_H2 "===== Preparing local libdispatch sources..."
VER=`rpmspec -q --qf "%{version}:" ${SPEC_FILE} | awk -F: '{print $1}'`
LOCAL_SRC_DIR=${PROJECT_DIR}/Libraries/libdispatch
PKG_NAME=swift-corelibs-libdispatch-swift-${VER}-RELEASE
if [ ! -f ${LOCAL_SRC_DIR}/CMakeLists.txt ]; then
	print_ERR "Missing local libdispatch sources in ${LOCAL_SRC_DIR}"
	exit 1
fi
TMP_DIR=`mktemp -d`
mkdir -p ${TMP_DIR}/${PKG_NAME}
cp -a ${LOCAL_SRC_DIR}/. ${TMP_DIR}/${PKG_NAME}/
tar zcf ${RPM_SOURCES_DIR}/libdispatch-${VER}.tar.gz -C ${TMP_DIR} ${PKG_NAME}
rm -rf ${TMP_DIR}

print_H2 "===== Building libdispatch package..."
rpmbuild -bb ${SPEC_FILE}
STATUS=$?
if [ $STATUS -eq 0 ]; then 
    print_OK " Building of Grand Central Dispatch library RPM SUCCEEDED!"
    print_H2 "===== Installing libdispatch RPMs..."

    install_rpm libdispatch-${DISPATCH_VERSION} ${RPMS_DIR}/libdispatch-${DISPATCH_VERSION}.rpm
    mv ${RPMS_DIR}/libdispatch-${DISPATCH_VERSION}.rpm ${RELEASE_USR}

    install_rpm libdispatch-devel-${DISPATCH_VERSION} ${RPMS_DIR}/libdispatch-devel-${DISPATCH_VERSION}.rpm
    mv ${RPMS_DIR}/libdispatch-devel-${DISPATCH_VERSION}.rpm ${RELEASE_DEV}
    mv ${RPMS_DIR}/libdispatch-debuginfo-${DISPATCH_VERSION}.rpm ${RELEASE_DEV}
    if [ -f ${RPMS_DIR}/libdispatch-debugsource-${DISPATCH_VERSION}.rpm ];then
        mv ${RPMS_DIR}/libdispatch-debugsource-${DISPATCH_VERSION}.rpm ${RELEASE_DEV}
    fi
else
    print_ERR " Building of Grand Central Dispatch library RPM FAILED!"
    exit $STATUS
fi
