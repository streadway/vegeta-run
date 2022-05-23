FROM golang:1 as build
WORKDIR /app

COPY go.* ./
RUN go mod download

COPY . ./
RUN CGO_ENABLED=0 GOOS=linux go build -mod=readonly -v -o /srv/app


FROM alpine:latest as runtime
ARG VEGETA_VERSION=12.8.4
ARG VEGETA_ARCH=amd64

RUN set -ex \
 && apk add --no-cache ca-certificates jq \
 && apk add --no-cache --virtual .build-deps \
    openssl \
 && cd /tmp \
 && wget -q "https://github.com/tsenart/vegeta/releases/download/v${VEGETA_VERSION}/vegeta_${VEGETA_VERSION}_checksums.txt" \
 && wget -q "https://github.com/tsenart/vegeta/releases/download/v${VEGETA_VERSION}/vegeta_${VEGETA_VERSION}_linux_${VEGETA_ARCH}.tar.gz" \
 && grep linux_${VEGETA_ARCH} *_checksums.txt | sha256sum -c - \
 && tar xzf *linux_${VEGETA_ARCH}* vegeta \
 && mv vegeta /bin/ \
 && rm vegeta* \
 && vegeta -version \
 && apk del .build-deps

COPY --from=build /srv/app /srv/app
CMD ["/srv/app"]


