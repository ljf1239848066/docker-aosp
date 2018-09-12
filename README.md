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

ENV USE_CCACHE 1
ENV CCACHE_DIR /tmp/ccache
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
另外，如果系统时Mac，一定要注意创建磁盘镜像时格式选择`OS X扩展 (区分大小写，日志式)`，否则会报FAQ第1条错误，磁盘大小建议**60G或更大**。

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

- 切换分支(不需要切换直接跳过此小节)

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

此步骤视具体网速，耗时3h+，建议放在晚上进行，大概会下载仓库10G左右，本地checkout代码另占用37G左右，后面编译缓存大小10G，因此建议准备一个大于等于60G(视Android版本差异，版本越新占用空间越大，不确定就尽量准备足够大的硬盘)的磁盘。

为避免网络问题同步失败，可准备一个脚本sync.sh循环同步直到同步成功为止：

```
#!/bin/bash 
repo sync -c -j4
while [ $? = 1 ]; do
   echo "================sync failed, re-sync again =====" 
   sleep 3
   repo sync
        done
```

保存后`./sync.sh`执行，如果执行报错赋一下权限`chmod +x sync.sh`，重新执行即可。


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

## FAQ

### 1. 磁盘不区分大小写问题

```
15:13:31 ************************************************************
15:13:31 You are building on a case-insensitive filesystem.
15:13:31 Please move your source tree to a case-sensitive filesystem.
15:13:31 ************************************************************
15:13:31 Case-insensitive filesystems not supported

#### failed to build some targets (13 seconds) ####
```

需要格式化磁盘为区分大小写模式。

###  2. `ckati failed with: signal: killed`问题
是内存不够用，建议清理内存重新make;或者是Docker内存限制，macOS可按下图修改：

<img src="http://o8ydbqznc.bkt.clouddn.com/markdown/1522769631943.png" width="400"/>
 
### 3. USER环境变量问题

（由于运行的docker 容易没有配置USER环境变量），报错：

```
JACK VMCOMMAND="java -Dfile.encoding=UTF-8 -Xms2560m -XX:+TieredCompilation -jar out/host/linux-x86/framework/jack-launcher.jar " JACK_JAR="out/host/linux-x86/framework/jack.jar" out/host/linux-x86/bin/jack-admin start-server out/host/linux-x86/bin/jack-admin: line 27: USER: unbound variable 
```

执行

``` 
export USER=$(whoami) 
```
	
命令重新编译；或者在docker的构建文件Dockerfile中加上配置容器默认用户名变量：
	
```
ENV USER aosp   #或者自己需要的名字 
```
	
### 4. Communication error with Jack server

问题log如下：

```
FAILED: /bin/bash out/target/common/obj/JAVA_LIBRARIES/framework_intermediates/with-local/classes.dex.rsp
Communication error with Jack server (56). Try 'jack-diagnose'
ninja: build stopped: subcommand failed.
build/core/ninja.mk:148: recipe for target 'ninja_wrapper' failed
make: *** [ninja_wrapper] Error 1
```
Jack server 启动失败，可以尝试执行以下命令解决：

```
jack-admin start-server
```

### 5. Out of memory error

问题log如下：

```
Try increasing heap size with java option '-Xmx<size>'.
Warning: This may have produced partial or corrupted output.
[ 34% 12242/35623] Building with Jack: out/target/common/obj/JAVA_LIBRARIES/libprotobuf-java-nano_intermediates/classes.jack
ninja: build stopped: subcommand failed.
build/core/ninja.mk:148: recipe for target 'ninja_wrapper' failed
make: *** [ninja_wrapper] Error 1
```

**解决方法**：
上面已经给出提示：`Try increasing heap size with java option '-Xmx<size>'`。

*  1. 查询Jack server运行状态 

```
jack-admin list-server
```

*  2. 停止Jack server

```
jack-admin stop-server
```

* 3. 配置-Xmx参数

添加`-Xmx2048m`或者`-Xmx2g`，当然也可以设置更大的内存，例如-Xmx3g、-Xmx4g。

打开**`prebuilts/sdk/tools/jack-admin`**文件，修改**`454`**行:

```
JACK_SERVER_COMMAND="java -XX:MaxJavaStackTraceDepth=-1 -Djava.io.tmpdir=$TMPDIR $JACK_SERVER_VM_ARGUMENTS -cp $LAUNCHER_JAR $LAUNCHER_NAME"
```

改为:

```
JACK_SERVER_COMMAND="java -Xmx2g -XX:MaxJavaStackTraceDepth=-1 -Djava.io.tmpdir=$TMPDIR $JACK_SERVER_VM_ARGUMENTS -cp $LAUNCHER_JAR $LAUNCHER_NAME"
```

*  4. 重启Jack server

```
jack-admin start-server
```
启动后重新编译。


# 0x4 感谢
- [kylemanna/docker-aosp](https://github.com/kylemanna/docker-aosp)
- [tiann/docker-aosp](https://github.com/tiann/docker-aosp)
- [清华镜像](https://mirrors.tuna.tsinghua.edu.cn/help/AOSP/)
- [中科大镜像](https://lug.ustc.edu.cn/wiki/mirrors/help/aosp)
- [云栖社区](https://yq.aliyun.com/articles/50709)

