FROM openjdk:8-jre-slim-buster

ENV SOLR_USER solr
ENV SOLR_UID 8983
ENV SOLR_GROUP solr
ENV SOLR_GID 8983
ENV SOLR_VERSION 4.10.4
ENV SOLR_URL ${SOLR_DOWNLOAD_SERVER:-https://archive.apache.org/dist/lucene/solr}/4.10.4/solr-4.10.4.tgz
ENV SOLR_SHA256 ac3543880f1b591bcaa962d7508b528d7b42e2b5548386197940b704629ae851
ENV PATH /opt/solr/bin:/opt/docker-solr/scripts:$PATH

COPY scripts /opt/docker-solr/scripts
COPY schema.xml /opt/solr/example/solr/collection1/conf/schema.xml

RUN apt update \
  && apt install -y lsof procps wget gpg unzip \
  && rm -rf /var/lib/apt/lists/* \
  && groupadd -r --gid "$SOLR_GID" "$SOLR_GROUP" \
  && useradd -r --uid $SOLR_UID --gid "$SOLR_GID" "$SOLR_USER" \
  && mkdir -p /opt/solr \
  && wget -nv "$SOLR_URL" -O /opt/solr.tgz \
  && wget -nv "$SOLR_URL.asc" -O /opt/solr.tgz.asc \
  && (>&2 ls -l /opt/solr.tgz /opt/solr.tgz.asc) \
  && tar -C /opt/solr --extract --file /opt/solr.tgz --strip-components=1 \
  && rm /opt/solr.tgz* \
  && rm -Rf /opt/solr/docs/ \
  && mkdir -p /opt/solr/server/solr/lib /opt/solr/server/solr/mycores /opt/solr/server/logs /docker-entrypoint-initdb.d /opt/docker-solr \
  && sed -i -e 's/"\$(whoami)" == "root"/$(id -u) == 0/' /opt/solr/bin/solr \
  && sed -i -e 's/lsof -PniTCP:/lsof -t -PniTCP:/' /opt/solr/bin/solr \
  && sed -i -e '/-Dsolr.clustering.enabled=true/ a SOLR_OPTS="$SOLR_OPTS -Dsun.net.inetaddr.ttl=60 -Dsun.net.inetaddr.negative.ttl=60"' /opt/solr/bin/solr.in.sh \
  && chown -R "$SOLR_USER:$SOLR_GROUP" /opt/solr \
  && chown -R "$SOLR_USER:$SOLR_GROUP" /opt/docker-solr \
  && chown -R "$SOLR_USER:$SOLR_GROUP" /opt/solr/example/solr/collection1/conf/schema.xml \
  && mkdir -p /opt/solr/example/solr/collection1/data \
  && chown -R "$SOLR_USER:$SOLR_GROUP" /opt/solr/example/solr/collection1/data

EXPOSE 8983
WORKDIR /opt/solr
USER $SOLR_USER

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["solr-foreground"]
