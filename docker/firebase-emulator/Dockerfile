# Image Firebase Emulator Suite untuk development lokal dan CI.
# Satu image dipakai dua service di docker-compose.yml (auth dan storage), dipilih lewat
# FIREBASE_EMULATORS. firebase.json dan storage.rules di-mount saat runtime, jadi mengubah
# aturan tidak perlu build ulang image.
FROM node:24-trixie-slim

# Java 21+ dibutuhkan runtime rules Storage Emulator; curl untuk healthcheck.
RUN apt-get update \
  && apt-get install -y --no-install-recommends openjdk-21-jre-headless curl \
  && rm -rf /var/lib/apt/lists/*

ARG FIREBASE_TOOLS_VERSION=15.32.0
RUN npm install -g firebase-tools@${FIREBASE_TOOLS_VERSION} \
  && npm cache clean --force

# Unduh jar runtime rules Storage saat build agar container tidak mengunduh setiap start.
RUN firebase setup:emulators:storage

WORKDIR /firebase

ENV FIREBASE_EMULATORS=auth
ENV FIREBASE_PROJECT_ID=demo-template

EXPOSE 9099 9199
CMD ["sh", "-c", "exec firebase emulators:start --only \"$FIREBASE_EMULATORS\" --project \"$FIREBASE_PROJECT_ID\""]
