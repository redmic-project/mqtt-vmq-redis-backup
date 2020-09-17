ARG ALPINE_IMAGE_TAG=3.12.0

FROM alpine:${ALPINE_IMAGE_TAG}

LABEL maintainer="info@redmic.es"

ARG CURL_VERSION=7.69.1-r1
ARG REDIS_VERSION=5.0.9-r0
ARG PYTHON3_VERSION=3.8.5-r0
ARG PY3_PIP_VERSION=20.1.1-r0
ARG AWSCLI_VERSION=1.18.140

RUN apk --no-cache update && \
	apk --no-cache add \
		curl=${CURL_VERSION} \
		redis=${REDIS_VERSION} \
		python3=${PYTHON3_VERSION} \
		py3-pip=${PY3_PIP_VERSION}

RUN pip install --no-cache-dir --upgrade \
	awscli==${AWSCLI_VERSION}

COPY script /

ENTRYPOINT [ "/entrypoint.sh" ]
