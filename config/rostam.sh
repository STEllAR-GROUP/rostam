# Copyright (c) 2015-2016 Alireza Kheirkhahan
#
# Distributed under the Boost Software License, Version 1.0. (See accompanying
# file BOOST_LICENSE_1_0.rst or copy at http://www.boost.org/LICENSE_1_0.txt)

# /etc/profile.d/rostam.sh

# System wide environment for rostam cluster, any customization goes here:


# Generating key pair to enable access through the cluster
if [ ! -f $HOME/.ssh/id_rsa ]; then
    echo "Configuring ssh for cluster access"
    install -d -m 700 $HOME/.ssh
    ssh-keygen -t rsa -f $HOME/.ssh/id_rsa -N '' > /dev/null 2>&1
    cat $HOME/.ssh/id_rsa.pub >> $HOME/.ssh/authorized_keys
    chmod 0600 $HOME/.ssh/authorized_keys
fi
