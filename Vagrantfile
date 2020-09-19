# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  config.vm.box = "alpine/alpine64"

  config.vm.provision "shell", inline: <<-SHELL
    sudo apk add --no-cache file
    sudo apk add --no-cache musl\>1.1.20 --repository http://dl-cdn.alpinelinux.org/alpine/edge/main
    sudo apk --update add imagemagick findutils
  SHELL
end
