# Stage 1: Build wrk from source
FROM alpine:3.12 AS build

# 安装依赖，包括 perl（构建 OpenSSL 所必需）
RUN apk add --no-cache \
    openssl-dev \
    zlib-dev \
    git make \
    gcc \
    musl-dev \
    libbsd-dev \
    perl \
    && \
    git clone https://github.com/wg/wrk.git && \
      cd wrk && make

# Stage 2: Runtime 环境极简
FROM alpine:3.12
RUN apk add --no-cache \
    libgcc
    
RUN adduser -D -H wrk_user

USER wrk_user
COPY --from=build /wrk/wrk /usr/bin/wrk
ENTRYPOINT ["/usr/bin/wrk"]
