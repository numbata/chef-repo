maintainer       "Andrey Subbota"
maintainer_email "subbota@gmail.com"
license          "Apache 2.0"
description      "Setup vagrant boxes"
version          "0.0.2"

depends 'iptables'
depends 'rvm'
depends 'vagrant'

recipe "vagrant_boxes", "Setup vagrant boxes"
