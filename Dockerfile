ARG OS_VER=latest


FROM centos:$OS_VER
MAINTAINER liufee job@feehi.com


#root用户密码
ARG ROOT_PASSWORD=123456
#php版本,因为php版本间配置文件模板不相同，此处的版本号只能为大于7.0以上版本
ARG PHP_VER=7.2.8
#nginx版本
ARG NGINX_VER=1.15.2
#mysql版本
ARG MYSQL_VER=5.7.23
#redis版本
ARG REDIS_VER=4.0.11
#redis密码
ARG REDIS_PASS=123456
#phpmyadmin版本
ARG PHPMYADMIN_VER=4.7.6
#mysql data目录
ARG MYSQL_DATA_DIR=/data/mysql
#mysql pid目录
ARG MYSQL_PID_DIR=/var/run/mysql
#mysql log目录
ARG MYSQL_LOG_DIR=/var/log/mysql
#mysql sock目录
ARG MYSQL_SOCK_DIR=/var/lib/mysql
#xhprof版本
ARG XHPROF_VER=1.2
#hiredis版本
ARG HIREDIS_VER=0.13.3
#swoole版本
ARG SWOOLE_VER=4.0.4
#go版本
ARG GO_VER=1.10.3
#node.js版本
ARG NODE_VER=8.11.4
#mongodb版本
ARG MONGODB_VER=4.0.1
#mongodb data目录
ARG MONGODB_DATA_DIR=/data/mongodb
#java版本
ARG JDK_VER=1.8
#maven版本
ARG MAVEN_VER=3.6.0


#映射配置文件
ADD ./etc /usr/src/etc


#基础环境配置
RUN yum install vim wget git net-tools -y \
    && yum install epel-release -y \
    && yum update -y \
    && yum -y install pcre pcre-devel zlib zlib-devel openssl openssl-devel libxml2 libxml2-devel libjpeg libjpeg-devel \
        libpng libpng-devel curl curl-devel libicu libicu-devel libmcrypt  libmcrypt-devel freetype freetype-devel \
        libmcrypt libmcrypt-devel autoconf gcc-c++ gcc make automake cmake ncurses-devel bison bison-devel\
    && yum install vixie-cron crontabs -y \
    && yum install python-setuptools -y \
    && easy_install supervisor \
    && yum install openssh-server -y \
    && echo PermitRootLogin  yes >> /etc/ssh/sshd_config \
    && echo PasswordAuthentication yes >> /etc/ssh/sshd_config \
    && echo RSAAuthentication yes >> etc/ssh/sshd_config \
    && sed -i "s/UseDNS yes/UseDNS no/" /etc/ssh/sshd_config \
    && echo "root:$ROOT_PASSWORD" | chpasswd \
    && ssh-keygen -t dsa -f /etc/ssh/ssh_host_rsa_key \
    && ssh-keygen -t rsa -f /etc/ssh/ssh_host_ecdsa_key \
    && ssh-keygen -t rsa -f /etc/ssh/ssh_host_ed25519_key \
    && yum clean all && rm -rf /var/cache/yum/*


#安装php
RUN cd /usr/src \
    && curl -o php.tar.gz http://php.net/get/php-${PHP_VER}.tar.gz/from/this/mirror -L \
    && mkdir php \
    && tar -xzvf php.tar.gz -C ./php --strip-components 1 \
    && cd php \
    && ./configure --prefix=/usr/local/php --with-config-file-path=/etc/php --enable-soap --enable-mbstring=all \
        --enable-sockets --enable-fpm --with-gd --with-freetype-dir=/usr/include/freetype2/freetype \
        --with-jpeg-dir=/usr/lib64 --with-zlib --with-iconv --enable-libxml --enable-xml  --enable-intl \
        --enable-zip --enable-pcntl --enable-bcmath --enable-maintainer-zts --with-curl --with-mcrypt --with-openssl \
        --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd \
    && make \
    && make install \
    && mkdir /etc/php \
    && cp /usr/src/php/php.ini-development /etc/php/php.ini \
    && echo $MYSQL_SOCK_DIR > /tmp/temp_mysql_sock_dir.txt && temp_mysql_sock_dir=$(sed "s/\//\\\\\//g" /tmp/temp_mysql_sock_dir.txt) && rm -rf /tmp/temp_mysql_sock_dir.txt \
    && sed -i "s/mysqli.default_socket =/mysqli.default_socket = ${temp_mysql_sock_dir}\/mysql.sock/" /etc/php/php.ini \
    && sed -i "s/pdo_mysql.default_socket=/pdo_mysql.default_socket = ${temp_mysql_sock_dir}\/mysql.sock/" /etc/php/php.ini \
    && cp /usr/src/php/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm \
    && chmod +x /etc/init.d/php-fpm \
    && cd /usr/local/php/etc \
    && cp php-fpm.conf.default php-fpm.conf \
    && sed -i "s/;daemonize = yes/daemonize = no/" php-fpm.conf \
    && cp ./php-fpm.d/www.conf.default ./php-fpm.d/www.conf \
    && sed -i "s/export PATH/PATH=\/usr\/local\/php\/bin:\$PATH\nexport PATH/" /etc/profile \
    && sed -i "s/export PATH/PATH=\/etc\/init.d:\$PATH\nexport PATH/" /etc/profile \
    && rm -rf /usr/src/php.tar.gz && rm -rf /usr/src/php \
    #php redis扩展
    && /usr/local/php/bin/pecl install redis && echo "extension=redis.so" >> /etc/php/php.ini \
    #php swoole扩展
    && cd /usr/src && curl -o hiredis.tar.gz https://github.com/redis/hiredis/archive/v${HIREDIS_VER}.tar.gz -L && mkdir hiredis && tar -xzvf hiredis.tar.gz -C ./hiredis --strip-components 1 \
    && cd hiredis && make && make install && mkdir /usr/lib/hiredis && cp libhiredis.so /usr/lib/hiredis && mkdir /usr/include/hiredis && cp hiredis.h /usr/include/hiredis \
    && echo '/usr/local/lib' >> /etc/ld.so.conf && ldconfig \
    && /usr/local/php/bin/pecl download swoole-${SWOOLE_VER} && tar -zxvf swoole-${SWOOLE_VER}.tgz && cd swoole-${SWOOLE_VER} \
    && /usr/local/php/bin/phpize && ./configure --with-php-config=/usr/local/php/bin/php-config --enable-openssl --enable-async-redis && make && make install \
    && echo "extension=swoole.so" >> /etc/php/php.ini && rm -rf /usr/src/hiredis.tar.gz && rm -rf /usr/src/hiredis && rm -rf swoole-${SWOOLE_VER}.tgz && rm -rf swoole-${SWOOLE_VER} \
    #php xhprof扩展
    && cd /usr/src \
    && curl -o xhprof.tar.gz https://github.com/longxinH/xhprof/archive/v${XHPROF_VER}.tar.gz -L \
    && tar -xvf xhprof.tar.gz \
    && cd xhprof-${XHPROF_VER}/extension \
    && /usr/local/php/bin/phpize \
    && ./configure --with-php-config=/usr/local/php/bin/php-config --enable-xhprof && make && make install \
    && mkdir -p -m 777 /tmp/xhprof \
    && echo -e "[xhprof]\nextension = xhprof.so\nxhprof.output_dir = /tmp/xhprof" >> /etc/php/php.ini \
    && mkdir /var/tools \
    && cd /usr/src/xhprof-${XHPROF_VER} \
    && mv xhprof_html /var/tools/ \
    && mv xhprof_lib /usr/local/php/lib/php \
    && sed -i "s/dirname(__FILE__) . '\/..\/xhprof_lib'/'xhprof_lib'/" /var/tools/xhprof_html/index.php \
    && sed -i "s/dirname(__FILE__) . '\/..\/xhprof_lib'/'xhprof_lib'/" /var/tools/xhprof_html/callgraph.php \
    && sed -i "s/dirname(__FILE__) . '\/..\/xhprof_lib'/'xhprof_lib'/" /var/tools/xhprof_html/typeahead.php \
    && rm -rf /usr/src/xhprof-${XHPROF_VER} && rm -rf /usr/src/xhprof.tar.gz



#安装nginx
RUN cd /usr/src \
    && curl -o nginx.tar.gz http://nginx.org/download/nginx-${NGINX_VER}.tar.gz -L \
    && mkdir nginx && tar -xzvf nginx.tar.gz -C ./nginx --strip-components 1 \
    && cd nginx \
    && ./configure --prefix=/usr/local/nginx --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log --pid-path=/var/run/nginx.pid --lock-path=/var/lock/nginx.lock \
        --user=nginx --group=nginx --with-http_ssl_module --with-http_flv_module --with-http_stub_status_module \
        --with-http_gzip_static_module --http-client-body-temp-path=/tmp/nginx/client/ \
        --http-proxy-temp-path=/tmp/nginx/proxy/ \
        --http-fastcgi-temp-path=/tmp/nginx/fcgi/ \
        --with-pcre --with-http_dav_module \
    && make && make install \
    && useradd nginx \
    && mkdir -p -m 777 /tmp/nginx \
    && echo "#!/bin/sh" > /etc/init.d/nginx \
    && echo "#description: Nginx web server." >> /etc/init.d/nginx \
    && echo -e "case \$1 in \n\
            restart): \n\
                /usr/local/nginx/sbin/nginx -s reload \n\
                ;; \n\
            stop): \n\
                /usr/local/nginx/sbin/nginx -s stop \n\
                ;; \n\
            *): \n\
                /usr/local/nginx/sbin/nginx \n\
                ;; \n\
        esac \n" >> /etc/init.d/nginx \
    && chmod +x /etc/init.d/nginx \
    #&& sed -i "3a daemon off;" /etc/nginx/nginx.conf \
    #&& sed -i "s/index  index.html index.htm;/index  index.php index.html index.htm;/" /etc/nginx/nginx.conf \
    #&& sed -i "s/# pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000/location ~ \.php\$ { \nfastcgi_pass 127.0.0.1:9000;\nfastcgi_index  index.php;\nfastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;\ninclude fastcgi_params;\n }/" /etc/nginx/nginx.conf \
    && echo "<?php phpinfo()?>" > /usr/local/nginx/html/index.php \
    && rm -rf /etc/nginx && cp -rf /usr/src/etc/nginx /etc/nginx \
    && mkdir -m 777 -p /var/log/nginx \
    && rm -rf /usr/src/nginx.tar.gz && rm -rf /usr/src/nginx



#安装mysql
RUN cd /usr/src \
    && curl -o mysql.tar.gz https://dev.mysql.com/get/Downloads/MySQL-${MYSQL_VER%.*}/mysql-boost-${MYSQL_VER}.tar.gz -L \
    && tar zxf mysql.tar.gz \
    && cd mysql-${MYSQL_VER} \
    && cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql -DWITH_BOOST=./boost -DMYSQL_DATADIR=${MYSQL_DATA_DIR} -DSYSCONFDIR=/etc -DWITH_MYISAM_STORAGE_ENGINE=1 \
        -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_MEMORY_STORAGE_ENGINE=1 -DWITH_READLINE=1 -DMYSQL_UNIX_ADDR=${MYSQL_SOCK_DIR}/mysql.sock -DMYSQL_TCP_PORT=3306 \
        -DENABLED_LOCAL_INFILE=1 -DWITH_PARTITION_STORAGE_ENGINE=1 -DEXTRA_CHARSETS=all -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DWITH_UNIT_TESTS=OFF \
    && gmake \
    && gmake install \
    && mkdir -p ${MYSQL_DATA_DIR} \
    && mkdir -m 755 -p ${MYSQL_LOG_DIR} \
    && mkdir -m 755 -p ${MYSQL_SOCK_DIR} \
    && mkdir -m 755 -p ${MYSQL_PID_DIR} \
    && echo -e "[mysqld]\ndatadir=${MYSQL_DATA_DIR}\nsocket=${MYSQL_SOCK_DIR}/mysql.sock\nsymbolic-links=0\nlog-error=${MYSQL_LOG_DIR}/mysqld.log\npid-file=${MYSQL_PID_DIR}/mysqld.pid\nuser=root\n" > /etc/my.cnf \
    && echo -e "#!/bin/sh \n\
        files=\`ls ${MYSQL_DATA_DIR}\` \n\
        if [ -z \"\$files\" ];then \n\
            if [ ! \${MYSQL_PASSWORD} ]; then \n\
                MYSQL_PASSWORD='123456' \n\
            fi \n\
            /usr/local/mysql/bin/mysqld --initialize --basedir=/usr/local/mysql --datadir=${MYSQL_DATA_DIR} > ${MYSQL_LOG_DIR}/mysqld.log 2>&1 \n\
            MYSQLOLDPASSWORD=\`awk -F \"localhost: \" '/A temporary/{print \$2}' ${MYSQL_LOG_DIR}/mysqld.log\` \n\
            /usr/local/mysql/bin/mysqld & \n\
            echo -e \"[client] \\\n  password=\"\${MYSQLOLDPASSWORD}\" \\\n user=root\" > ~/.my.cnf \n\
            sleep 8s \n\
            /usr/local/mysql/bin/mysql --connect-expired-password -e \"alter user 'root'@'localhost' identified by '\$MYSQL_PASSWORD';update mysql.user set host='%' where user='root' && host='localhost';flush privileges;\" \n\
            echo -e \"[client] \\\n  password=\"\${MYSQL_PASSWORD}\" \\\n user=root\" > ~/.my.cnf \n\
            while true \n\
            do \n\
              let \"1\" \n\
            done \n\
        else \n\
            rm -rf \${MYSQL_SOCK_DIR}/mysql.sock.lock \n\
            /usr/local/mysql/bin/mysqld \n\
        fi" > /mysql.sh \
    && chmod +x /mysql.sh \
    && sed -i "s/export PATH/PATH=\/usr\/local\/mysql\/bin:\$PATH\nexport PATH/" /etc/profile \
    && rm -rf /usr/src/mysql.tar.gz && rm -rf /usr/src/mysql-${MYSQL_VER} && rm -rf /usr/local/mysql/mysql-test \
    && rm -rf /usr/local/mysql/bin/mysql_client_test && rm -rf /usr/local/mysql/bin/mysql_client_test_embedded && rm -rf /usr/local/mysql/bin/mysql_embedded \
    && rm -rf /usr/local/mysql/bin/mysqltest && rm -rf /usr/local/mysql/bin/mysqltest_embedded && rm -rf /usr/local/mysql/lib/libmysql.a


#安装redis server
RUN cd /usr/src \
    && curl -o redis.tar.gz http://download.redis.io/releases/redis-${REDIS_VER}.tar.gz -L \
    && mkdir redis \
    && tar -xzvf redis.tar.gz -C ./redis --strip-components 1 \
    && cd redis \
    && make \
    && make install \
    && mkdir -p /usr/local/redis/bin \
    && cp ./src/redis-server /usr/local/redis/bin/ \
    && cp ./src/redis-cli /usr/local/redis/bin/ \
    && cp ./src/redis-benchmark /usr/local/redis/bin/ \
    && cp ./redis.conf /etc/redis.conf \
    && sed -i 's/bind 127.0.0.1/bind 0.0.0.0/' /etc/redis.conf \
    && sed -i "s/# requirepass foobared/requirepass ${REDIS_PASS}/" /etc/redis.conf \
    && echo -e "# description: Redis server. \n\
         case \$1 in \n\
            restart): \n\
                /usr/local/redis/bin/redis-cli -h 127.0.0.1 -p 6379 -a 123456 shutdown \n\
                /usr/local/redis/bin/redis-server /etc/redis.conf \n\
                ;; \n\
            stop): \n\
                /usr/local/redis/bin/redis-cli -h 127.0.0.1 -p 6379 -a 123456 shutdown \n\
                ;; \n\
            *): \n\
                /usr/local/redis/bin/redis-server /etc/redis.conf \n\
         esac" > /etc/init.d/redis \
    && chmod +x /etc/init.d/redis \
    && sed -i "s/export PATH/PATH=\/usr\/local\/redis\/bin:\$PATH\nexport PATH/" /etc/profile \
    && rm -rf /usr/src/redis.tar.gz && rm -rf /usr/src/redis


#安装go
RUN cd /usr/src \
    && curl -o go.tar.gz https://studygolang.com/dl/golang/go${GO_VER}.linux-amd64.tar.gz -L \
    && mkdir /usr/local/go \
    && tar -xzvf go.tar.gz -C /usr/local/go  --strip-components 1 \
    && sed -i "s/export PATH/PATH=\/usr\/local\/go\/bin:\$HOME\/go\/bin:\$PATH\nGOPATH=\$HOME\/go\nexport GOPATH\nexport PATH/" /etc/profile \
    && sed -i 's/export PATH USER/export PATH USER GOPATH/' /etc/redis.conf \
    && rm -rf go.tar.gz


#安装node.js
RUN curl -o node.tar.xz https://nodejs.org/dist/v${NODE_VER}/node-v${NODE_VER}-linux-x64.tar.xz && tar -xvf node.tar.xz \
    && mv node-v${NODE_VER}-linux-x64 /usr/local/node \
    && sed -i "s/export PATH/PATH=\/usr\/local\/node\/bin:\$PATH\nexport PATH/" /etc/profile \
    && source /etc/profile && /usr/local/node/bin/npm install -g cnpm --registry=https://registry.npm.taobao.org \
    && rm -rf node.tar.gz


#安装mongodb
RUN curl -o mongodb.tar.gz https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-${MONGODB_VER}.tgz && tar -xvf mongodb.tar.gz \
    && mkdir -p ${MONGODB_DATA_DIR} && mv mongodb-linux-x86_64-${MONGODB_VER} /usr/local/mongodb \
    && sed -i "s/export PATH/PATH=\/usr\/local\/mongodb\/bin:\$PATH\nexport PATH/" /etc/profile  \
    && mkdir -p /var/log/mongodb \
    && echo -e "fork=false\njournal=true\nquiet=false\nlogpath=/var/log/mongodb/mongodb.log\nlogappend=true\nport=27017\ndbpath=${MONGODB_DATA}\nbind_ip=0.0.0.0" > /etc/mongod.conf \
    && rm -rf mongodb.tar.gz


#安装Java JDK
RUN cd /usr/src \
    && curl -o jdk.tar.gz http://d.feehi.com/jdk-${JDK_VER} -L \
    && mkdir -p /usr/local/java && tar -xzvf jdk.tar.gz -C /usr/local/java --strip-components 1 \
    && sed -i "s/export PATH/PATH=\/usr\/local\/java\/bin:\$PATH\nJAVA_HOME=\/usr\/local\/java\nJRE_HOME=\/usr\/local\/java\/jre\nCLASSPATH=\.:\$JAVA_HOME\/lib:\$JRE_HOME\/lib\nexport JAVA_HOME JRE_HOME CLASSPATH\nexport PATH/" /etc/profile \
    && rm -rf jdk.tar.gz


#安装maven
RUN cd /usr/src && curl -o maven.tar.gz http://mirrors.tuna.tsinghua.edu.cn/apache/maven/maven-3/${MAVEN_VER}/binaries/apache-maven-${MAVEN_VER}-bin.tar.gz -L \
    && tar -xvf maven.tar.gz && mv apache-maven-${MAVEN_VER} /usr/local/maven \
    && sed -i "s/<mirrors>/<mirrors><mirror><id>nexus-aliyun<\/id><mirrorOf>central<\/mirrorOf><name>Nexus aliyun<\/name><url>http:\/\/maven.aliyun.com\/nexus\/content\/groups\/public<\/url><\/mirror>/" /usr/local/maven/conf/settings.xml \
    && sed -i "s/export PATH/MAVEN_HOME=\/usr\/local\/maven \nexport MAVEN_HOME\nPATH=\/usr\/local\/maven\/bin:\$PATH\nexport PATH/" /etc/profile \
    && rm -rf maven.tar.gz


#安装必要的服务
RUN cd /usr/src \
    && /usr/local/php/bin/php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && /usr/local/php/bin/php composer-setup.php  --install-dir=/usr/local/bin --filename=composer \
    && rm -rf composer-setup.php \
    && /usr/local/php/bin/php /usr/local/bin/composer config -g repo.packagist composer https://packagist.laravel-china.org \
    && /usr/local/php/bin/php /usr/local/bin/composer create-project -s dev erik-dubbelboer/php-redis-admin /var/tools/phpredisadmin -vvv \
    && cd /var/tools/phpredisadmin && cp includes/config.sample.inc.php includes/config.inc.php \
    && sed -i "s/=> 'local server'/=> 'feehi server'/" includes/config.inc.php \
    && sed -i "s/\/\/'auth' => 'redispasswordhere'/'auth' => '${REDIS_PASS}'/" includes/config.inc.php \
    && sed -i "s/'scansize' => 1000/'scansize' => 1000,\n'login' => array('admin' => array('password' => '${REDIS_PASS}')),/" includes/config.inc.php \
    && rm -rf /root/.composer/cache/ \
    && cd /usr/src \
    && curl -o phpmyadmin.tar.gz https://files.phpmyadmin.net/phpMyAdmin/${PHPMYADMIN_VER}/phpMyAdmin-${PHPMYADMIN_VER}-all-languages.tar.gz \
    && mkdir -p /var/tools/phpmyadmin \
    && tar -xzvf phpmyadmin.tar.gz -C /var/tools/phpmyadmin --strip-components 1 \
    && rm -rf /usr/src/phpmyadmin.tar.gz


#环境变量设置
ENV PATH /usr/local/php/bin:/etc/init.d:/usr/local/mysql/bin:/usr/local/redis/bin:/usr/local/go/bin:/root/go/bin:/usr/local/node/bin:/usr/local/mongodb/bin:usr/local/java/bin:/usr/local/maven/bin:$PATH
ENV GOPATH /root/go
ENV JAVA_HOME /usr/local/java
ENV JRE_HOME /usr/local/java/jre
ENV CLASSPATH .:$JAVA_HOME/lib:/$JRE_HOME/lib:$CLASSPATH
ENV MAVEN_HOME /usr/local/maven


#服务器基础设置
RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo 'Asia/Shanghai' > /etc/timezonesource \
    && source /etc/profile \
    &&echo [supervisord] > /etc/supervisord.conf \
    && echo nodaemon=true >> /etc/supervisord.conf \
    && echo user=root >> /etc/supervisord.conf \
    \
    && echo [program:sshd] >> /etc/supervisord.conf \
    && echo command=/usr/sbin/sshd -D >> /etc/supervisord.conf \
    \
    && echo [program:nginx] >> /etc/supervisord.conf \
    && echo command=/usr/local/nginx/sbin/nginx >> /etc/supervisord.conf \
    \
    && echo [program:php-fpm] >> /etc/supervisord.conf \
    && echo command=/usr/local/php/sbin/php-fpm >> /etc/supervisord.conf \
    \
    && echo [program:mysqld] >> /etc/supervisord.conf \
    && echo command=/bin/sh /mysql.sh >> /etc/supervisord.conf \
    \
    && echo [program:redis] >> /etc/supervisord.conf \
    && echo command=/usr/local/redis/bin/redis-server /etc/redis.conf >> /etc/supervisord.conf \
    \
    && echo [program:mongodb] >> /etc/supervisord.conf \
    && echo command=/usr/local/mongodb/bin/mongod -f /etc/mongod.conf >> /etc/supervisord.conf \
    \
    && echo [program:crond] >> /etc/supervisord.conf \
    && echo command=/usr/sbin/crond -n >> /etc/supervisord.conf


EXPOSE 80 3306 6379 27017


CMD ["/usr/bin/supervisord"]
