FROM ubuntu:22.04

RUN apt update \
    && apt upgrade -y

RUN apt install -y curl git jq libicu70

RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

ENV TARGETARCH="linux-x64"

WORKDIR /azp/

COPY ./start.sh ./

RUN chmod +x ./start.sh

RUN useradd -d /azp agent \
    && chown -R agent ./

USER agent

ENTRYPOINT ./start.sh
