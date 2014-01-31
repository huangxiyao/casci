GitLab Installation Which Requires ROOT Access
==============================================

Root access is needed to install libraries required for building git, redis,
python 2.5+, ruby 2.0.0. The application will run as "casfw" user in /opt/casfw/gitlab. 
The libraries are built and installed into /opt/casfw/gitlab/local directory.

The source installation document is available at the below location and instructions
have been adapted to work on NGDC RHEL5 server.

https://github.com/gitlabhq/gitlabhq/blob/master/doc/install/installation.md


Packages / Dependencies
-----------------------

Run as *root*:

    yum install \
    curl.x86_64 \
    curl-devel.x86_64 \
    gdbm-devel.x86_64 \
    libicu-devel.x86_64 \
    ncurses-devel.x86_64 \
    readline-devel.x86_64 \
    openssl-devel.x86_64 \
    libxml2-devel.x86_64 \
    libxslt-devel.x86_64 \
    logrotate.x86_64 \
    zlib-devel.x86_64 \
    gcc.x86_64 \
    gcc-c++.x86_64 \
    expat-devel.x86_64 \
    mysql.x86_64 \
    mysql-devel.x86_64


Missing Libraries
-----------------

The libraries below are either not available in RedHat repos, or the versions available
are too old. The libraries are installed to /usr/local.


Run as *root*:

    mkdir /tmp/build
    
    cd /tmp/build
    curl -O -x web-proxy.corp.hp.com:8088 ftp://sourceware.org/pub/libffi/libffi-3.0.13.tar.gz
    tar zxf libffi-3.0.13.tar.gz
    cd libffi-3.0.13
    ./configure --prefix=/usr/local
    make
    make check
    make install
    
    cd /tmp/build
    curl -O -x web-proxy.corp.hp.com:8088 http://pyyaml.org/download/libyaml/yaml-0.1.4.tar.gz
    tar zxf yaml-0.1.4.tar.gz
    cd yaml-0.1.4
    ./configure --prefix=/usr/local
    make
    make install
    
    cd /tmp/build
    curl -O -x web-proxy.corp.hp.com:8088 http://download.icu-project.org/files/icu4c/52.1/icu4c-52_1-src.tgz
    tar zxf icu4c-52_1-src.tgz
    cd icu/source
    CFLAGS="-O2" ./configure --prefix=/usr/local --with-data-packaging=files --enable-shared --enable-static --disable-samples
    make
    make install
    chmod -R a+rX /usr/local/include/
    
    cd
    rm -rf /tmp/build


Environment Setup
-----------------

Run as *casfw*:

    export http{,s}_proxy=web-proxy.corp.hp.com:8088
    export INSTALL_DIR=/opt/casfw/gitlab
    export DEPS_DIR=$INSTALL_DIR/local
    export BUILD_DIR=$INSTALL_DIR/build
    export PATH=$DEPS_DIR/bin:$PATH
    export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
    mkdir -p $DEPS_DIR $BUILD_DIR
    unset ARCH


Redis
-----

Run as *casfw*":

    cd $BUILD_DIR
    curl -O --progress http://download.redis.io/releases/redis-2.8.4.tar.gz
    tar zxf redis-2.8.4.tar.gz
    cd redis-2.8.4
    make
    make install PREFIX=$DEPS_DIR
    cd $BUILD_DIR
    rm -rf $BUILD_DIR/redis-2.8.4


Python 2.5+
-----------

Run as *casfw*:

    cd $BUILD_DIR
    curl -O http://www.python.org/ftp/python/2.7.6/Python-2.7.6.tgz
    tar zxf Python-2.7.6.tgz
    cd Python-2.7.6
    ./configure --prefix=$DEPS_DIR
    make
    make test
    make install
    cd $BUILD_DIR
    rm -rf Python-2.7.6

Note: When running `make test` the following test fails: test_urllib


Git
---

Run as *casfw*":

    cd $BUILD_DIR
    curl --progress -O https://git-core.googlecode.com/files/git-1.8.5.3.tar.gz
    tar zxf git-1.8.5.3.tar.gz
    cd git-1.8.5.3
    ./configure --prefix=$DEPS_DIR
    make
    make install
    cd $BUILD_DIR
    rm -rf $BUILD_DIR/git-1.8.5.3


Ruby and Bundler
----------------

Run as *casfw*:

    cd $BUILD_DIR
    curl -x $http_proxy --progress -O ftp://ftp.ruby-lang.org/pub/ruby/2.0/ruby-2.0.0-p353.tar.gz
    tar zxf ruby-2.0.0-p353.tar.gz
    cd ruby-2.0.0-p353
    ./configure --disable-install-rdoc --prefix=$DEPS_DIR
    make
    make install
    cd $BUILD_DIR
    rm -rf $BUILD_DIR/ruby-2.0.0-p353
    
    gem install bundler --no-ri --no-rdoc


GitLab Shell
------------

Run as *casfw*:

    cd $INSTALL_DIR
    git clone https://github.com/gitlabhq/gitlab-shell.git -b v1.8.0
    cd gitlab-shell
    cp config.yml.example config.yml


Edit config.yml. The diff is below:

    $ diff config.yml.example config.yml
    2c2
    < user: git
    ---
    > user: casfw
    18c18
    < repos_path: "/home/git/repositories"
    ---
    > repos_path: "/opt/casfw/gitlab/repositories"
    21c21
    < auth_file: "/home/git/.ssh/authorized_keys"
    ---
    > auth_file: "/opt/casfw/gitlab/ssh/authorized_keys"
    25c25
    <   bin: /usr/bin/redis-cli
    ---
    >   bin: /opt/casfw/gitlab/local/bin/redis-cli


Run as *casfw*:

    ./bin/install


Database
--------

Use MySQL database provided by GDS.

Ensure the user has the appropriate privileges:

    GRANT SELECT, LOCK TABLES, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER ON `CASCI_GITLB_DEV`.* TO 'CASCI_GITLB_DEV'@'localhost'


GitLab
------

Run as *casfw*:

    cd $INSTALL_DIR
    git clone https://github.com/gitlabhq/gitlabhq.git -b 6-4-stable gitlab
    cd gitlab
    cp config/gitlab.yml.example config/gitlab.yml


Edit config/gitlab.yml. The diff is below:

    $ diff config/gitlab.yml.example config/gitlab.yml
    18,20c18,20
    <     host: localhost
    <     port: 80
    <     https: false
    ---
    >     host: code1-itg.corp.hp.com
    >     port: 443
    >     https: true
    38c38
    <     email_from: gitlab@localhost
    ---
    >     email_from: NOREPLY@hp.com
    41c41
    <     support_email: support@localhost
    ---
    >     support_email: slawomir.zachcial@hp.com
    168c168
    <     path: /home/git/gitlab-satellites/
    ---
    >     path: /opt/casfw/gitlab/gitlab-satellites/
    177c177
    <     path: /home/git/gitlab-shell/
    ---
    >     path: /opt/casfw/gitlab/gitlab-shell/
    180,181c180,181
    <     repos_path: /home/git/repositories/
    <     hooks_path: /home/git/gitlab-shell/hooks/
    ---
    >     repos_path: /opt/casfw/gitlab/repositories/
    >     hooks_path: /opt/casfw/gitlab/gitlab-shell/hooks/
    194c194
    <     bin_path: /usr/bin/git
    ---
    >     bin_path: /opt/casfw/gitlab/local/bin/git


Run as *casfw*:

    mkdir $INSTALL_DIR/gitlab-satellites
    mkdir tmp/pids/
    mkdir tmp/sockets/
    mkdir public/uploads
    cp config/unicorn.rb.example config/unicorn.rb


Edit config/unicorn.rb. The diff is below:

    $ diff config/unicorn.rb.example config/unicorn.rb
    35c35
    < working_directory "/home/git/gitlab" # available in 0.94.0+
    ---
    > working_directory "/opt/casfw/gitlab/gitlab" # available in 0.94.0+
    39c39
    < listen "/home/git/gitlab/tmp/sockets/gitlab.socket", :backlog => 64
    ---
    > listen "/opt/casfw/gitlab/gitlab/tmp/sockets/gitlab.socket", :backlog => 64
    46c46
    < pid "/home/git/gitlab/tmp/pids/unicorn.pid"
    ---
    > pid "/opt/casfw/gitlab/gitlab/tmp/pids/unicorn.pid"
    51,52c51,52
    < stderr_path "/home/git/gitlab/log/unicorn.stderr.log"
    < stdout_path "/home/git/gitlab/log/unicorn.stdout.log"
    ---
    > stderr_path "/opt/casfw/gitlab/gitlab/log/unicorn.stderr.log"
    > stdout_path "/opt/casfw/gitlab/gitlab/log/unicorn.stdout.log"


Run as *casfw*:

    cp config/initializers/rack_attack.rb.example config/initializers/rack_attack.rb
    git config --global user.name "GitLab"
    git config --global user.email "gitlab@code1-itg.corp.hp.com"
    git config --global core.autocrlf input
    cp config/database.yml.mysql config/database.yml
    chmod o-rwx config/database.yml


Edit config/database.yml. The diff is below:

    $ diff config/database.yml.mysql config/database.yml
    8c8
    <   database: gitlabhq_production
    ---
    >   database: CASCI_GITLB_DEV
    10,12c10,13
    <   username: git
    <   password: "secure password"
    <   # host: localhost
    ---
    >   username: CASCI_GITLB_DEV
    >   password: "GitLab_2014"
    >   host: g4t4758.houston.hp.com
    >   port: 1531


Install Gems
------------

Run as *casfw*

    cd $INSTALL_DIR/gitlab
    bundle install --deployment --without development test postgres aws


