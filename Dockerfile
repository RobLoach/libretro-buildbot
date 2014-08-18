FROM fedora:20
MAINTAINER l3iggs <l3iggs@live.com>

# setup the generic build environment
RUN yum update -y

# setup repo
RUN yum install -y python python-gnupg git
RUN git config --global user.email "buildbot@none.com"
RUN git config --global user.name "Build Bot"
ADD https://storage.googleapis.com/git-repo-downloads/repo /bin/repo
RUN chmod a+x /bin/repo

# setup ccache
RUN yum install -y ccache
RUN mkdir /ccache
ENV CCACHE_DIR /ccache
RUN cp /usr/bin/ccache /usr/local/bin/
RUN ln -s ccache /usr/local/bin/gcc
RUN ln -s ccache /usr/local/bin/g++
RUN ln -s ccache /usr/local/bin/cc
RUN ln -s ccache /usr/local/bin/c++
RUN ccache -M 6

# all the front-end dependancies
RUN yum install -y make automake clang gcc gcc-c++ mesa-libEGL-devel libv4l-devel libxkbcommon-devel mesa-libgbm-devel Cg libCg zlib-devel freetype-devel libxml2-devel ffmpeg-devel SDL2-devel SDL-devel python3 libCg

# setup repo for this project
RUN cd /root/ && repo init -u https://github.com/libretro/libretro-manifest.git

# add the build script
ADD https://raw.githubusercontent.com/libretro/libretro-buildbot/master/build-now.sh /bin/build-now.sh
RUN chmod a+x /bin/build-now.sh

# for packaging outputs
RUN yum install -y p7zip

# for working in the image
RUN yum install -y vim

# build once now to populate ccache
RUN build-now.sh linux_retroarch

# the commands above here set up the static image
# the command below here gets executed by default when the container is "run" with the `docker run` command
CMD build-now.sh linux_retroarch
