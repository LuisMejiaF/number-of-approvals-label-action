FROM alpine:3.17.1

RUN apk add --no-cache bash curl jq

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]