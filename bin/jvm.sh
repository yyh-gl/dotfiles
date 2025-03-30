#!/bin/zsh

# Not depend on other scripts

curl \
  -L https://download.oracle.com/java/${JVM_VERSION}/latest/jdk-${JVM_VERSION}_macos-aarch64_bin.tar.gz \
  -o $HOME/jvm/jdk-${JVM_VERSION}
