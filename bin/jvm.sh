#!/bin/zsh

# Not depend on other scripts

mkdir -p $HOME/jvm
curl \
  -L https://download.oracle.com/java/${JVM_VERSION}/latest/jdk-${JVM_VERSION}_macos-aarch64_bin.tar.gz \
  -o $HOME/jvm/jdk-${JVM_VERSION}.tar.gz
tar -zxvf $HOME/jvm/jdk-${JVM_VERSION}.tar.gz
mv ./jdk-${JVM_VERSION}*.jdk $HOME/jvm
rm -rf $HOME/jvm/jdk-${JVM_VERSION}.tar.gz
