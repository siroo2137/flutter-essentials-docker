FROM openjdk:8

MAINTAINER Niklas Lehnfeld <niklas@lehnfeld.net>

SHELL ["/bin/bash", "--login", "-c"]

ENV LANG en_US.UTF-8

# Update & Install basics
RUN apt-get update
RUN yes | apt-get install \
  locales \
  libstdc++6 \
  lib32stdc++6 \
  libglu1-mesa \
  build-essential \
  ruby-full \
  rubygems

# Install nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

# Install latest LTS node
RUN nvm install --lts

# Install fastlane
RUN gem install fastlane -NV \
  && fastlane --version

# Install firebase cli
RUN npm install -g firebase-tools \
  && firebase --version


# Install Flutter

## Setting variables for android download
ARG ANDROID_SDK_TOOLS="4333796"
ENV ANDROID_SDK_URL="https://dl.google.com/android/repository/sdk-tools-linux-${ANDROID_SDK_TOOLS}.zip"
ENV ANDROID_SDK_ROOT="/usr/local/android"
ENV ANDROID_SDK_ARCHIVE="/tmp/android.zip"

## Download Android SDK
RUN curl --output "${ANDROID_SDK_ARCHIVE}" --url "${ANDROID_SDK_URL}" \
  && unzip -q -d "${ANDROID_SDK_ROOT}" "${ANDROID_SDK_ARCHIVE}" \
  && rm "${ANDROID_SDK_ARCHIVE}"

## Download tools and accept 
RUN yes "y" | ${ANDROID_SDK_ROOT}/tools/bin/sdkmanager "tools" \
  "platform-tools" \
  "extras;android;m2repository" \
  "extras;google;m2repository" \
  "patcher;v4" 

## Download and accept platform-tools 
ARG ANDROID_SDK_MAJOR=28
RUN yes "y" | ${ANDROID_SDK_ROOT}/tools/bin/sdkmanager "platforms;android-${ANDROID_SDK_MAJOR}" 

## Download and accept build-tools
ARG ANDROID_SDK_MINOR=0
ARG ANDROID_SDK_PATCH=3
ARG ANDROID_SDK_VERSION="${ANDROID_SDK_MAJOR}.${ANDROID_SDK_MINOR}.${ANDROID_SDK_PATCH}"
RUN yes "y" | ${ANDROID_SDK_ROOT}/tools/bin/sdkmanager "build-tools;${ANDROID_SDK_VERSION}" 

## Setting Flutter Variables
ARG FLUTTER_SDK_CHANNEL="stable"
ARG FLUTTER_SDK_VERSION="3.24.4"
ENV FLUTTER_ROOT="/usr/local/flutter"
ENV FLUTTER_SDK_ARCHIVE="/tmp/flutter.tar.xz"
ENV FLUTTER_SDK_URL="https://storage.googleapis.com/flutter_infra/releases/stable/linux/flutter_linux_${FLUTTER_SDK_VERSION}-${FLUTTER_SDK_CHANNEL}.tar.xz"

## Download Flutter SDK
RUN curl --output "${FLUTTER_SDK_ARCHIVE}" --url "${FLUTTER_SDK_URL}" \
  && tar --extract --file="${FLUTTER_SDK_ARCHIVE}" --directory=$(dirname ${FLUTTER_ROOT}) \
  && rm "${FLUTTER_SDK_ARCHIVE}" 

## Setting Path and Environment variables

### Add android executables to path (example: adb avdmanager)
ENV PATH="${PATH}:${ANDROID_SDK_ROOT}/tools/bin:${ANDROID_SDK_ROOT}/platform-tools:${ANDROID_SDK_ROOT}/build-toos/${ANDROID_SDK_VERSION}"

### Add flutter executable to path
ENV PATH="${PATH}:${FLUTTER_ROOT}/bin"

### Make it easy to use other Dart and Pub packages
ENV DART_SDK="${FLUTTER_ROOT}/bin/cache/dart-sdk"
ENV PUB_CACHE=${FLUTTER_ROOT}/.pub-cache
ENV PATH="${PATH}:${DART_SDK}/bin:${PUB_CACHE}/bin"

## Accepting all android licenses
RUN yes "y" | ${FLUTTER_ROOT}/bin/flutter doctor --android-licenses \
  && ${FLUTTER_ROOT}/bin/flutter doctor

## Switch to flutters master channel
RUN flutter channel master

## Clear stuff
RUN locale-gen en_US ${LANG} \
  && dpkg-reconfigure locales \
  && apt-get autoremove -y \
  && rm -rf /var/lib/apt/lists/*
