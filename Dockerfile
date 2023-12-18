FROM ghcr.io/linuxserver/baseimage-kasmvnc:ubuntujammy

LABEL maintainer="lanjelin"

ENV TITLE=CryptoWallets
ENV FEATHERVERSION=2.6.0
ENV ELECTRUMVERSION=4.4.6

RUN \
  sed -i 's|</applications>|  <application title="CryptoWallets" type="normal">\n    <maximized>no</maximized>\n  </application>\n</applications>|' /etc/xdg/openbox/rc.xml && \
  mkdir -p /app && \
  echo "**** update packages ****" && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    wget && \
  echo "**** install feather ****" && \
  apt-get install -y --no-install-recommends \
    unzip \
    libxkbcommon-x11-0 \
    libxcb-cursor0 \
    libxcb-icccm4 \
    libxcb-keysyms1 \
    libxcb-randr0 && \
  wget -q https://featherwallet.org/files/releases/linux/feather-$FEATHERVERSION-linux.zip -O /tmp/feather.zip && \
  wget -q https://raw.githubusercontent.com/feather-wallet/feather/master/utils/pubkeys/featherwallet.asc -O /tmp/featherwallet.asc && \
  wget -q https://featherwallet.org/files/releases/hashes-$FEATHERVERSION.txt -O /tmp/hashes.txt && \
  export GNUPGHOME="$(mktemp -d)" && \
  gpg --import /tmp/featherwallet.asc && \
  if ! gpg --batch --quiet --verify /tmp/hashes.txt; then \
    echo "File signature mismatch"; \
    exit 1; \
  fi && \
  sha256=$(sha256sum /tmp/feather.zip) && \
  if ! grep --quiet "${sha256%% *}" /tmp/hashes.txt; then \
    echo "SHA256 mismatch"; \
    exit 1; \
  fi && \
  unzip /tmp/feather.zip -d /tmp/ && \
  mv /tmp/feather-* /app/feather && \
  wget -q https://raw.githubusercontent.com/feather-wallet/feather/master/src/assets/images/feather.png -O /app/feather.png && \
  echo "**** install electrum ****" && \
  apt-get install -y --no-install-recommends \
    python3-pyqt5 \
    libsecp256k1-dev \
    python3-cryptography && \
  wget -q https://download.electrum.org/$ELECTRUMVERSION/Electrum-$ELECTRUMVERSION.tar.gz -O /tmp/Electrum-$ELECTRUMVERSION.tar.gz && \
  wget -q https://download.electrum.org/$ELECTRUMVERSION/Electrum-$ELECTRUMVERSION.tar.gz.asc -O /tmp/Electrum-$ELECTRUMVERSION.tar.gz.asc && \
  wget -q https://raw.githubusercontent.com/spesmilo/electrum/master/pubkeys/ThomasV.asc -O /tmp/ThomasV.asc && \
  wget -q https://raw.githubusercontent.com/spesmilo/electrum/master/pubkeys/sombernight_releasekey.asc -O /tmp/sombernight_releasekey.asc && \
  wget -q https://raw.githubusercontent.com/spesmilo/electrum/master/pubkeys/Emzy.asc -O /tmp/Emzy.asc && \
  gpg --import /tmp/ThomasV.asc && \
  gpg --import /tmp/sombernight_releasekey.asc && \
  gpg --import /tmp/Emzy.asc && \
  if ! gpg --batch --quiet --verify /tmp/Electrum-$ELECTRUMVERSION.tar.gz.asc /tmp/Electrum-$ELECTRUMVERSION.tar.gz; then \
    echo "File signature mismatch"; \
    exit 1; \
  fi && \
  tar -xf /tmp/Electrum-$ELECTRUMVERSION.tar.gz -C /tmp && \
  mv /tmp/Electrum-$ELECTRUMVERSION /app/Electrum && \
  wget -q https://raw.githubusercontent.com/spesmilo/electrum/master/electrum/gui/icons/electrum.png -O /app/electrum.png && \
  echo "**** setting permissions ****" && \
  find /app -perm 700 -exec chmod 755 {} + && \
  find /app -perm 600 -exec chmod 644 {} + && \
  echo "**** cleanup ****" && \
  rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/*

# add local files
COPY /root /

# ports and volumes
EXPOSE 3000 3001

VOLUME /config
