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

# 软链接头文件至 include
RUN for hdr in lua.h lauxlib.h lualib.h luaconf.h lua.hpp luajit.h; do \
      ln -s ${LUAJIT_INC}/$hdr ${WITH_LUAJIT}/include/$hdr; \
    done

# 编译 wrk
WORKDIR /wrk
RUN git clone https://github.com/bailangvvk/wrk.git . \
 && make WITH_LUAJIT=${WITH_LUAJIT} \
         LUAJIT_INC=${WITH_LUAJIT}/include \
         LUAJIT_LIB=${WITH_LUAJIT}/lib

# 第二阶段：最小运行镜像
FROM alpine

# 安装运行时依赖：OpenSSL
RUN apk add --no-cache openssl

# 复制 LuaJIT 动态库到系统库路径
COPY --from=builder /usr/local/lib/libluajit-5.1.so.2* /usr/lib/

# 复制 wrk 二进制
COPY --from=builder /wrk/wrk /usr/local/bin/wrk

# 默认入口和帮助
ENTRYPOINT ["wrk"]
CMD ["--help"]
