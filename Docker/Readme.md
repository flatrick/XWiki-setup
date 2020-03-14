# Info

This example sets up and runs XWiki and Matomo using Docker Compose.
It uses volumes for permanent storage, so that if you restart the containers, they'll still contain the same data.
It also uses links to files on the host for MySQL so as to ensure the correct settings that XWiki requires.
If you're running this on Windows, make sure to add the unit-drive (C:\, D:\ or wherever you put these files) as a resource in the Docker service (Resources - File Sharing).

- XWiki running on [http://localhost:8080](http://localhost:8080)
  - with MySQL as a db backend
- Matomo running on [http://localhost:8081](http://localhost:8081)
  - with MariaDB as a db backend

## Readme before starting

Edit all .env-files listed below to have usernames and passwords.
Matomo uses MariaDB so their usernames and passwords must match.
XWiki uses MySQL so their usernames and passwords must match.

- [docker-compose.yaml](docker-compose.yaml)
- [mariadb.env](mariadb.env)
- [matomo.env](matomo.env)
- [mysql.env](mysql.env)
- [xwiki.env](xwiki.env)
