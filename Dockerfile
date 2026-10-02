# syntax=docker/dockerfile:1

FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG GO_VERSION=1.24.7

ENV TZ=UTC \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    GOPATH=/home/bug-bounty/go \
    GOBIN=/home/bug-bounty/go/bin \
    PATH=/home/bug-bounty/go/bin:/home/bug-bounty/.pdtm/go/bin:/opt/tools/sqlmap:/opt/tools/dirsearch:$PATH

# System dependencies are kept in one layer and apt metadata is removed afterwards.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        libpcap-dev \
        python3 \
        python3-pip \
        python3-venv \
        unzip \
        whois \
        dnsutils \
        jq \
        nmap \
        netcat-openbsd \
    && rm -rf /var/lib/apt/lists/* \
    && arch="$(dpkg --print-architecture)" \
    && case "$arch" in \
         amd64) goarch='amd64' ;; \
         arm64) goarch='arm64' ;; \
         *) echo "Unsupported architecture: $arch" >&2; exit 1 ;; \
       esac \
    && curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${goarch}.tar.gz" -o /tmp/go.tgz \
    && tar -C /usr/local -xzf /tmp/go.tgz \
    && rm /tmp/go.tgz

ENV PATH=/usr/local/go/bin:$PATH

RUN groupadd --gid 10001 bug-bounty \
    && useradd --uid 10001 --gid 10001 --create-home --shell /bin/bash bug-bounty \
    && mkdir -p /opt/tools /opt/wordlists /mnt \
    && chown -R bug-bounty:bug-bounty /opt/tools /opt/wordlists /mnt /home/bug-bounty

USER bug-bounty
WORKDIR /mnt

RUN git clone --depth 1 --filter=blob:none --sparse https://github.com/danielmiessler/SecLists.git /opt/wordlists/SecLists \
    && git -C /opt/wordlists/SecLists sparse-checkout set Discovery Fuzzing Passwords Usernames

# Findomain publishes architecture-specific Linux release archives.
RUN case "$(dpkg --print-architecture)" in \
      amd64) findomain_asset='findomain-linux.zip' ;; \
      arm64) findomain_asset='findomain-aarch64.zip' ;; \
      *) echo "Unsupported architecture for Findomain" >&2; exit 1 ;; \
    esac \
    && mkdir -p /tmp/findomain /home/bug-bounty/go/bin \
    && curl -fsSL "https://github.com/findomain/findomain/releases/latest/download/${findomain_asset}" -o /tmp/findomain.zip \
    && unzip -q /tmp/findomain.zip -d /tmp/findomain \
    && install -m 0755 /tmp/findomain/findomain /home/bug-bounty/go/bin/findomain \
    && rm -rf /tmp/findomain /tmp/findomain.zip

# ffuf and pdtm are Go binaries. pdtm installs the ProjectDiscovery suite into
# the bug-bounty user's .pdtm directory, which is included in PATH above.
RUN go install github.com/ffuf/ffuf/v2@latest \
    && go install github.com/tomnomnom/assetfinder@latest \
    && go install github.com/gwen001/github-subdomains@latest \
    && go install github.com/trufflesecurity/trufflehog/v3@latest \
    && go install github.com/sensepost/gowitness@latest \
    && go install github.com/projectdiscovery/pdtm/cmd/pdtm@latest \
    && pdtm -install-all

# Keep the Python tools isolated from Ubuntu's system Python.
RUN python3 -m venv /home/bug-bounty/.venv \
    && /home/bug-bounty/.venv/bin/pip install --no-cache-dir --upgrade pip \
    && git clone --depth 1 https://github.com/sqlmapproject/sqlmap.git /opt/tools/sqlmap \
    && git clone --depth 1 https://github.com/maurosoria/dirsearch.git /opt/tools/dirsearch \
    && /home/bug-bounty/.venv/bin/pip install --no-cache-dir -r /opt/tools/dirsearch/requirements.txt \
    && printf '#!/bin/sh\nexec /home/bug-bounty/.venv/bin/python /opt/tools/sqlmap/sqlmap.py "$@"\n' > /opt/tools/sqlmap/sqlmap \
    && printf '#!/bin/sh\nexec /home/bug-bounty/.venv/bin/python /opt/tools/dirsearch/dirsearch.py "$@"\n' > /opt/tools/dirsearch/dirsearch \
    && chmod +x /opt/tools/sqlmap/sqlmap /opt/tools/dirsearch/dirsearch

COPY --chown=bug-bounty:bug-bounty --chmod=755 docker-entrypoint.sh /usr/local/bin/docker-entrypoint

ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]
CMD ["-l"]
