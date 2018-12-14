# /etc/nginx/conf.d/tomcat.conf #

```
## Expires map based upon HTTP Response Header Content-Type
#    map $sent_http_content_type $expires
#{
#       default                 off;
#       text/html               epoch;
#       text/css                1h;
#       text/javascript         1h;
#       application/javascript  1h;
#       ~image/                 1m;
#}

## Expires map based upon request_uri (everything after hostname)
map $request_uri $expires {
    default off;
    ~*\.(ogg|ogv|svg|svgz|eot|otf|woff|mp4|ttf|rss|atom|js|jpg|jpeg|gif|png|ico|zip|tgz|gz|rar|bz2|doc|xls|exe|ppt|tar|mid|midi|wav|bmp|rtf)(\?|$) 1h;
    ~*\.(css) 0m;
}
expires $expires;

server {
    listen       80;
    server_name  wiki.server.local wiki;
    charset utf-8;

    # Normally root should not be accessed, however, root should not serve files that might compromise the security of your server.
    root /var/www/html;

    location /
    {
        # All "root" requests will have /xwiki appended AND redirected to wiki.kibino.local
        rewrite ^ $scheme://$server_name/xwiki$request_uri? permanent;
    }

    location ^~ /xwiki
    {
       # If path starts with /xwiki - then redirect to backend: XWiki application in Tomcat
       # Read more about proxy_pass: http://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_pass
       proxy_pass              http://localhost:8080/xwiki;
       proxy_cache             off;
       proxy_set_header        X-Real-IP $remote_addr;
       proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
       proxy_set_header        Host $http_host;
       proxy_set_header        X-Forwarded-Proto $scheme;
       expires                 $expires;
    }
}
