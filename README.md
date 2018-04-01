# 极简Android源码编译环境搭建工具

# 0x0 前言

这是一个帮助快速搭建Android源码编译环境的工具，项目fork自 [tiann/docker-aosp](https://github.com/tiann/docker-aosp)，其fork自 [kylemanna/docker-aosp](https://github.com/kylemanna/docker-aosp)；针对Docker以及天朝的网络环境做了一部分修改，仅供China用户使用。

> 具体介绍见：[README-OLD](https://github.com/ljf1239848066/docker-aosp/blob/master/old/README.md)

由于中间作者的脚本在我这里使用一直没成功，这里对使用步骤进行了一点修改变动。

# 0x1 镜像增强——制作自己的docker镜像

## 新建Dockerfile，内容如下：

```
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
```

1.   修改软件源，改为国内分源，或者可以按需修改source.list，改为自己觉得速度比较快，方便后面安装其他软件的软件源。
2.   补充安装几个常用软件，这个自行按需增删

## 编译镜像

```
docker build . -t lxzh/aosp:1.0
```

# 0x2 下载准备

这个建议还是手动启动镜像，之前用过原作者提供的脚本，不好使，老是失败。
另外，如果系统时Mac，一定要注意创建磁盘镜像时格式选择`OS X扩展 (区分大小写，日志式)`，磁盘大小建议**60G或更大**。

## 1.  启动容器

```
docker run -it --name aosp -v /Volumes/Android:/aosp -v /Volumes/Android/ccache:/tmp/ccache lxzh/aosp:1.0 /bin/bash
```

## 2. 下载源代码

- 本地仓库初始化

```
#通过清华镜像下载
repo init --depth 1 -u "https://aosp.tuna.tsinghua.edu.cn/platform/manifest" -b "android-8.1.0_r9" --repo-url=https://mirrors.tuna.tsinghua.edu.cn/git/git-repo/

#通过中科大镜像下载
repo init --depth 1 -u "git://mirrors.ustc.edu.cn/aosp/platform/manifest" -b "android-8.1.0_r9"  --repo-url=https://gerrit-googlesource.lug.ustc.edu.cn/git-repo
```
>ps: 这里-u的参数如果用https格式时，前面`--depth 1`会失效

- 切换分支(不需要切换直接跳此节)

当前选择了此时Android的最新分支`android-8.1.0_r9`，如果需要查询有哪些分支，在aosp目录下：

```
cd .repo/manifests/
git branch -a
```

切换分支:

```
repo init --depth 1 -u "git://mirrors.ustc.edu.cn/aosp/platform/manifest" -b new_branch
```

-  代码下载

```
repo sync -c
```

此步骤视具体网速，耗时3h+，建议放在晚上进行，大概会下载仓库10G左右，本地checkout代码另占用37G左右，后面编译缓存大小10G，因此建议准备一个大于等于60G的磁盘。


# 0x3 源码编译

在代码根目录依次执行以下命令：

```
#获取CPU数
cpus=$(grep ^processor /proc/cpuinfo | wc -l)
#设置缓存大小
prebuilts/misc/linux-x86/ccache/ccache -M 10G
#环境设置
source build/envsetup.sh
#设置BUILD目标
lunch aosp_arm-eng
#开始编译
make -j $cpus
```

> 其中的`aosp_arm_eng`请自行选择，[这里](https://www.cnblogs.com/chiefhsing/p/5175624.html)有介绍

# 0x4 感谢
- [kylemanna/docker-aosp](https://github.com/kylemanna/docker-aosp)
- [tiann/docker-aosp](https://github.com/tiann/docker-aosp)
- [清华镜像](https://mirrors.tuna.tsinghua.edu.cn/help/AOSP/)
- [中科大镜像](https://lug.ustc.edu.cn/wiki/mirrors/help/aosp)
- [云栖社区](https://yq.aliyun.com/articles/50709)

