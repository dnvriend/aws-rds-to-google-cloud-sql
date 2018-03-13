# aws-rds-to-google-cloud-sql
A small study project on how to migrate data from aws rds to google cloud sql focusing only on
mysql using the `mysqldump` and `mysql` tooling and `postgres` using the `pg_dump` and `psql` tooling, both using the `sql statement` export stategy to create sql files for backup and restore.

## TL;DR
MySQL migration of AWS RDS to Cloud SQL Mysql is quite easy and works out of the box. Postgres however not so much, and needs special attention and further research. GCP Postgres support is still beta. For now, bet on MySQL for both AWS and GCP.

## Database versions per platform
Both AWS and GCP support mysql and postgres as a database engine. The supported versions are:

| Database Engine | AWS                           | GCP           |
| --------------- | ----------------------------- | ------------- |
| MySQL           | 5.5, 5.6, 5.7                 | 5.5, 5.6, 5.7 |
| PostgreSQL      | 9.3, 9.4, 9.5, 9.6, 10.1      | 9.6           |
| Aurora          | mysql 5.7, postres 9.6        |               |

As both AWS and GCP support MySQL 5.7 and Postgres 9.6, we full focus on these versions only.

## What is AWS RDS?
Amazon Relational Database Service (Amazon RDS) is a managed service that makes it easy to set up, operate, and scale a relational database in the cloud. It provides cost-efficient and resizable capacity, while managing time-consuming database administration tasks, freeing you up to focus on your applications and business.

## What is Google Cloud SQL?
Cloud SQL is an easy-to-use service that delivers fully managed SQL databases in the cloud. Cloud SQL provides either MySQL or PostgreSQL databases. Cloud SQL for PostgreSQL is currently in Beta release. Cloud SQL lets you hand off to Google the mundane, but necessary and often time consuming tasks — like applying patches and updates, managing backups and configuring replications — so you can put your focus on building great applications. And because we use standard wire protocols, it’s easy to connect from just about any application, anywhere.

## Creating databases
I have used the AWS RDS Web Console to create three databases on AWS RDS and the Google Cloud Dashboard to create Google Cloud SQL MySQL and Postgres instances.

# MySQL
Lets first look at the MySQL database engine. TL;DR is that it is possible to migrate data from AWS RDS to Google Cloud SQL and back again using the import/export feature of GCP and the `mysqldump` and `mysql` command and use sql based backup files.

## Docker for commands
I will use the `mysql:5.7` docker container so that I have all the mysql utilities available. All the commands will be executed from this container. To launch the container:

```
$ docker run -e MYSQL_ROOT_PASSWORD=dennis -d --name mysql mysql:5.7
$ docker exec -it mysql /bin/bash    
```

## Connect to the database
To connect to the database, execute the following:

```
$ mysql \
  --host=dnvriend-mysql.czvsstshhhca.eu-central-1.rds.amazonaws.com \
  --port=3306 \
  --user=dnvriend \
  --password=dnvriend01 \
  dnvriend
```

You should now have access to the database

## Insert records to the database
Lets create the table schema and insert some records:

```
create table person
(
	id int auto_increment primary key,
	name varchar(255) null,
	age int null
);
INSERT INTO `person` (name, age) VALUES ('Dennis',42),('Tijger',12),('Elsa',16);
```

We should now have three records in the database.

## A word about 'mysqlimport'
To import data, there are two ways, use the `mysql` tool and [mysqlimport](https://dev.mysql.com/doc/refman/5.7/en/mysqlimport.html) tool, which is a client that bulk loads text file contents to tables. There are some constraints using mysqlimport. Although mysqlimport is faster, the data needs to be in the expected format, and tables must already exist. There is another tool `mysqldump` that generates 'sql' based files that contain SQL statements, which is more flexible. We won't be using `mysqlimport` for this reason but only focus on `mysqldump`.

## mysqldump
To export data, MySQL uses the [mysqldump](https://dev.mysql.com/doc/refman/5.7/en/mysqldump.html) tool, which is a client that performs logical backups. By default, mysqldump writes information as SQL statements to the standard output, so we will pipe that output to a file:

```
$ mysqldump \
  --host=dnvriend-mysql.czvsstshhhca.eu-central-1.rds.amazonaws.com \
  --port=3306 \
  --user=dnvriend \
  --password=dnvriend01 \
  dnvriend \
  person > person.sql
```

The above means to log in to the database with the credentials above, use the database `dnvriend` and export the table `person` and store the SQL statements in the file `person.sql`.

Next we need to copy the contents of the file to the host operating system:

```
$ docker cp mysql:person.sql ~/Desktop/person.sql
```

## Restore to AWS RDS Mysql
Lets drop the table manually and restore the table from the database file:

```
drop table person;
```

Lets restore the table:

```
$ mysql \
  --host=dnvriend-mysql.czvsstshhhca.eu-central-1.rds.amazonaws.com \
  --port=3306 \
  --user=dnvriend \
  --password=dnvriend01 \
  dnvriend < person.sql
```

When we do a select we see:

```
mysql> select * from person;
+----+--------+------+
| id | name   | age  |
+----+--------+------+
|  1 | Dennis |   42 |
|  2 | Tijger |   12 |
|  3 | Elsa   |   16 |
+----+--------+------+
3 rows in set (0.01 sec)
```

Great!

## Restore to AWS MySQL Aurora
I have created a mysql aurora, lets see if we can restore that database as well.

```
$ mysql \
  --host=dnvriend-aurora-mysql.czvsstshhhca.eu-central-1.rds.amazonaws.com \
  --port=3306 \
  --user=dnvriend \
  --password=dnvriend01 \
  dnvriend < person.sql
```

Lets see if the table has been restored:

```
mysql> select * from person;
+----+--------+------+
| id | name   | age  |
+----+--------+------+
|  1 | Dennis |   42 |
|  2 | Tijger |   12 |
|  3 | Elsa   |   16 |
+----+--------+------+
3 rows in set (0.02 sec)
```

It has, also great!

## Google Cloud SQL for MySQL
Lets use the Google Cloud Dashboard to create a 2nd generation MySQL 5.7 database with all the default options enabled. You can use the google cloud dashboard to connect to the database. Just click on your database and connect. We must first upload the `person.sql` file that we have exported to a GCP bucket. When we've done so, in the database console of our instance, we can choose to `import` a sql file, choose the one from our bucket and also choose a database. We must first create a database though, just call it `dnvriend`. Then choose that database to restore to. After the import has completed, we have all the records available in the database and can see it through the database CLI (Cloud Shell).

To export the database, we can choose `export` and then select the database to export. It will export the whole database including all tables and exports it, using `mysqldump` to a GCP bucket, eg.  We can download the file from the bucket and use it to restore our mysql database in AWS, lets try it.

We must first copy the cloud sql export file to the docket container though:

```
$ docker cp ~/Desktop/Cloud_SQL_Export_2018-03-13\ \(11_16_36\) mysql:cloud_sql_export.sql
```

Let's try to restore it to our AWS RDS `mysql` instance:

```
$ mysql \
  --host=dnvriend-mysql.czvsstshhhca.eu-central-1.rds.amazonaws.com \
  --port=3306 \
  --user=dnvriend \
  --password=dnvriend01 \
  dnvriend < cloud_sql_export.sql
```

lets check:

```
mysql> select * From person;
+----+--------+------+
| id | name   | age  |
+----+--------+------+
|  1 | Dennis |   42 |
|  2 | Tijger |   12 |
|  3 | Elsa   |   16 |
+----+--------+------+
3 rows in set (0.01 sec)
```

And we can restore an export from GCP, great!

# Postgres
The TL;DR of postgres is that there are still some issues when migrating from AWS RDS to Cloud SQL, and further research is necessary.

## Docker for commands
I will use the `postgres:9.6` docker container so that I have all the postgres utilities available. All the commands will be executed from this container. To launch the container:

```
$ docker run -d --name postgres postgres:9.6
$ docker exec -it postgres /bin/bash
```

## Connect to the database
To connect to the database, execute the following:

```
$ PGPASSWORD=dnvriend01 psql \
  --host=dnvriend-postgres.czvsstshhhca.eu-central-1.rds.amazonaws.com \
  --port=5432 \
  --username=dnvriend \
  --dbname=dnvriend
```

You should now have access to the database

## Insert records to the database
Lets create the table schema and insert some records:

```
create table person
(
	id serial not null constraint person_pkey primary key,
	name varchar(255),
	age integer
);

insert into person (name, age) values ('Dennis',42),('Tijger',12),('Elsa',16);('Dennis',42),('Tijger',12),('Elsa',16);
```

We should now have three records in the database.

## pg_dump
To export data, Postgres uses the [pg_dump](https://www.postgresql.org/docs/9.6/static/app-pgdump.html) tool, which is a utility for backing up a PostgreSQL database and it can create a sql file, that contains all the SQL statement to restore the database. To restore, you need to use the `psql` command.

```
$ PGPASSWORD=dnvriend01 pg_dump \
  --host=dnvriend-postgres.czvsstshhhca.eu-central-1.rds.amazonaws.com \
  --port=5432 \
  --username=dnvriend \
  dnvriend > pg-dnvriend.sql
```

The above means to log in to the database with the credentials above, use the database `dnvriend` and export the database `dnvriend` and store the SQL statements of all tables in the file `pg-dnvriend.sql`.

Next we need to copy the contents of the file to the host operating system:

```
$ docker cp postgres:pg-dnvriend.sql ~/Desktop/pg-dnvriend.sql
```

## Restore to AWS RDS Postgres
Lets drop the table manually and restore the table from the database file:

```
drop table person;
```

Lets restore the table:

```
$ PGPASSWORD=dnvriend01 psql \
  --host=dnvriend-postgres.czvsstshhhca.eu-central-1.rds.amazonaws.com \
  --port=5432 \
  --username=dnvriend \
  --dbname=dnvriend < pg-dnvriend.sql
```

When we do a select we see:

```
dnvriend=> select * from person;
 id |  name  | age
----+--------+-----
  1 | Dennis |  42
  2 | Tijger |  12
  3 | Elsa   |  16
(3 rows)
```

Great!

## Restore to AWS Postgres Aurora
I have created a postgres aurora, lets see if we can restore that database as well.

```
$ PGPASSWORD=dnvriend01 psql \
  --host=dnvriend-postgres-aurora.czvsstshhhca.eu-central-1.rds.amazonaws.com \
  --port=5432 \
  --username=dnvriend \
  --dbname=dnvriend < pg-dnvriend.sql
```

Lets see if the table has been restored:

```
$ PGPASSWORD=dnvriend01 psql \
  --host=dnvriend-postgres-aurora.czvsstshhhca.eu-central-1.rds.amazonaws.com \
  --port=5432 \
  --username=dnvriend \
  --dbname=dnvriend

dnvriend=> select * from person;
 id |  name  | age
----+--------+-----
  1 | Dennis |  42
  2 | Tijger |  12
  3 | Elsa   |  16
(3 rows)
```

It has, also great!

## Google Cloud SQL for Postgres
Lets use the Google Cloud Dashboard to create a Postgres 9.6 database with all the default options enabled. You can use the google cloud dashboard to connect to the database. Just click on your database and connect. We must first upload the `pg-dnvriend.sql` file that we have exported to a GCP bucket. 

I've tried to  `import` a sql file, after I've created the `dnvriend` database, but the import failed. Obviously there is something wrong.

I tried to copy the sql file from the bucket to the environment of Cloud Shell using the following command:

```
gsutil cp gs://dnvriend-bucket/pg-dnvriend.sql pg-dnvriend.sql
```

Afterwards I executed the following command to execute the sql statement. There were some errors, related to roles that are not available, those are available in AWS RDS, so some cleaning may be necessary before importing the sql script.

```
gcloud beta sql connect dnvriend-postgres --user=postgres < pg-dnvriend.sql
```

A quick check shows all data being available though:

```
postgres=> select * from person;
 id |  name  | age
----+--------+-----
  1 | Dennis |  42
  2 | Tijger |  12
  3 | Elsa   |  16
(3 rows)
```

Lets try to export the data:

To export the database, we can choose `export` and then select the database to export. It will export the whole database including all tables and exports it, using `pg_dump` to a GCP bucket, eg.  We can download the file from the bucket and use it to restore our postgres database in AWS, lets try it.

We must first copy the cloud sql export file to the docket container though:

```
$ docker cp ~/Desktop/Cloud_SQL_Export_2018-03-13_postgres postgres:cloud_sql_export.sql
```

Let's try to restore it to our AWS RDS `postgres` instance:

```
$ PGPASSWORD=dnvriend01 psql \
  --host=dnvriend-postgres.czvsstshhhca.eu-central-1.rds.amazonaws.com \
  --port=5432 \
  --username=dnvriend \
  --dbname=dnvriend < cloud_sql_export.sql
```

lets check:

```
dnvriend=> select * from person;
ERROR:  relation "person" does not exist
LINE 1: select * from person;
```

A quick check of the `cloud_sql_export.sql` script shows that nothing is in there. Further research is necessary to figure out what went wrong. 
