#!/bin/sh
set -e
# Copy certificates acquired by https://github.com/lukas2511/dehydrated 
# to the server's SSL directories e.g. /etc/ssl/*
# Thomas Leuxner <tlx@leuxner.net> 03-08-2017
#
# [04-10-2017]
# + added DANE RR Update Logic: DNS fingerprint
# [26-05-2019]
# + added LDAP certificate Update Logic
acme_certs_dir='/etc/dehydrated/certs'
cert_file_ext='_ACME.pem'
cert_keyfile_ext='_ACME.key'
ssl_certs_dir='/etc/ssl/certs'
ssl_certs_keydir='/etc/ssl/private'
dane_keyfile="$ssl_certs_keydir/host_example_com_ACME.key"
dane_ttl='900'
dane_file_date_old=$(date -r $dane_keyfile +%s)
dane_nsupdate_key='/root/Kxxxx.123+45678.private'
ldap_certs_dir='/etc/ldap/tls'
ldap_private_key='host_example_com_ACME.key'
ldap_keyfile="$ssl_certs_keydir/$ldap_private_key"
ldap_file_date_old=$(date -r $ldap_keyfile +%s)

. msg_formatted.inc

# split out certificate name from path and replace dots with underscores
cert_file_name_split() {
	cert_file=$(echo $i | awk -F/ '{ gsub (/\./,"_"); print $5 }')
}
 
for i in $(find $acme_certs_dir -name fullchain.pem) 
	do 
	cert_file_name_split
	# certificate is new?
	[ -f "$ssl_certs_dir/$cert_file$cert_file_ext" ] || \
	{ msg_formatted "$i_step New certficate $ssl_certs_dir/$cert_file$cert_file_ext..."; touch -d "1 hour ago" $ssl_certs_dir/$cert_file$cert_file_ext  >&2; } 
	# certificate is a renewal?
	[ "$i" -nt $ssl_certs_dir/$cert_file$cert_file_ext ] && \
	{ msg_formatted "$i_step Updating $ssl_certs_dir/$cert_file$cert_file_ext..."; cp -p $i $ssl_certs_dir/$cert_file$cert_file_ext; \
	chmod 644 $ssl_certs_dir/$cert_file$cert_file_ext >&2; }
done

for i in $(find $acme_certs_dir -name privkey.pem) 
	do 
	cert_file_name_split
	[ -f "$ssl_certs_keydir/$cert_file$cert_keyfile_ext" ] || \
	{ msg_formatted "$i_step New key $ssl_certs_keydir/$cert_file$cert_keyfile_ext..."; touch -d "1 hour ago" $ssl_certs_keydir/$cert_file$cert_keyfile_ext  >&2; } 
	[ "$i" -nt $ssl_certs_keydir/$cert_file$cert_keyfile_ext ] && \
	{ msg_formatted "$i_step Updating $ssl_certs_keydir/$cert_file$cert_keyfile_ext..."; cp -p $i $ssl_certs_keydir/$cert_file$cert_keyfile_ext; \
	chmod 400 $ssl_certs_keydir/$cert_file$cert_keyfile_ext >&2; }
done

	# Check whether mail server certficate has been renewed
	dane_file_date_new=$(date -r $dane_keyfile +%s)
	if [ $dane_file_date_new -gt $dane_file_date_old ]; then
		dane_record=$(postfix tls output-server-tlsa $dane_keyfile | sed -e "1d;s/IN/$dane_ttl/")
		msg_formatted "$i_step Updating DANE RR: $dane_record"
		{ echo "update add $dane_record"; echo send; echo quit; } | nsupdate -v -k $dane_nsupdate_key
	fi

	# Check whether LDAP certificate has been renewed
	ldap_file_date_new=$(date -r $ldap_keyfile +%s)
	if [ $ldap_file_date_new -gt $ldap_file_date_old ]; then
	{ msg_formatted "$i_step Updating LDAP Key: $ldap_keyfile"; cp -p $ldap_keyfile $ldap_certs_dir/$ldap_private_key; \
	chmod 400 $ldap_certs_dir/$ldap_private_key; chgrp openldap: $ldap_certs_dir/$ldap_private_key >&2; }
	fi
