# Set the base image to Boomi Atom, can be overridden at build time to molecule
ARG DEPLOY_TYPE=atom
# Set default Boomi version to 5.0.3, can be overridden at build time to any valid Boomi version e.g. 5.0.3-rhel
ARG BOOMI_VERSION=5.0.3
FROM boomi/${DEPLOY_TYPE}:${BOOMI_VERSION}

# Set user to root to install packages and make modifications
USER root

RUN apk add --update --no-cache \
    python3 \
    python3-dev \
    py3-pip \
    jq \
    curl \
    aws-cli \
    && rm -rf /var/cache/apk/*

COPY entrypoint.sh /home/boomi/bin/entrypoint.sh
RUN chmod 755 /home/boomi/bin/entrypoint.sh

EXPOSE 9090 45588 7800

# Set user back to boomi
USER boomi

ENTRYPOINT ["entrypoint.sh", "init"]
