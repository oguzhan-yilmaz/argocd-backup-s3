FROM amazon/aws-cli:latest as awscli
FROM argoproj/argocd:latest as argocd


FROM debian:bookworm-slim

LABEL org.opencontainers.image.source https://github.com/oguzhan-yilmaz/argocd-backup-s3
LABEL org.opencontainers.image.description TODO 

ENV DEBIAN_FRONTEND=noninteractive

# Instead of just creating the user
RUN apt-get update -y \
 && apt-get upgrade -y \
 && apt-get install --no-install-recommends -y curl tar unzip ca-certificates \
 && apt-get autoremove \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && groupadd -g 1001070001 argocdbackup \
 && useradd -m -u 1001070001 -g argocdbackup argocdbackup \
 && mkdir -p /argocdbackup/.config/argo \
 && chown -R argocdbackup:argocdbackup /argocdbackup

WORKDIR /argocdbackup
ENV HOME /argocdbackup

# get the aws cli from it's docker image
COPY --from=awscli /usr/local/aws-cli /usr/local/aws-cli
RUN ln -s /usr/local/aws-cli/v2/current/bin/aws /usr/local/bin/aws

# get the argocd cli from it's docker image
COPY --from=argocd /usr/local/bin/argocd /usr/local/bin/argocd

USER argocdbackup

COPY entrypoint.sh .

ENTRYPOINT [ "bash", "entrypoint.sh" ]

