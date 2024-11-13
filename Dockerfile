FROM alpine:3.20 AS build

WORKDIR /app

RUN apk update \
    && apk upgrade \
    && apk add go

COPY main.go /app/main.go

RUN go mod init github.com/MichaelRodriguesOficial/mysqlsql-backup-s3 \
    && go get github.com/robfig/cron/v3 \
    && go build -o out/go-cron

FROM alpine:3.20
LABEL maintainer="ITMR"

RUN apk update \
    && apk upgrade \
    && apk add coreutils mysql-client mariadb-client mariadb-connector-c aws-cli openssl \
    && apk add tzdata nano \
    && cp /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime \
    && echo "America/Sao_Paulo" > /etc/timezone \
    && rm -rf /var/cache/apk/*

# Definir o fuso horário como variável de ambiente
ENV TZ=America/Sao_Paulo

COPY --from=build /app/out/go-cron /usr/local/bin/go-cron

# Variáveis de ambiente para MariaDB/MySQL
ENV MYSQLDUMP_OPTIONS --quote-names --quick --add-drop-table --add-locks --allow-keywords --disable-keys --extended-insert --single-transaction --create-options --comments --net_buffer_length=16384
ENV MYSQL_DATABASE=**None**
ENV MYSQL_HOST=**None**
ENV MYSQL_PORT=3306
ENV MYSQL_USER=**None**
ENV MYSQL_PASSWORD=**None**
ENV MYSQL_EXTRA_OPTS=''

# Variáveis de ambiente para S3
ENV S3_ACCESS_KEY_ID=**None**
ENV S3_SECRET_ACCESS_KEY=**None**
ENV S3_BUCKET=**None**
ENV S3_REGION=us-west-1
ENV S3_PREFIX='backup'
ENV S3_ENDPOINT=**None**
ENV S3_S3V4=no

# Variáveis configuração geral
ENV SCHEDULE=**None**
ENV ENCRYPTION_PASSWORD=**None**
ENV DELETE_OLDER_THAN=**None**

ADD run.sh run.sh
ADD backup.sh backup.sh

RUN chmod +x run.sh backup.sh

CMD ["sh", "run.sh"]
