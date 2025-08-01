#!/bin/bash

# set -x (bash debug) if log level is trace
# https://github.com/kuebler-it/container-baseimage/blob/master/image/usr/local/sbin/log-helper
log-helper level eq trace && set -x

SCHEMAS=$1

tmpd=$(mktemp -d)

pushd "${tmpd}" >>/dev/null || exit 1

{
  echo "include /etc/ldap/schema/core.schema"
  echo "include /etc/ldap/schema/cosine.schema"
  echo "include /etc/ldap/schema/inetorgperson.schema"
} > convert.dat

if [ -e "/etc/ldap/schema/rfc2307bis.schema" ]; then
  echo "include /etc/ldap/schema/rfc2307bis.schema" >> convert.dat
else
  echo "include /etc/ldap/schema/nis.schema" >> convert.dat
fi


for schema in ${SCHEMAS} ; do
    echo "include ${schema}" >> convert.dat
done

mkdir ./slaptest
slaptest -f convert.dat -F ./slaptest

if [ $? -ne 0 ] ; then
    log-helper error "slaptest conversion failed"
    exit
fi

mv ./slaptest/* .
rm -rf ./slaptest

for schema in ${SCHEMAS} ; do
    fullpath=${schema}
    schema_name=$(basename "${fullpath}" .schema)
    schema_dir=$(dirname "${fullpath}")
    ldif_file=${schema_name}.ldif

    if [ -e "${schema_dir}/${ldif_file}" ]; then
      log-helper warning "${schema} ldif file ${schema_dir}/${ldif_file} already exists skipping conversion"
      continue
    fi

    find . -name *\}${schema_name}.ldif -exec mv '{}' ./${ldif_file} \;

    # TODO: these sed invocations could all be combined
    sed -i "/dn:/ c dn: cn=${schema_name},cn=schema,cn=config" "${ldif_file}"
    sed -i "/cn:/ c cn: ${schema_name}" "${ldif_file}"
    sed -i '/structuralObjectClass/ d' "${ldif_file}"
    sed -i '/entryUUID/ d' "${ldif_file}"
    sed -i '/creatorsName/ d' "${ldif_file}"
    sed -i '/createTimestamp/ d' "${ldif_file}"
    sed -i '/entryCSN/ d' "${ldif_file}"
    sed -i '/modifiersName/ d' "${ldif_file}"
    sed -i '/modifyTimestamp/ d' "${ldif_file}"

    # slapd seems to be very sensitive to how a file ends. There should be no blank lines.
    sed -i '/^ *$/d' "${ldif_file}"

    mv "${ldif_file}" "${schema_dir}"
done

popd >>/dev/null

rm -rf "$tmpd"
