#this prepares the android build environment
FROM l3iggs/libretro-arch-base:latest
MAINTAINER l3iggs <l3iggs@live.com>

# Android setup section
RUN pacman -Suy --noconfirm apache-ant
RUN mkdir /root/android-tools

# Android SDK
ADD https://dl.google.com/android/android-sdk_r23.0.2-linux.tgz /root/android-tools/android-sdk.tgz
RUN tar -xvf /root/android-tools/android-sdk.tgz -C /root/android-tools/
RUN rm -rf /root/android-tools/android-sdk.tgz
ENV PATH $PATH:/root/android-tools/android-sdk-linux/tools

# Android NDK
ADD https://dl.google.com/android/ndk/android-ndk32-r10-linux-x86_64.tar.bz2 /root/android-tools/android-ndk.tar.bz2
RUN tar -xvf /root/android-tools/android-ndk.tar.bz2 -C /root/android-tools/
RUN rm -rf /root/android-tools/android-ndk.tar.bz2
RUN mv /root/android-tools/android-ndk-* /root/android-tools/android-ndk
ENV PATH $PATH:/root/android-tools/android-ndk

# for optional signing of release  apk
RUN keytool -genkey -keystore /root/android-tools/my-release-key.keystore -alias alias_name -keyalg RSA -keysize 2048 -validity 10000 -storepass libretro -keypass libretro -dname "cn=localhost, ou=IT, o=libretro, c=US"

# update/install android sdk components
RUN pacman -Suy --noconfirm expect
ADD https://raw.githubusercontent.com/l3iggs/libretro-buildbot/android-setup/android-sdk-installer.py /root/android-tools/android-sdk-installer.py
RUN python2 /root/android-tools/android-sdk-installer.py

# for working in the image
RUN pacman -Suy --noconfirm vim

# for packaging outputs
RUN pacman -Suy --noconfirm p7zip

# enable ccache for NDK builds
ENV NDK_CCACHE ccache
