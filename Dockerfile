# 第一阶段：多架构编译环境
FROM --platform=$BUILDPLATFORM alpine AS builder

# 构建参数（可通过 build-args 覆盖）
ARG WITH_LUAJIT=/usr/local
ARG WITH_OPENSSL=/usr/local/openssl
ARG LUAJIT_INC=${WITH_LUAJIT}/include/luajit-2.1
ARG LUAJIT_LIB=${WITH_LUAJIT}/lib

# 安装编译依赖
RUN apk add --no-cache \
    build-base \
    git \
    openssl-dev \
    curl \
    cmake \
    unzip

# 编译并安装 LuaJIT
RUN git clone https://github.com/LuaJIT/LuaJIT \
 && cd LuaJIT \
 && make -j$(nproc) \
 && make install PREFIX=${WITH_LUAJIT}

# 把头文件从 luajit-2.1 目录软链接到 /usr/local/include
RUN for hdr in lua.h lauxlib.h lualib.h luaconf.h lua.hpp luajit.h; do \
      ln -s ${LUAJIT_INC}/$hdr ${WITH_LUAJIT}/include/$hdr; \
    done

# 克隆 wrk 源码并编译
WORKDIR /wrk
RUN git clone https://github.com/bailangvvk/wrk.git . \
 && make WITH_LUAJIT=${WITH_LUAJIT} \
         LUAJIT_INC=${WITH_LUAJIT}/include \
         LUAJIT_LIB=${LUAJIT_LIB}

# 第二阶段：最小运行镜像
FROM alpine

# 复制 LuaJIT 运行时库
COPY --from=builder /usr/local/lib/libluajit-5.1.so.2* /usr/local/lib/

# 更新动态链接器缓存
RUN echo "/usr/local/lib" > /etc/ld.so.conf.d/luajit.conf

# （可选）安装 OpenSSL 运行时
RUN apk add --no-cache openssl

COPY --from=builder /wrk/wrk /usr/local/bin/wrk

ENTRYPOINT ["wrk"]
CMD ["--help"]

