FROM amazon/aws-cli:latest as awscli
FROM argoproj/argocd:latest as argocd

FROM debian:bookworm-slim

LABEL org.opencontainers.image.source https://github.com/oguzhan-yilmaz/argocd-backup-s3
LABEL org.opencontainers.image.description TODO 

ENV DEBIAN_FRONTEND=noninteractive

# Instead of just creating the user
RUN apt-get update -y \
 && apt-get upgrade -y \
 && apt-get install --no-install-recommends -y curl tar unzip ca-certificates gpg lsb-release \
 \
 #azcopy ınstallation
 && echo "Installing AzCopy..." \
 && curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /etc/apt/trusted.gpg.d/microsoft.gpg \
 && echo "deb [arch=amd64] https://packages.microsoft.com/debian/$(lsb_release -rs)/prod $(lsb_release -cs) main" > /etc/apt/sources.list.d/microsoft-prod.list \
 && apt-get update -y \
 && apt-get install -y azcopy \
 \
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

# ÖNCE 'root' olarak 'entrypoint.sh' dosyasını kopyala ve izinlerini ayarla
COPY entrypoint.sh .

# ŞİMDİ, tüm hazırlıklar bittikten sonra, güvenli kullanıcıya geçiş yap
USER argocdbackup

ENTRYPOINT [ "bash", "entrypoint.sh" ]