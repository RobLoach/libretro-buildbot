#!/bin/bash
# this script lives in each of the Docker build images and initiates and
# manages doing the actual compilation and moving the generated binaries to /staging

# builds the front end for linux
linux()
{
  rm -rf /staging/
  #declare -a ARCHES=("x86_64" "i686")
  declare -a ARCHES=("x86_64")
  for ARCH in "${ARCHES[@]}"
  do
    if [ "$1" == "frontend" ] || [ -z "$1" ]; then #build frontend unless this is a core specific build
      echo "Building ${ARCH} frontend for ${DISTRO}..."
      export STRIP=strip
      cd /root/libretro-super
      ./retroarch-build.sh
      
      mkdir -p /staging/linux/${DISTRO}/${ARCH}/RetroArch/files
      mkdir -p /staging/linux/${DISTRO}/${ARCH}/RetroArch_with_cores/files
      
      cd /root/libretro-super/retroarch/
      make DESTDIR=/staging/linux/${DISTRO}/${ARCH}/RetroArch/files install
      make DESTDIR=/staging/linux/${DISTRO}/${ARCH}/RetroArch_with_cores/files install
      
      7za a -r /staging/linux/${DISTRO}/${ARCH}/RetroArch/RetroArch.7z /staging/linux/${DISTRO}/${ARCH}/RetroArch/files/*
      rm -rf /staging/linux/${DISTRO}/${ARCH}/RetroArch/files
    fi
    
    if [ "$1" != "frontend" ]; then # build cores unless this is a frontend only build
      echo "Building ${ARCH} cores for ${DISTRO}..."
      # build cores
      rm -rf /root/libretro-super/dist/unix*
      cd /root/libretro-super
      ./libretro-build.sh $1
      
      mkdir -p /staging/linux/${DISTRO}/${ARCH}/RetroArch_with_cores/files/usr/lib/libretro
      mkdir -p /staging/linux/${DISTRO}/${ARCH}/cores/
      mkdir -p /staging/linux/${DISTRO}/${ARCH}/all_cores/
      
      cd /root/libretro-super
      ./libretro-install.sh /staging/linux/${DISTRO}/${ARCH}/RetroArch_with_cores/files/usr/lib/libretro
      ./libretro-install.sh /staging/linux/${DISTRO}/${ARCH}/cores/
      
      7za a -r /staging/linux/${DISTRO}/${ARCH}/all_cores/cores.7z /staging/linux/${DISTRO}/${ARCH}/cores/*
      7za a -r /staging/linux/${DISTRO}/${ARCH}/RetroArch_with_cores/RetroArch_with_cores.7z /staging/linux/${DISTRO}/${ARCH}/RetroArch_with_cores/files/*
      rm -rf   /staging/linux/${DISTRO}/${ARCH}/RetroArch_with_cores/files
      
      #cd /staging/linux/${ARCH}/files/ && zip -r /staging/linux/${ARCH}/RetroArch.zip *
    fi
  done
}

# builds windows cores and frontend
windows()
{
  rm -rf /staging
  declare -a ARCHES=("x86_64" "i686")
  for ARCH in "${ARCHES[@]}"
  do
    if [ "$1" == "frontend" ] || [ -z "$1" ]; then #build frontend unless this is a core specific build
      echo "Building ${ARCH} windows frontend..."
      # cd /root/libretro-super 
      # HOST_CC=i686-w64-mingw32- platform=mingw ./retroarch-build.sh
      
      cd /root/libretro-super/retroarch
      # CROSS_COMPILE=i686-w64-mingw32- ./configure
      
      # disable some stuff
      sed -i 's/HAVE_RSOUND = 1/HAVE_RSOUND = 0/g' /root/libretro-super/retroarch/Makefile.win
      sed -i 's/HAVE_PYTHON = 1/HAVE_PYTHON = 0/g' /root/libretro-super/retroarch/Makefile.win
      
      platform=mingw make -f Makefile.win clean
      # build frontend
      C_INCLUDE_PATH=/usr/${ARCH}-w64-mingw32/include/SDL:/usr/${ARCH}-w64-mingw32/include/libxml2/:/usr/${ARCH}-w64-mingw32/include/freetype2  HOST_PREFIX=${ARCH}-w64-mingw32- make -f Makefile.win
      
      mkdir -p /staging/windows/${ARCH}/RetroArch/files/bin
      mkdir -p /staging/windows/${ARCH}/RetroArch/files/assets/autoconfig
      mkdir -p /staging/windows/${ARCH}/RetroArch/files/user-content
      mkdir -p /staging/windows/${ARCH}/RetroArch/files/save-files
      mkdir -p /staging/windows/${ARCH}/RetroArch/files/save-states
      mkdir -p /staging/windows/${ARCH}/RetroArch/files/system
      mkdir -p /staging/windows/${ARCH}/RetroArch/files/screenshots
      
      # "install" the frontend
      cd /root/libretro-super/retroarch/
      # platform=mingw make DESTDIR=/staging/windows/${ARCH}/RetroArch/files install
      cp /root/libretro-super/retroarch/retroarch.cfg /staging/windows/${ARCH}/RetroArch/files/bin/retroarch.cfg
      cp /root/libretro-super/retroarch/retroarch.exe /staging/windows/${ARCH}/RetroArch/files/bin
      cp /root/libretro-super/retroarch//tools/retroarch-joyconfig.exe /staging/windows/${ARCH}/RetroArch/files/bin
      #TODO: insert logic here to only copy the required dll files
      cp /usr/${ARCH}-w64-mingw32/bin/*.dll* /staging/windows/${ARCH}/RetroArch/files/bin
      cp -r /root/libretro-super/dist/info /staging/windows/${ARCH}/RetroArch/files/assets/
      cp -r /root/libretro-super/retroarch/media/shaders /staging/windows/${ARCH}/RetroArch/files/assets/
      rm -rf /staging/windows/${ARCH}/RetroArch/files/assets/shaders/.git
      cp -r /root/libretro-super/retroarch/media/autoconfig/winxinput/* /staging/windows/${ARCH}/RetroArch/files/assets/autoconfig
      
      # some sane defaults for .cfg
      sed -i 's,# savefile_directory =,savefile_directory = ":\\..\\save-files",g' /staging/windows/${ARCH}/RetroArch/files/bin/retroarch.cfg
      sed -i 's,# savestate_directory =,savefile_directory = ":\\..\\save-states",g' /staging/windows/${ARCH}/RetroArch/files/bin/retroarch.cfg
      sed -i 's,# libretro_directory =,libretro_directory = ":\\..\\assets\\cores",g' /staging/windows/${ARCH}/RetroArch/files/bin/retroarch.cfg
      sed -i 's,# libretro_info_path =,libretro_info_path = ":\\..\\assets\\info",g' /staging/windows/${ARCH}/RetroArch/files/bin/retroarch.cfg
      sed -i 's,# system_directory =,system_directory = ":\\..\\system",g' /staging/windows/${ARCH}/RetroArch/files/bin/retroarch.cfg
      sed -i 's,# rgui_browser_directory =,rgui_browser_directory = ":\\..",g' /staging/windows/${ARCH}/RetroArch/files/bin/retroarch.cfg
      sed -i 's,# content_directory =,content_directory = ":\\..\\user-content",g' /staging/windows/${ARCH}/RetroArch/files/bin/retroarch.cfg
      sed -i 's,# assets_directory =,assets_directory = ":\\..\\assets",g' /staging/windows/${ARCH}/RetroArch/files/bin/retroarch.cfg
      sed -i 's,# video_shader_dir =,video_shader_dir = ":\\..\\assets\\shaders",g' /staging/windows/${ARCH}/RetroArch/files/bin/retroarch.cfg
      sed -i 's,# joypad_autoconfig_dir  =,joypad_autoconfig_dir  = ":\\..\\assets\\autoconfig",g' /staging/windows/${ARCH}/RetroArch/files/bin/retroarch.cfg
      sed -i 's,# screenshot_directory =,screenshot_directory  = ":\\..\\screenshots",g' /staging/windows/${ARCH}/RetroArch/files/bin/retroarch.cfg
      
      cd /staging/windows/${ARCH}/RetroArch/files && zip -r ../RetroArch.zip *
      
      #cleanup changes to windows makefile
      rm -rf /root/libretro-super/retroarch/Makefile.win
      cd /root/libretro-super/retroarch/ && git stash
    fi
    
    if [ "$1" != "frontend" ] ; then # build cores unless this is a frontend only build
      echo "Building ${ARCH} windows cores..."
      
      rm -rf /root/libretro-super/dist/win
      cd /root/libretro-super
      # build cores
      HOST_CC=${ARCH}-w64-mingw32 platform=mingw ./libretro-build.sh $1
      
      #install cores and other assets
      mkdir -p /staging/windows/${ARCH}/cores
      platform=mingw ./libretro-install.sh /staging/windows/${ARCH}/cores
      
      cd /staging/windows/${ARCH}/cores && zip -r ../cores.zip *
      
      cp -r /staging/windows/${ARCH}/cores /staging/windows/${ARCH}/RetroArch/files/assets/
      rm -rf /staging/windows/${ARCH}/RetroArch/files/assets/cores/*.info
      cd /staging/windows/${ARCH}/RetroArch/files && zip -r ../../RetroArch_with_cores.zip *
      
      rm -rf /staging/windows/${ARCH}/RetroArch/files
    fi
  done
}

# builds the android frontend and cores and packages them into an apk
android()
{
  rm -rf /staging/
  IFS=' ' read -ra ABIS <<< "$TARGET_ABIS"
  
  OLD_PATH=$PATH
  
  for a in "${ABIS[@]}"
  do
    # export abi to config file
    echo "export TARGET_ABIS=\"${a}\"" > /root/libretro-super/libretro-config-user.sh
    
    # setup ndk
    if [[ ${a} == "*64*" ]]; then
      NDK_DIR=/root/android-tools/android-ndk64
    else
      NDK_DIR=/root/android-tools/android-ndk
    fi
    export PATH=$OLD_PATH:${NDK_DIR}
    
    rm -rf /root/libretro-super/retroarch/android/phoenix/assets
    
    echo "Building ${a} Android cores..."
    if [ "$1" != "frontend" ]; then # build cores unless this is a frontend only build
      rm -rf /root/libretro-super/dist/android/${a}/*
      cd /root/libretro-super/ && ./libretro-build-android-mk.sh $1
      
      #setup paths
      mkdir -p /staging/android/${a}/cores
      mkdir -p /root/libretro-super/retroarch/android/phoenix/assets
      
      cp -r /root/libretro-super/dist/android/${a} /root/libretro-super/retroarch/android/phoenix/assets/cores
      cp /root/libretro-super/retroarch/android/phoenix/assets/cores/* /staging/android/${a}/cores/
      cd /root/libretro-super/dist/android/${a}/ && zip -r /staging/android/${a}/cores.zip *
    fi
    
    if [ "$1" == "frontend" ] || [ -z "$1" ]; then #build frontend unless this is a core specific build
      echo "Building ${a} Android frontend..."
      # build frontend
      cd /root/libretro-super/retroarch/android/phoenix/libs/appcompat && android update project --target ${RA_ANDROID_API} --path .
      cd /root/libretro-super/retroarch/android/phoenix/libs/googleplay && android update project --target ${RA_ANDROID_API} --path .
      cd /root/libretro-super/retroarch/android/phoenix && android update project --target ${RA_ANDROID_API} --path .
      
      # setup paths
      mkdir -p /root/libretro-super/retroarch/android/phoenix/assets/autoconfig
      
      #convert shaders
      cd /root/libretro-super/retroarch && make -f Makefile.griffin shaders-convert-glsl
      
      # copy in assets
      cp -r /root/libretro-super/dist/info /root/libretro-super/retroarch/android/phoenix/assets/
      cp -r /root/libretro-super/retroarch/media/shaders_glsl /root/libretro-super/retroarch/android/phoenix/assets/
      cp -r /root/libretro-super/retroarch/media/overlays /root/libretro-super/retroarch/android/phoenix/assets/
      cp -r /root/libretro-super/retroarch/media/autoconfig/android/* /root/libretro-super/retroarch/android/phoenix/assets/autoconfig/
      
      # clean before building
      cd /root/libretro-super/retroarch/android/phoenix && ant clean -Dndk.dir=${NDK_DIR}
      
      KEYSTORE=/root/android-tools/my-release-key.keystore
      if [ $KEYSTORE_PASSWORD ]; then #release build case
        echo "Release build using KEYSTORE_PASSWORD and KEYSTORE_URL environment variables."
        
        # release build
        cd /root/libretro-super/retroarch/android/phoenix && ant release -Dndk.dir=${NDK_DIR}
        
        #download the keystore
        curl ${KEYSTORE_URL} > ${KEYSTORE}
        
        # sign the apk
        jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -storepass ${KEYSTORE_PASSWORD} -keystore ${KEYSTORE} /root/libretro-super/retroarch/android/phoenix/bin/retroarch-release-unsigned.apk retroarch
        
        # delete the keystore
        rm ${KEYSTORE}
        
        # zipalign
        `find /root/android-tools/android-sdk-linux/ -name zipalign` -v 4 /root/libretro-super/retroarch/android/phoenix/bin/retroarch-release-unsigned.apk /root/libretro-super/retroarch/android/phoenix/bin/RetroArch.apk
      else #debug(nighlty) build case
        # KEYSTORE_PASSWORD=libretro
        
        # this hacks a new "debug" version of RetroArch that can be installed alongside the play store version for testing
        sed -i 's/com\.retroarch/com\.debugretroarch/g' `grep -lr 'com\.retroarch' /root/libretro-super/retroarch/android/phoenix`
        sed -i 's/com_retroarch/com_debugretroarch/g' `grep -lr 'com_retroarch' /root/libretro-super/retroarch/android/phoenix`
        mv /root/libretro-super/retroarch/android/phoenix/src/com/retroarch /root/libretro-super/retroarch/android/phoenix/src/com/debugretroarch || true
        mv /root/libretro-super/retroarch/android/phoenix/jni/native/com_retroarch_browser_NativeInterface.h /root/libretro-super/retroarch/android/phoenix/jni/native/com_debugretroarch_browser_NativeInterface.h  || true
        sed -i 's,<string name="app_name">[^<]*</string>,<string name="app_name">RetroArch Dev</string>,g' /root/libretro-super/retroarch/android/phoenix/res/values/strings.xml
        sed -i "s/android:versionCode=\"[0-9]*\"/android:versionCode=\"`date -u +%s`\"/g" /root/libretro-super/retroarch/android/phoenix/AndroidManifest.xml
        #sed -i 's/android:minSdkVersion="9"/android:minSdkVersion="L"/g' /root/libretro-super/retroarch/android/phoenix/AndroidManifest.xml
        
        # build debug apk
        cd /root/libretro-super/retroarch/android/phoenix && ant debug -Dndk.dir=${NDK_DIR}
        mv /root/libretro-super/retroarch/android/phoenix/bin/retroarch-debug.apk /root/libretro-super/retroarch/android/phoenix/bin/RetroArch.apk
      fi
      
      # copy the apk to staging
      cp /root/libretro-super/retroarch/android/phoenix/bin/RetroArch.apk /staging/android/${a}/RetroArch.apk
    fi
  done
  
  export PATH=$OLD_PATH
  
  rm /root/libretro-super/libretro-config-user.sh
  
  # let's not leave the debug mess in libretro-super/retroarch/android 
  cd /root/libretro-super/retroarch/android && rm -rf phoenix
  cd /root/libretro-super/retroarch/android && git stash
}

if [ $1 ]; then
  if [ -z "$2" ]; then
    echo "Building $1 cores and frontened"
  else
    echo "Building only $2 for $1"
  fi

  cd /root/libretro-super && . ./libretro-config.sh
  $1 $2
  
  # show ccache stats
  ccache -s
else
  echo "Not building anything"
fi
