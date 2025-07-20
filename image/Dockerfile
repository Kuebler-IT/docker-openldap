# Use kueblerit/container-baseimage
# sources: https://github.com/kuebler-it/container-baseimage
FROM kueblerit/container-baseimage:12.2.1

ARG OPENLDAP_PACKAGE_VERSION=2.5.13

ARG LDAP_OPENLDAP_GID
ARG LDAP_OPENLDAP_UID

#ARG PQCHECKER_VERSION=2.0.0
#ARG PQCHECKER_MD5=c005ce596e97d13e39485e711dcbc7e1

# Add openldap user and group first to make sure their IDs get assigned consistently, regardless of whatever
# dependencies get added. If explicit uid or gid is given, use it.
RUN if [ -z "${LDAP_OPENLDAP_GID}" ]; then \
        groupadd -g 911 -r openldap; \
    else \
        groupadd -r -g ${LDAP_OPENLDAP_GID} openldap; \
    fi \
    && if [ -z "${LDAP_OPENLDAP_UID}" ]; then \
        useradd -l -u 911 -r -g openldap openldap; \
    else \
        useradd -l -r -g openldap -u ${LDAP_OPENLDAP_UID} openldap; \
    fi

# Add buster-backports in preparation for downloading newer openldap components, especially sladp
# RUN echo "deb http://ftp.debian.org/debian buster-backports main" >> /etc/apt/sources.list

# Install OpenLDAP, ldap-utils and ssl-tools from the (backported) baseimage and clean apt-get files
# sources: https://github.com/kuebler-it/container-baseimage/blob/master/image/tool/add-service-available
#          https://github.com/kuebler-it/container-baseimage/blob/master/image/service-available/:ssl-tools/download.sh
RUN echo "path-include /usr/share/doc/krb5*" >> /etc/dpkg/dpkg.cfg.d/docker \
    && apt-get -y update \
    && /container/tool/add-service-available :ssl-tools \
    && LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates=20230311* \
    curl=7.88.1* \
    ldap-utils=${OPENLDAP_PACKAGE_VERSION}\* \
    libsasl2-modules=2.1.28* \
    libsasl2-modules-db=2.1.28* \
    libsasl2-modules-gssapi-mit=2.1.28* \
    libsasl2-modules-ldap=2.1.28* \
    libsasl2-modules-otp=2.1.28* \
    libsasl2-modules-sql=2.1.28* \
    openssl=3.0* \
    slapd=${OPENLDAP_PACKAGE_VERSION}\* \
    slapd-contrib=${OPENLDAP_PACKAGE_VERSION}\* \
    krb5-kdc-ldap=1.20.1* \
    #&& curl -o pqchecker.deb -SL http://www.meddeb.net/pub/pqchecker/deb/8/pqchecker_${PQCHECKER_VERSION}_amd64.deb \
    #&& echo "${PQCHECKER_MD5} *pqchecker.deb" | md5sum -c - \
    #&& dpkg -i pqchecker.deb \
    #&& rm pqchecker.deb \
    && update-ca-certificates \
    && apt-get remove -y --purge --auto-remove curl ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Add service directory to /container/service
COPY service /container/service

# Use baseimage install-service script
# https://github.com/kuebler-it/container-baseimage/blob/master/image/tool/install-service
RUN /container/tool/install-service

# Add default env variables
COPY environment /container/environment/99-default

# Expose default ldap and ldaps ports
EXPOSE 389 636

# Put ldap config and database dir in a volume to persist data.
# VOLUME /etc/ldap/slapd.d /var/lib/ldap
