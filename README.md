LNMP Dockerfile
=================

基于最新版CentOS官方镜像

包含php，nginx，reids，oepnssh server，crond，swoole，phpmyadmin，phpredisadmin等服务。

快速获取容器
------------------------
```bash 
docker pull registry.cn-hangzhou.aliyuncs.com/liufee/feehi 
```

简介
------------------------
默认包含的版本

1. php7.1.2

2. nginx1.12.2

3. redis3.2.9（默认密码123456）

4. openssh server(默认root密码123456)

5. crond

6. phpmyadmin

7. phpredisadmin(管理用户名为admin，密码同redis密码)


>docker build的时候加入--build-arg PHP_VER=php版本号 --build-arg NGINX_VER=nginx版本号 --build-arg REDIS_VER=reids版本号 --build-arg PHPMYADMIN_VER=phpmyadmin版本号 指定php，nginx，redis，phpmyadmin的安装版本。*

>docker build的时候加入--build-arg REDIS_VER=REDIS_PASS指定redis密码(phpredisadmin的admin用户的密码也是此密码)，--build-arg ROOT_PASSWORD=ssh的root密码*


构建镜像
------------------------
```bash
  $ git clone https://github.com/liufee/docker.git
  $ cd /path/to/docker
  $ docker build -t feehi/lnmp ./
```
P.S 如果某一步骤失败, 再来一次。(因为你懂的原因，pecl.php.net不稳定，造成下载某些扩展的时候失败退出)


运行容器
-------------------

```bash
  $ docker run -h feehi -p 80:80 -p 23:22 -p 3306:3306 -p 6379:6379 --name feehi -itd -v /path/to/docker/etc/nginx:/etc/nginx -v /path/to/docker/data/mysql:/mysql -v /path/to/docker/data/log:/var/log -v /path/to/docker/data/tools:/tools -v /e:/www liufee/feehi
```
 P.S 
 
 1. $PWD为当前运行docker run的目录，可传入绝对地址。
 
 2. 把e:/换成代码路径，或者传入多个项目的地址，修改/etc/nginx/site.d中的document_root地址


注意
-------------------
* 为了持久化保存数据，最好把宿主机某一目录挂载到容器内的/mysql。
* 每次启动容器的时候，都会判断/mysql目录是否为空，为空则初始化mysql服务并修改root密码为docker run -e MYSQL_PASSWORD=xxx的值，若没有指定默认修改为123456, host='%'，需要重置mysql直接清空/mysql目录重新启动容器即可。

   
