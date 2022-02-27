FROM postgres

RUN mkdir -p /var/lib/postgresql/data

COPY ./init.sql /docker-entrypoint-initdb.d/

EXPOSE 5432