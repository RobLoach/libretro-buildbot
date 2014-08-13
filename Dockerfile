#this builds cores for linux
FROM l3iggs/libretro-arch-base:latest
MAINTAINER l3iggs <l3iggs@live.com>

# our one open-gl dependency
RUN pacman -Suy --noconfirm mesa-libgl

# build the cores now to populate ccache
WORKDIR /root/libretro-super/
RUN ./libretro-build.sh

# for working in the image
RUN pacman -Suy --noconfirm vim

# for packaging outputs
RUN pacman -Suy --noconfirm p7zip

WORKDIR /root/

#add the build script
ADD https://raw.githubusercontent.com/l3iggs/libretro-buildbot/master/nightly-build.sh /bin/nightly-build
RUN chmod a+x /bin/nightly-build

# the commands above here set up the static image
# the command below here gets executed by default when the container is "run" with the `docker run` command
CMD nightly-build linux_x86_64
