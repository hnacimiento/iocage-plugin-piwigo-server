# iocage-plugin-piwigo-server

This is iocage plugin to create Piwigo, an open source photo gallery software for the web. Designed for organisations, teams and individuals.
More details at http://piwigo.org

*I have tested this plugin couple of times on my TrueNAS 13.0 as a **13.0-RELEASE** and **12.0-U8.1**, all seems to work well.*

![Piwigo Installation Successful](https://i.imgur.com/iElp8s3.png)

Tip 1. Please remember to read info in **TrueNAS / Plugins / Piwigo / POST INSTALL NOTES** - to access info with DB user and DB password.
Piwigo first installation page will set Host: as localhost, usually this needs to be changed to 127.0.0.1
>   Host: 127.0.0.1

Tip 2. Please set your own date/time location in PHP.INI, as for this installation I have chosen Europe/London ;)

## Some of the post installation settings I have tuned for Piwigo:
<h6> PHP

```
    date.timezone = "America/Argentina/Buenos_Aires"
    max_execution_time = 300
    max_input_time = 300
    post_max_size = 100M
    upload_max_filesize = 100M
    memory_limit = 512M
```
<h6>Nginx

```
    proxy_connect_timeout 600s
    proxy_send_timeout 600s
    proxy_read_timeout 600s
    fastcgi_send_timeout 600s
    fastcgi_read_timeout 600s

    pm.max_children = 35
    pm.start_servers = 15
    pm.min_spare_servers = 15
    pm.max_spare_servers = 20

    request_terminate_timeout = 300
```

<h2> <h2>Gallery View

![Piwigo Gallery View - Theme Modus](https://i.imgur.com/1QnmoeQ.png)

![Piwigo Dashboard View](https://i.imgur.com/eXVPk13.png)