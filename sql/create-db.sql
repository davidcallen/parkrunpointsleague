CREATE DATABASE PRPL DEFAULT CHARACTER SET = utf8;

FLUSH PRIVILEGES;  -- workaround for bug in v5.0, where a prior dropped user is still in the cache and the following create user will then fail.
CREATE USER 'PRPL'@'%' IDENTIFIED BY 'xxxxxxxx';

FLUSH PRIVILEGES;  -- workaround for bug in v5.0, where a prior dropped user is still in the cache and the following create user will then fail.
GRANT ALL ON PRPL.* TO 'PRPL'@'%';
GRANT GRANT OPTION ON PRPL.* TO 'PRPL'@'%';

FLUSH PRIVILEGES;
