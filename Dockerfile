FROM amazon/aws-cli:latest as awscli
FROM argoproj/argocd:latest as argocd


FROM debian:bookworm-slim

LABEL org.opencontainers.image.source https://github.com/oguzhan-yilmaz/argocd-backup-s3
LABEL org.opencontainers.image.description TODO 

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y \
    && apt-get upgrade -y \
    && apt-get install --no-install-recommends -y curl tar unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -g 12345 argocdbackup \
    && useradd -m -u 12345 -g argocdbackup argocdbackup

COPY --from=awscli /usr/local/aws-cli /usr/local/aws-cli
RUN ln -s /usr/local/aws-cli/v2/current/bin/aws /usr/local/bin/aws

COPY --from=argocd /usr/local/bin/argocd /usr/local/bin/argocd

# Print all binaries in PATH
# CMD find $(echo $PATH | tr ':' ' ') -type f -executable -exec basename {} \; | sort

# COPY entrypoint.sh .
# ENTRYPOINT [ "bash", "entrypoint.sh" ]

USER argocdbackup
WORKDIR /home/argocdbackup

CMD echo "You should override the Dockerfile CMD - Aborting.."; sleep 3s; echo "BYE!";

