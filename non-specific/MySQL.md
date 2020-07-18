# Instructions

These instructions will expect you to install MySQL in anyway you like, either by source or using your chosen OS package-manager.

## Configure

Where you'll find your **mysqld.cnf** differs from OS to OS, so you'll need to read up on that now if you don't already know where it is

```sh
mysql -u root -e "create database xwiki default character set utf8 collate utf8_bin"
mysql -u root -e "grant all privileges on *.* to xwiki@localhost identified by 'SOMETHING74f3H3r3?'"
vi mysqld.cnf
```

Edit `mysqld.cnf` so the line with `max_allowed_packet` looks like this:

```ini
max_allowed_packet      = 512M
```
