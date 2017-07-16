FROM centos:latest
MAINTAINER liufee job@feehi.com


#root用户密码
ENV ROOT_PASSWORD=123456
#php版本
ENV PHP_VER=7.1.7
#nginx版本
ENV NGINX_VER=1.12.0
#redis版本
ENV REDIS_VER=3.2.9
#redis密码
ENV REDIS_PASS=123456


#修改dns地址
RUN echo nameserver 223.5.5.5 > /etc/resolv.conf


#更换yum源
RUN mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup && curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo


#安装基础工具
RUN yum install vim wget git net-tools -y


#安装supervisor
RUN  yum install python-setuptools -y && easy_install supervisor


#安装openssh server，设置root密码为变量ROOT_PASSWORD
RUN yum install openssh-server -y
RUN echo PermitRootLogin  yes >> /etc/ssh/sshd_config\
    && echo PasswordAuthentication yes >> /etc/ssh/sshd_config\
    && echo RSAAuthentication yes >> etc/ssh/sshd_config\
    && sed -i "129s/UseDNS yes/UseDNS no/g" /etc/ssh/sshd_config\
    && echo "root:$ROOT_PASSWORD" | chpasswd\
    && ssh-keygen -t dsa -f /etc/ssh/ssh_host_rsa_key\
    && ssh-keygen -t rsa -f /etc/ssh/ssh_host_ecdsa_key\
    && ssh-keygen -t rsa -f /etc/ssh/ssh_host_ed25519_key


#安装php
RUN yum install epel-release -y && yum update -y\
    && yum -y install pcre pcre-devel zlib zlib-devel openssl openssl-devel libxml2 libxml2-devel libjpeg libjpeg-devel libpng libpng-devel curl curl-devel libicu libicu-devel libmcrypt  libmcrypt-devel freetype freetype-devel libmcrypt libmcrypt-devel autoconf gcc-c++
WORKDIR /usr/src
RUN wget -O php.tar.gz "http://php.net/get/php-${PHP_VER}.tar.gz/from/this/mirror" && mkdir php && tar -xzvf php.tar.gz -C ./php --strip-components 1
WORKDIR php
RUN ./configure --prefix=/usr/local/php --with-config-file-path=/etc/php --enable-soap --enable-mbstring=all --enable-sockets --enable-fpm --with-gd --with-freetype-dir=/usr/include/freetype2/freetype --with-jpeg-dir=/usr/lib64 --with-zlib --with-iconv --enable-libxml --enable-xml  --enable-intl --enable-zip --enable-pcntl --enable-maintainer-zts --with-curl --with-mcrypt --with-openssl --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd \
    && make && make install \
    && mkdir /etc/php \
    && cp /usr/src/php/php.ini-development /etc/php/php.ini \
    && cp /usr/src/php/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm && chmod +x /etc/init.d/php-fpm
WORKDIR /usr/local/php/etc
RUN cp php-fpm.conf.default php-fpm.conf \
    && sed -i "/;daemonize = yes/s/;daemonize = yes/daemonize = no/g" php-fpm.conf \
    && cp ./php-fpm.d/www.conf.default ./php-fpm.d/www.conf \
    && sed -i "52a PATH=/usr/local/php/bin:$PATH" /etc/profile \
    && sed -i "52a PATH=/etc/init.d:$PATH" /etc/profile


#安装nginx
WORKDIR /usr/src
RUN wget -O nginx.tar.gz http://nginx.org/download/nginx-${NGINX_VER}.tar.gz -O nginx.tar.gz && mkdir nginx && tar -zxvf nginx.tar.gz -C ./nginx --strip-components 1
WORKDIR nginx
RUN ./configure --prefix=/usr/local/nginx --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/var/run/nginx.pid --lock-path=/var/lock/nginx.lock --user=nginx --group=nginx --with-http_ssl_module --with-http_flv_module --with-http_stub_status_module --with-http_gzip_static_module --http-client-body-temp-path=/tmp/nginx/client/ --http-proxy-temp-path=/tmp/nginx/proxy/ --http-fastcgi-temp-path=/tmp/nginx/fcgi/ --with-pcre --with-http_dav_module \
     && make && make install \
     && useradd nginx \
     && mkdir -p -m 777 /tmp/nginx \
     && echo "#!/bin/sh" > /etc/init.d/nginx \
     && echo "# description: Nginx web server." >> /etc/init.d/nginx \
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
     && sed -i "64a         }" /etc/nginx/nginx.conf \
     && sed -i "64a             include        fastcgi_params;" /etc/nginx/nginx.conf \
     && sed -i "64a             fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;" /etc/nginx/nginx.conf \
     && sed -i "64a             fastcgi_index  index.php;" /etc/nginx/nginx.conf \
     && sed -i "64a             fastcgi_pass   127.0.0.1:9000;" /etc/nginx/nginx.conf \
     && sed -i "64a             root           html;" /etc/nginx/nginx.conf \
     && sed -i "64a             location ~ \.php$ {" /etc/nginx/nginx.conf \
     && sed -i "3a daemon off;" /etc/nginx/nginx.conf \
     && echo "<?php phpinfo()?>" > /usr/local/nginx/html/index.php \
     && sed -i '45s/index  index.html index.htm;/index  index.php index.html index.htm;/g' /etc/nginx/nginx.conf


#安装mysql
RUN curl -o mysql-server.rpm https://repo.mysql.com//mysql57-community-release-el7-11.noarch.rpm
RUN rpm -ivh mysql-server.rpm
RUN /usr/bin/yum install mysql-community-server -y
VOLUME ['/mysql']
RUN sed -i "/datadir=/s/\/var\/lib\/mysql/\/mysql/g" /etc/my.cnf && echo "user=root" >> /etc/my.cnf
RUN echo -e "#!/bin/sh \n\
    files=\`ls /mysql\` \n\
    if [ -z \"\$files\" ];then \n\
        if [ ! \${MYSQL_PASSWORD} ]; then \n\
            MYSQL_PASSWORD='123456' \n\
        fi \n\
        /usr/sbin/mysqld --initialize \n\
        MYSQLOLDPASSWORD=\`awk -F \"localhost: \" '/A temporary/{print \$2}' /var/log/mysqld.log\` \n\
        /usr/sbin/mysqld & \n\
        echo -e \"[client] \\\n  password=\"\${MYSQLOLDPASSWORD}\" \\\n user=root\" > ~/.my.cnf \n\
        sleep 5s \n\
        /usr/bin/mysql --connect-expired-password -e \"set password=password('\$MYSQL_PASSWORD');update mysql.user set host='%' where user='root' && host='localhost';flush privileges;\" \n\
        echo -e \"[client] \\\n  password=\"\${MYSQL_PASSWORD}\" \\\n user=root\" > ~/.my.cnf \n\
    else \n\
        /usr/sbin/mysqld \n\
    fi" > /mysql.sh
RUN chmod +x /mysql.sh


#安装redis server
WORKDIR /usr/src
RUN wget -O redis.tar.gz http://download.redis.io/releases/redis-${REDIS_VER}.tar.gz && mkdir redis && tar -xzvf redis.tar.gz -C ./redis --strip-components 1
WORKDIR /usr/src/redis
RUN make \
    && make install \
    && mkdir -p /usr/local/redis/bin \
    && cp ./src/redis-server /usr/local/redis/bin/ \
    && cp ./src/redis-cli /usr/local/redis/bin/ \
    && cp ./src/redis-benchmark /usr/local/redis/bin/ \
    && cp ./redis.conf /etc/redis.conf \
    && sed -i '61s/127.0.0.1/0.0.0.0/g' /etc/redis.conf \
    && sed -i '128s/no/yes/g' /etc/redis.conf \
    && sed -i "480s/# requirepass foobared/requirepass ${REDIS_PASS}/g" /etc/redis.conf \
    && echo -e "# description: Redis web server. \n\
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
    && chmod +x /etc/init.d/redis


#安装php redis扩展
RUN /usr/local/php/bin/pecl install redis && echo "extension=redis.so" >> /etc/php/php.ini


#安装必要的服务
RUN yum install vixie-cron crontabs -y


#配置supervisor
RUN echo [supervisord] > /etc/supervisord.conf \
    && echo nodaemon=true >> /etc/supervisord.conf \
    \
    && echo [program:sshd] >> /etc/supervisord.conf \
    && echo command=/usr/sbin/sshd -D >> /etc/supervisord.conf \
    \
    && echo [program:nginx] >> /etc/supervisord.conf \
    && echo command=/etc/init.d/nginx start >> /etc/supervisord.conf \
    \
    && echo [program:php-fpm] >> /etc/supervisord.conf \
    && echo command=/etc/init.d/php-fpm start >> /etc/supervisord.conf \
    \
    && echo [program:mysqld] >> /etc/supervisord.conf \
    && echo command=/bin/sh /mysql.sh >> /etc/supervisord.conf \
    \
    && echo [program:redis] >> /etc/supervisord.conf \
    && echo command=/usr/local/redis/bin/redis-server /etc/redis.conf >> /etc/supervisord.conf \
    \
    && echo [program:crond] >> /etc/supervisord.conf \
    && echo command=/usr/sbin/crond -n >> /etc/supervisord.conf


RUN source /etc/profile


EXPOSE 80 3306 6379


CMD ["/usr/bin/supervisord"]
