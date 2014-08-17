#!/bin/bash -e
# this script lives in each of the Docker build images and initiates and
# manages fetching new code and doing the actual compilation and moving the generated binaries to /staging 

# grabs the latest code for all of libretro
update_code()
{
  echo Updating code...
  cd /root/
  repo sync
  repo forall -c git submodule update --init
}

# builds the front end
linux_retroarch()
{
  ARCH="x86_64" 
  echo Building RetroArch ...
  # build frontend
  cd /root/libretro-super
  ./retroarch-build.sh
  
  rm -rf /staging/linux/${ARCH}/RetroArch/*
  mkdir -p /staging/linux/${ARCH}/RetroArch/files
  cd /root/libretro-super/retroarch/
  make DESTDIR=/staging/linux/${ARCH}/RetroArch/files install
  
  7za a -r /staging/linux/${ARCH}/RetroArch.7z /staging/linux/${ARCH}/RetroArch/files/*
}

# builds all the cores
linux_cores()
{
  ARCH="x86_64"
  echo Building cores...
  # build cores
  rm -rf /root/libretro-super/dist/unix*
  cd /root/libretro-super
  ./libretro-build.sh
  
  rm -rf /staging/linux/${ARCH}/cores/
  mkdir -p /staging/linux/${ARCH}/cores
  cd /root/libretro-super
  ./libretro-install.sh /staging/linux/${ARCH}/cores
  
  
  7za a -r /staging/linux/${ARCH}/cores.7z /staging/linux/${ARCH}/cores/*
}

# builds the android frontend and cores and packages into an apk
android_all()
{
  ARCH="armeabi-v7a"
  echo Building for Android ...
  # build cores
  rm -rf /root/libretro-super/dist/android/${ARCH}/*
  cd /root/libretro-super/
  ./libretro-build-android-mk.sh
  
  # build frontend
  cd /root/libretro-super/retroarch/android/phoenix
  android update project --path .
  echo "ndk.dir=/root/android-tools/android-ndk" >> local.properties
  android update project --path libs/googleplay/
  android update project --path libs/appcompat/
  
  # setup paths
  rm -rf /root/libretro-super/retroarch/android/phoenix/assets
  mkdir -p /root/libretro-super/retroarch/android/phoenix/assets/
  
  # copy cores and other assets
  cp -r /root/libretro-super/dist/android/${ARCH} /root/libretro-super/retroarch/android/phoenix/assets/cores
  cp -r /root/libretro-super/dist/info /root/libretro-super/retroarch/android/phoenix/assets/
  cp -r /root/libretro-super/retroarch/media/shaders /root/libretro-super/retroarch/android/phoenix/assets/shaders_glsl
  cp -r /root/libretro-super/retroarch/media/overlays /root/libretro-super/retroarch/android/phoenix/assets/
  cp -r /root/libretro-super/retroarch/media/autoconfig /root/libretro-super/retroarch/android/phoenix/assets/
  
  # clean and build
  #TODO: modify build architecture here
  NDK_TOOLCHAIN_VERSION=4.8 ant clean
  NDK_TOOLCHAIN_VERSION=4.8 ant release
  
  # sign the apk
  jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -storepass libretro -keystore /root/android-tools/my-release-key.keystore /root/libretro-super/retroarch/android/phoenix/bin/retroarch-release-unsigned.apk retroarch
  
  rm -rf /staging/android/${ARCH}/*
  mkdir -p /staging/android/${ARCH}/cores
  cp /root/libretro-super/retroarch/android/phoenix/assets/cores/* /staging/android/${ARCH}/cores/
  7za a -r /staging/android/${ARCH}/cores.7z /staging/android/${ARCH}/cores/*
  
  # zipalign
  `find /root/android-tools/android-sdk-linux/ -name zipalign` -v 4 /root/libretro-super/retroarch/android/phoenix/bin/retroarch-release-unsigned.apk /staging/android/${ARCH}/RetroArch.apk
}


if [ $1 ]; then
  update_code
  $1 || echo "Non-zero return from build."
fi
