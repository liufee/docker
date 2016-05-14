FROM centos:7
MAINTAINER liufee job@feehi.com
RUN yum -y install epel-release && yum -y update
RUN yum -y install pcre pcre-devel zlib zlib-devel openssl openssl-devel libxml2 libxml2-devel libjpeg libjpeg-devel libpng libpng-devel curl curl-devel freetype freetype-devel libmcrypt libmcrypt-devel cmake gcc-c++ ncurses-devel perl-Data-Dumper autoconf wget libicu libicu-devel libmcrypt libmcrypt-devel vim

ADD /nginx-1.10.0 /downloads/nginx-1.10.0
WORKDIR /downloads/nginx-1.10.0
RUN ./configure --prefix=/usr/local/nginx --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/var/run/nginx.pid --lock-path=/var/lock/nginx.lock --user=nginx --group=nginx --with-http_ssl_module --with-http_flv_module --with-http_stub_status_module --with-http_gzip_static_module --http-client-body-temp-path=/tmp/nginx/client/ --http-proxy-temp-path=/tmp/nginx/proxy/ --http-fastcgi-temp-path=/tmp/nginx/fcgi/ --with-pcre --with-http_dav_module 
RUN make && make install

ADD /php-7.0.6 /downloads/php-7.0.6
WORKDIR /downloads/php-7.0.6
RUN ./configure --prefix=/usr/local/php --with-config-file-path=/etc --enable-soap --enable-mbstring=all --enable-sockets --enable-fpm --with-gd --with-freetype-dir=/usr/include/freetype2/freetype --with-jpeg-dir=/usr/lib64 --with-zlib --with-iconv --enable-libxml --enable-xml --with-curl --with-mcrypt --with-openssl --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --enable-intl
RUN make && make install

ADD /mysql-5.7.12 /downloads/mysql-5.7.12
WORKDIR /downloads/mysql-5.7.12
RUN cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql -DMYSQL_DATADIR=/data/mysql -DSYSCONFDIR=/etc -DWITH_MYISAM_STORAGE_ENGINE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_MEMORY_STORAGE_ENGINE=1 -DWITH_READLINE=1 -DMYSQL_UNIX_ADDR=/var/lib/mysql/mysql.sock -DMYSQL_TCP_PORT=3306 -DENABLED_LOCAL_INFILE=1 -DWITH_PARTITION_STORAGE_ENGINE=1 -DEXTRA_CHARSETS=all -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DWITH_BOOST=/downloads/mysql-5.7.12/boost
RUN make
RUN make install
RUN mkdir -p /data/mysql
RUN useradd mysql
RUN chown -R mysql /data/mysql
RUN /usr/local/mysql/bin/mysqld --initialize --initialize-insecure --basedir=/usr/local/mysql --datadir=/data/mysql --user=mysql


ADD /etc /etc
ADD /nginx /etc/init.d/nginx
RUN chmod +x /etc/init.d/nginx
RUN useradd nginx
RUN mkdir -p /tmp/nginx/client
RUN cp /downloads/php-7.0.6/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm && chmod +x /etc/init.d/php-fpm
RUN cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf
RUN cp /usr/local/php/etc/php-fpm.d/www.conf.default /usr/local/php/etc/php-fpm.d/www.conf
RUN cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysqld && chmod +x /etc/init.d/mysqld

ADD /start.sh /start.sh
RUN chmod +x /start.sh
CMD ["/start.sh"]
