FROM centos:latest
MAINTAINER liufee job@feehi.com


#修改dns地址
RUN echo nameserver 114.114.114.114 > /etc/resolv.conf


#更换yum源
RUN mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
RUN curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo


#安装基础工具
RUN yum install vim wget git net-tools -y



#安装supervisor
RUN  yum install python-setuptools -y
RUN easy_install supervisor


#安装openssh server，设置root密码为123456
RUN yum install openssh-server -y
RUN echo PermitRootLogin  yes >> /etc/ssh/sshd_config
RUN echo PasswordAuthentication yes >> /etc/ssh/sshd_config
RUN echo RSAAuthentication yes >> etc/ssh/sshd_config
RUN echo "root:123456" | chpasswd
RUN ssh-keygen -t dsa -f /etc/ssh/ssh_host_rsa_key
RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_ecdsa_key
RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_ed25519_key


#安装php
RUN yum install epel-release -y
RUN yum update -y
RUN yum -y install pcre pcre-devel zlib zlib-devel openssl openssl-devel libxml2 libxml2-devel libjpeg libjpeg-devel libpng libpng-devel curl curl-devel libicu libicu-devel libmcrypt  libmcrypt-devel freetype freetype-devel libmcrypt libmcrypt-devel autoconf gcc-c++
WORKDIR /usr/src
RUN wget http://php.net/get/php-7.1.7.tar.gz/from/this/mirror
RUN tar -xvf mirror
WORKDIR php-7.1.7
RUN ./configure --prefix=/usr/local/php --with-config-file-path=/etc/php --enable-soap --enable-mbstring=all --enable-sockets --enable-fpm --with-gd --with-freetype-dir=/usr/include/freetype2/freetype --with-jpeg-dir=/usr/lib64 --with-zlib --with-iconv --enable-libxml --enable-xml  --enable-intl --enable-zip --with-curl --with-mcrypt --with-openssl --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd
RUN make && make install
RUN cp /usr/src/php-7.1.7/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
RUN chmod +x /etc/init.d/php-fpm
WORKDIR /usr/local/php/etc
RUN cp php-fpm.conf.default php-fpm.conf
RUN cp ./php-fpm.d/www.conf.default ./php-fpm.d/www.conf
RUN sed -i "52a PATH=/usr/local/php/bin:$PATH" /etc/profile
RUN sed -i "52a PATH=/etc/init.d:$PATH" /etc/profile


#安装nginx
WORKDIR /usr/src
RUN wget http://nginx.org/download/nginx-1.12.0.tar.gz -O nginx.tar.gz
RUN tar -xvf nginx.tar.gz
WORKDIR /usr/src/nginx-1.12.0
RUN ./configure --prefix=/usr/local/nginx --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/var/run/nginx.pid --lock-path=/var/lock/nginx.lock --user=nginx --group=nginx --with-http_ssl_module --with-http_flv_module --with-http_stub_status_module --with-http_gzip_static_module --http-client-body-temp-path=/tmp/nginx/client/ --http-proxy-temp-path=/tmp/nginx/proxy/ --http-fastcgi-temp-path=/tmp/nginx/fcgi/ --with-pcre --with-http_dav_module
RUN make && make install
RUN useradd nginx
RUN mkdir -p -m 777 /tmp/nginx
RUN echo "#!/bin/sh" > /etc/init.d/nginx
RUN echo "# description: Nginx web server." >> /etc/init.d/nginx
RUN echo -e "case \$1 in \n\
            restart): \n\
                /usr/local/nginx/sbin/nginx -s reload \n\
                ;; \n\
            stop): \n\
                /usr/local/nginx/sbin/nginx -s stop \n\
                ;; \n\
            *): \n\
                /usr/local/nginx/sbin/nginx \n\
                ;; \n\
        esac \n" >> /etc/init.d/nginx
RUN chmod +x /etc/init.d/nginx
RUN sed -i "64a         }" /etc/nginx/nginx.conf
RUN sed -i "64a             include        fastcgi_params;" /etc/nginx/nginx.conf
RUN sed -i "64a             fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;" /etc/nginx/nginx.conf
RUN sed -i "64a             fastcgi_index  index.php;" /etc/nginx/nginx.conf
RUN sed -i "64a             fastcgi_pass   127.0.0.1:9000;" /etc/nginx/nginx.conf
RUN sed -i "64a             root           html;" /etc/nginx/nginx.conf
RUN sed -i "64a             location ~ \.php$ {" /etc/nginx/nginx.conf

RUN echo "<?php phpinfo()?>" > /usr/local/nginx/html/index.php
RUN sed -i '45s/index  index.html index.htm;/index  index.php index.html index.htm;/g' /etc/nginx/nginx.conf


#安装redis server
WORKDIR /usr/src
RUN wget -O redis.tar.gz http://download.redis.io/releases/redis-3.2.9.tar.gz
RUN mkdir redis && tar -xzvf redis.tar.gz -C ./redis --strip-components 1
WORKDIR /usr/src/redis
RUN make && make install
RUN mkdir -p /usr/local/redis/bin
RUN cp ./src/redis-server /usr/local/redis/bin/ && cp ./src/redis-cli /usr/local/redis/bin/ && cp ./src/redis-benchmark /usr/local/redis/bin/
RUN cp ./redis.conf /etc/redis.conf
RUN sed -i '61s/127.0.0.1/0.0.0.0/g' /etc/redis.conf
RUN sed -i '128s/no/yes/g' /etc/redis.conf
RUN sed -i '480s/# requirepass foobared/requirepass 123456/g' /etc/redis.conf
RUN echo -e "# description: Redis web server. \n\
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
         esac" > /etc/init.d/redis
RUN chmod +x /etc/init.d/redis


#安装php扩展
RUN mkdir /etc/php
RUN cp /usr/src/php-7.1.7/php.ini-development /etc/php/php.ini
RUN /usr/local/php/bin/pecl install redis
RUN echo "extension=redis.so" > /etc/php/php.ini


#配置supervisor
RUN echo [supervisord] > /etc/supervisord.conf
RUN echo nodaemon=true >> /etc/supervisord.conf

RUN echo [program:sshd] >> /etc/supervisord.conf
RUN echo command=/usr/sbin/sshd -D >> /etc/supervisord.conf

RUN echo [program:nginx] >> /etc/supervisord.conf
RUN echo command=/etc/init.d/nginx start >> /etc/supervisord.conf

RUN echo [program:php-fpm] >> /etc/supervisord.conf
RUN echo command=/etc/init.d/php-fpm start >> /etc/supervisord.conf

RUN echo [program:redis] >> /etc/supervisord.conf
RUN echo command=/usr/local/redis/bin/redis-server /etc/redis.conf >> /etc/supervisord.conf


RUN source /etc/profile


EXPOSE 80 6379


CMD ["/usr/bin/supervisord"]
