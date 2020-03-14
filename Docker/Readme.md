# Info

This example will:
- setup XWiki running on [http://localhost:8080](http://localhost:8080)
  - with MySQL as a db backend
- Matomo on [http://localhost:8081](http://localhost:8081)
  - with MariaDB as a db backend

## docker-compose.yaml

```yaml
version: "3.1"

services:

  mariadb:
    image: mariadb
    command: --max-allowed-packet=64MB
    restart: always
    volumes:
      - db:/var/lib/mysql
    env_file:
      - ./mariadb.env

  matomo:
    image: matomo
    depends_on:
      - mariadb
    restart: always
    volumes:
#     - ./config:/var/www/html/config
#     - ./logs:/var/www/html/logs
      - matomo:/var/www/html
    env_file:
      - ./matomo.env
    ports:
      - 8081:80

  xwiki:
    image: "xwiki:lts-mysql-tomcat"
    depends_on:
      - xwiki-mysql-db
    restart: always      
    volumes:
      - xwiki-data:/usr/local/xwiki      
    env_file:
      - ./xwiki.env
    ports:
      - 8080:8080      

  xwiki-mysql-db:
    image: "mysql:5.7"
    restart: always
    command: --max-allowed-packet=64MB
    volumes:
      # Download init.sql from: https://raw.githubusercontent.com/xwiki-contrib/docker-xwiki/master/11/mysql-tomcat/mysql/init.sql
      # Download xwiki.cnf from: https://raw.githubusercontent.com/xwiki-contrib/docker-xwiki/master/11/mysql-tomcat/mysql/xwiki.cnf
      - mysql-data:/var/lib/mysql
      - ./xwiki.cnf:/etc/mysql/conf.d/xwiki.cnf
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    env_file:
      - ./mysql.env

volumes:
  db:
  matomo:
  mysql-data:
  xwiki-data:
```

### mariadb.env

```ini
MYSQL_ROOT_PASSWORD=
MYSQL_DATABASE=matomo
MYSQL_USER=
MYSQL_PASSWORD=
```

### matomo.env

```ini
MATOMO_DATABASE_ADAPTER=mysql
MATOMO_DATABASE_HOST=mariadb
MATOMO_DATABASE_DBNAME=matomo
MATOMO_DATABASE_TABLES_PREFIX=matomo_
MATOMO_DATABASE_USERNAME=
MATOMO_DATABASE_PASSWORD=
VIRTUAL_HOST=
```

### mysql.env

```ini
MYSQL_ROOT_PASSWORD=
MYSQL_DATABASE=xwiki
MYSQL_USER=
MYSQL_PASSWORD=
```

### xwiki.env

```ini
DB_HOST=xwiki-mysql-db
DB_DATABASE=xwiki
DB_USER=
DB_PASSWORD=
```
