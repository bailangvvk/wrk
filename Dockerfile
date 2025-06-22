# 多架构编译环境
FROM --platform=$BUILDPLATFORM alpine AS builder

ARG TARGETARCH
ARG WITH_LUAJIT=/usr/local
ARG LUAJIT_INC=${WITH_LUAJIT}/include/luajit-2.1
ARG LUAJIT_LIB=${WITH_LUAJIT}/lib

RUN apk add --no-cache \
    build-base \
    git \
    openssl-dev \
    curl \
    cmake \
    unzip

# 构建 LuaJIT（默认支持 ARM64 和 x86_64）
RUN git clone https://github.com/LuaJIT/LuaJIT \
 && cd LuaJIT \
 && make -j$(nproc) \
 && make install PREFIX=${WITH_LUAJIT}

# 链接头文件
RUN for hdr in lua.h lauxlib.h lualib.h luaconf.h lua.hpp luajit.h; do \
      ln -s ${LUAJIT_INC}/$hdr ${WITH_LUAJIT}/include/$hdr; \
    done

# 构建 wrk
WORKDIR /wrk
RUN git clone https://github.com/bailangvvk/wrk.git . \
 && make WITH_LUAJIT=${WITH_LUAJIT} \
         LUAJIT_INC=${WITH_LUAJIT}/include \
         LUAJIT_LIB=${WITH_LUAJIT}/lib

# 运行镜像（超小体积）
FROM alpine

# 安装运行时依赖
RUN apk add --no-cache \
    openssl \
    libgcc

# 拷贝 LuaJIT 动态库
COPY --from=builder /usr/local/lib/libluajit-5.1.so.2* /usr/lib/

# 拷贝 wrk 可执行文件
COPY --from=builder /wrk/wrk /usr/local/bin/wrk

ENTRYPOINT ["wrk"]
CMD ["--help"]
