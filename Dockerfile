FROM alpine:3.6

ENV SERVER_ADDR     0.0.0.0
ENV SERVER_PORT     57001
ENV PASSWORD        123123
ENV METHOD          rc4-md5
ENV TIMEOUT         300
ENV DNS_ADDR        8.8.8.8
ENV DNS_ADDR_2      8.8.4.4

RUN apk --no-cache add python \
    libsodium

COPY shadowsocks.tar.gz /mnt/shadowsocks.tar.gz
RUN  tar -zvxf /mnt/shadowsocks.tar.gz -C /mnt && rm -f /mnt/shadowsocks.tar.gz

WORKDIR /mnt/shadowsocks

EXPOSE $SERVER_PORT

CMD python server.py -p $SERVER_PORT -k $PASSWORD -m $METHOD
