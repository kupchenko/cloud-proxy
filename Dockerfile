FROM alpine:latest

RUN apk update && apk add git build-base linux-headers bind-tools

RUN mkdir -p /usr/src

WORKDIR /usr/src
RUN git clone https://github.com/z3APA3A/3proxy.git

WORKDIR /usr/src/3proxy
RUN git checkout tags/0.8.12

RUN make -f Makefile.Linux && \
    make -f Makefile.Linux install

    FROM alpine:latest

    COPY --from=0 /usr/local/bin/ /usr/local/bin/

    RUN mkdir -p /etc/3proxy && mkdir -p /var/log/3proxy && apk update && apk add bind-tools

    CMD ["/usr/local/bin/3proxy","/etc/3proxy/3proxy.cfg"]
