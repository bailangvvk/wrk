FROM --platform=$BUILDPLATFORM alpine AS builder

ARG TARGETARCH
ARG WITH_LUAJIT=/usr/local
ARG WITH_OPENSSL=/usr/local/openssl
ARG LUAJIT_INC=/usr/local/include/luajit-2.1
ARG LUAJIT_LIB=/usr/local/lib

RUN apk add --no-cache build-base git openssl-dev curl cmake unzip

# 编译 LuaJIT
RUN git clone https://github.com/LuaJIT/LuaJIT && \
    cd LuaJIT && make -j$(nproc) && make install PREFIX=${WITH_LUAJIT}

# 编译 wrk
WORKDIR /wrk
RUN git clone https://github.com/bailangvvk/wrk.git . && \
    make WITH_LUAJIT=${WITH_LUAJIT} LUAJIT_INC=${LUAJIT_INC} LUAJIT_LIB=${LUAJIT_LIB}

# 最终镜像
FROM alpine
COPY --from=builder /wrk/wrk /usr/local/bin/wrk
ENTRYPOINT ["wrk"]
CMD ["--help"]
