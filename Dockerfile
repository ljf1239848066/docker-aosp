FROM kylemanna/aosp
LABEL maintainer="lxzh123 CORPORTION <1239848066@qq.com>"

COPY sources.list /etc/apt/sources.list

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc             \
    cmake           \
    vim             \
    wget            \
    unzip       &&  \
    rm -rf /var/lib/apt/lists/*

WORKDIR /aosp
ENTRYPOINT ["/root/docker_entrypoint.sh"]