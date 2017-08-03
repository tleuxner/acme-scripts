#!/bin/sh
set -e
# Copy certificates acquired by https://github.com/lukas2511/dehydrated 
# to the server's SSL directories e.g. /etc/ssl/*
# Thomas Leuxner <tlx@leuxner.net> 03-08-2017

acme_certs_dir='/etc/dehydrated/certs'
cert_file_ext='_ACME.pem'
cert_keyfile_ext='_ACME.key'
ssl_certs_dir='/etc/ssl/certs'
ssl_certs_keydir='/etc/ssl/private'

msg_formatted() {
	echo "[>] $*"
}
 
for i in $(find $acme_certs_dir -name fullchain.pem) 
	do 
	# split out certificate name from path and replace dots with underscores
	cert_file=$(echo $i | awk -F/ '{ gsub ("\.","_"); print $5 }') 
	# certificate is new?
	[ -f "$ssl_certs_dir/$cert_file$cert_file_ext" ] || \
	{ msg_formatted "New certficate $ssl_certs_dir/$cert_file$cert_file_ext..."; touch -d "1 hour ago" $ssl_certs_dir/$cert_file$cert_file_ext  >&2; } 
	# certificate is a renewal?
	[ "$i" -nt $ssl_certs_dir/$cert_file$cert_file_ext ] && \
	{ msg_formatted "Updating $ssl_certs_dir/$cert_file$cert_file_ext..."; cp -p $i $ssl_certs_dir/$cert_file$cert_file_ext; \
	chmod 644 $ssl_certs_dir/$cert_file$cert_file_ext >&2; }
done

for i in $(find $acme_certs_dir -name privkey.pem) 
	do 
	cert_file=$(echo $i | awk -F/ '{ gsub ("\.","_"); print $5 }') 
	[ -f "$ssl_certs_keydir/$cert_file$cert_keyfile_ext" ] || \
	{ msg_formatted "New key $ssl_certs_keydir/$cert_file$cert_keyfile_ext..."; touch -d "1 hour ago" $ssl_certs_keydir/$cert_file$cert_keyfile_ext  >&2; } 
	[ "$i" -nt $ssl_certs_keydir/$cert_file$cert_keyfile_ext ] && \
	{ msg_formatted "Updating $ssl_certs_keydir/$cert_file$cert_keyfile_ext..."; cp -p $i $ssl_certs_keydir/$cert_file$cert_keyfile_ext; \
	chmod 600 $ssl_certs_keydir/$cert_file$cert_keyfile_ext >&2; }
done
