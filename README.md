LNMP Dockerfile
=================

基于最新版CentOS官方镜像

包含php，nginx，reids，oepnssh server，crond，swoole，phpmyadmin，phpredisadmin，xhprof等服务。


简介
------------------------
默认包含的版本

- [x] php7.1.2

- [x] nginx1.12.2 (默认web根目录在/usr/local/nginx/html)

- [x] redis3.2.9（默认密码123456）

- [x] openssh server(默认root密码123456)

- [x] crond

- [x] phpmyadmin(管理地址:http://nginx默认站点或域名/phpmyadmin)

- [x] phpredisadmin(管理地址::http://nginx默认站点域名或ip/phpredisadmin。管理用户名为admin，密码同redis密码)

- [x] xhprof


>docker build的时候加入
    --build-arg PHP_VER=php版本号 
    --build-arg NGINX_VER=nginx版本号 
    --build-arg REDIS_VER=reids版本号
    --build-arg PHPMYADMIN_VER=phpmyadmin版本号
    --build-arg REDIS_VER=redis密码(phpredisadmin同此)
    --build-arg ROOT_PASSWORD=ssh的root密码
可以指定php，nginx，redis，phpmyadmin的安装版本,redis(phpredisadmin)和ssh的密码


获取镜像
------------------------
1. 快速获取镜像
    ```bash 
    $ docker pull registry.cn-hangzhou.aliyuncs.com/liufee/feehi 
    ```
    
2. 自行构建(推荐)
    ```bash
      $ git clone https://github.com/liufee/docker.git
      $ cd /path/to/docker
      $ docker build -t feehi/lnmp ./
    ```
P.S 自行构建，如果某一步骤失败, 再来一次。(因为你懂的原因，pecl.php.net,phpmyadmin.net,repo.mysql.com不稳定，造成下载某些扩展的时候失败退出。windows下使用ss代理切记勾选全局使用代理并重启cmd)


运行容器
-------------------

```bash
  $ docker run -h feehi -p 80:80 -p 23:22 -p 3306:3306 -p 6379:6379 --name feehi -itd -v /path/to/docker/etc/nginx:/etc/nginx -v /path/to/docker/data/mysql:/mysql -v /path/to/docker/data/log:/var/log -v /path/to/www:/usr/local/nginx/html feehi/lnmp
```
 P.S 
 
 默认web目录为/usr/local/nginx/html,若需要配置多个vhost可以映射其他web目录进去.如: -v /path/to/sites:/www,然后在/etc/nginx/site.d中增加vhost配置


xhprof使用方法
-------------------
```php
    xhprof_enable();

    //你需要分析的代码
    
    $xhprof_data = xhprof_disable();
    include_once 'xhprof_lib/utils/xhprof_lib.php';//注xhprof_lib已经在/usr/local/php/lib/php中了
    include_once 'xhprof_lib/utils/xhprof_runs.php';
    
    $xhprof_runs = new XHProfRuns_Default();
    $run_id = $xhprof_runs->save_run($xhprof_data, "xhprof_test");
    //将run_id保存起来或者随代码一起输出
```
然后访问:http://nginx默认站点或域名/xhpfrof_html/index.php?run=run_id&source=xhprof_test查看结果


注意
-------------------
* 为了持久化保存数据，最好把宿主机某一目录挂载到容器内的/mysql。
* 每次启动容器的时候，都会判断/mysql目录是否为空，为空则初始化mysql服务并修改root密码为docker run -e MYSQL_PASSWORD=xxx的值，若没有指定默认修改为123456, host='%'，需要重置mysql直接清空/mysql目录重新启动容器即可。

   
