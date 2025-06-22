# 第一阶段：多架构编译环境
FROM --platform=$BUILDPLATFORM alpine AS builder

# 构建参数（可通过 build-args 覆盖）
ARG WITH_LUAJIT=/usr/local
ARG WITH_OPENSSL=/usr/local/openssl
ARG LUAJIT_INC=/usr/local/include/luajit-2.1
ARG LUAJIT_LIB=/usr/local/lib

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

# 克隆 wrk 源码并编译
WORKDIR /wrk
RUN git clone https://github.com/bailangvvk/wrk.git . \
 && make WITH_LUAJIT=${WITH_LUAJIT} \
         LUAJIT_INC=${LUAJIT_INC} \
         LUAJIT_LIB=${LUAJIT_LIB}

# 第二阶段：最小运行镜像
FROM alpine

# 可选：如果运行 wrk 时需要 SSL，安装 openssl 运行时
RUN apk add --no-cache openssl

# 复制编译好的二进制
COPY --from=builder /wrk/wrk /usr/local/bin/wrk

# 默认入口和帮助命令
ENTRYPOINT ["wrk"]
CMD ["--help"]
