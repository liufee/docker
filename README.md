LNMP Dockerfile
=================

基于最新版CentOS官方镜像

包含php, java, nginx, mysql, reids, openssh server, go, crond, swoole, mongodb, node.js, phpmyadmin, phpredisadmin, xhprof, maven等服务。


简介
------------------------
默认包含的版本

- [x] php (默认7.2.8)

- [x] java (默认1.8,当前仅支持1.8)

- [x] nginx (默认1.15.2版本,默认web根目录在/usr/local/nginx/html)

- [x] mysql (默认5.7.23)

- [x] redis（默认4.0.11版本,默认密码123456）

- [x] openssh server (默认root密码123456)

- [x] crond

- [x] phpmyadmin (默认版本4.7.6, 管理地址:http://nginx默认站点或域名/phpmyadmin)

- [x] phpredisadmin (管理地址::http://nginx默认站点域名或ip/phpredisadmin。管理用户名为admin，密码同redis密码)

- [x] xhprof

- [x] go语言 (默认1.10.3 GOPATH环境变量已设置为$HOME/go，映射到此文件夹即可)

- [x] node.js (默认8.11.4)

- [x] mongodb (默认4.0.1)

- [x] maven (默认3.6.0)


>docker build的时候加入
    --build-arg PHP_VER=php版本号 
    --build-arg JKD_VER=jdk版本号 
    --build-arg NGINX_VER=nginx版本号 
    --build-arg MYSQL_VER=mysql版本号 
    --build-arg REDIS_VER=reids版本号
    --build-arg PHPMYADMIN_VER=phpmyadmin版本号
    --build-arg REDIS_VER=redis密码(phpredisadmin同此)
    --build-arg ROOT_PASSWORD=ssh的root密码
    --build-arg GO_VER=go语言版本
    --build-arg NODE_VER=node.js语言版本
    --build-arg MONGODB_VER=mongodb版本
    --build-arg MAVEN_VER=maven版本
可以指定php，nginx，redis，phpmyadmin的安装版本, redis(phpredisadmin)和ssh的密码


获取镜像
------------------------
1. 远程获取镜像(推荐)
    ```bash 
    $ docker pull registry.cn-hangzhou.aliyuncs.com/liufee/feehi 
    $ git clone https://github.com/liufee/docker.git
    $ cd /path/to/docker
    ```
    
2. 自行构建
    ```bash
    $ git clone https://github.com/liufee/docker.git
    $ cd /path/to/docker
    $ docker build -t liufee/feehi ./
    ```
    P.S 
    
    自行构建，如果某一步骤失败, 再来一次。(因为你懂的原因，pecl.php.net,phpmyadmin.net,repo.mysql.com不稳定，造成下载某些扩展的时候失败退出。windows下使用ss代理切记勾选全局使用代理并重启cmd)
    
    强烈建议在执行cd /path/to/docker命令前，执行export http_proxy=http://ip:1087;export https_proxy=http://ip:1087;伟大的GFW，最好带个梯子。ip通常为127.0.0.1


运行容器
-------------------

```bash
  $ docker run -h feehi -p 80:80 -p 23:22 -p 3306:3306 -p 6379:6379 -p 27017:27017 --name feehi -itd -v /path/to/docker/etc/nginx:/etc/nginx -v /path/to/docker/data/mysql:/data/mysql -v /path/to/docker/data/mongodb:/data/mongodb -v /path/to/docker/data/log:/var/log -v /path/to/www:/usr/local/nginx/html liufee/feehi
```
 P.S 
 
 若使用远程获取镜像请将liufee/feehi修改成registry.cn-hangzhou.aliyuncs.com/liufee/feehi
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

   
