FROM debian:jessie
MAINTAINER developers@plateculture.com

RUN apt-get update && apt-get install -y postgresql-9.5 postgresql-contrib-9.5 postgresql-9.5-postgis-2.1 postgresql-client-9.5 inotify-tools && rm -rf /var/lib/apt/lists/*

# Run the rest of the commands as the ``postgres`` user created by the ``postgres-9.5`` package when it was ``apt-get installed``
USER postgres

# Create a PostgreSQL role named ``docker`` with ``docker`` as the password and
# then create a database `docker` owned by the ``docker`` role.
# Note: here we use ``&&\`` to run commands one after the other - the ``\``
#       allows the RUN command to span multiple lines.
RUN    /etc/init.d/postgresql start &&\
    psql --command "UPDATE pg_database SET datistemplate=FALSE WHERE datname='template1';" &&\
    psql --command "DROP DATABASE template1;" &&\
    psql --command "CREATE DATABASE template1 WITH owner=postgres template=template0 encoding='UTF8';" &&\
    psql --command "UPDATE pg_database SET datistemplate=TRUE WHERE datname='template1';" &&\
    psql --command "CREATE USER docker WITH SUPERUSER PASSWORD 'docker';" &&\
    createdb -O docker docker

# Adjust PostgreSQL configuration so that remote connections to the
# database are possible.
RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/9.5/main/pg_hba.conf

# And add ``listen_addresses`` to ``/etc/postgresql/9.5/main/postgresql.conf``
RUN echo "listen_addresses='*'" >> /etc/postgresql/9.5/main/postgresql.conf

# Expose the PostgreSQL port
EXPOSE 5432

# Add VOLUMEs to allow backup of config, logs and databases
VOLUME  ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql"]

# Set the default command to run when starting the container
CMD ["/usr/lib/postgresql/9.5/bin/postgres", "-D", "/var/lib/postgresql/9.5/main", "-c", "config_file=/etc/postgresql/9.5/main/postgresql.conf"]

# To build it:
# (sudo) docker build -t postgresql .

# To run it:
# (sudo) docker run --restart="always" -d -P --name "postgresql_server" postgresql
