FROM alpine:3.9

LABEL maintainer="info@redmic.es"

RUN apk --no-cache update && \
	apk --no-cache add \
		redis \
		python3

RUN pip3 install --no-cache-dir --upgrade awscli

COPY script /

ENTRYPOINT [ "/entrypoint.sh" ]
