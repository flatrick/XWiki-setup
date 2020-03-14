# Info

This example will:

- setup XWiki running on [http://localhost:8080](http://localhost:8080)
  - with MySQL as a db backend
- Matomo on [http://localhost:8081](http://localhost:8081)
  - with MariaDB as a db backend

Edit all .env-files listed below to have usernames and passwords.
Matomo uses MariaDB so their usernames and passwords must match.
XWiki uses MySQL so their usernames and passwords must match.

- [docker-compose.yaml](docker-compose.yaml)
- [mariadb.env](mariadb.env)
- [matomo.env](matomo.env)
- [mysql.env](mysql.env)
- [xwiki.env](xwiki.env)
