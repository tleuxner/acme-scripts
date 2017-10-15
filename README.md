# acme-scripts
Helper scripts for the ACME-client [dehydrated](https://github.com/lukas2511/dehydrated).

`upssl.sh` will walk through the dehydrated certs directory structure and copy new **Let's Encrypt** certificates to the server's ssl repository. New certificates will be added and renewed ones will be replaced.

    /etc/dehydrated/certs/
    ├── host.example.com
    │   ├── fullchain.pem -> /etc/ssl/certs/host_example_com_ACME.pem
    │   └── privkey.pem   -> /etc/ssl/private/host_example_com_ACME.key
    └── host.example1.com
        ├── fullchain.pem
        └── privkey.pem

Add dedicated nsupdate key to Bind configuration for the DANE resource record (optional):

    dnssec-keygen -a hmac-md5 -b 512 -r /dev/urandom -n HOST host.example.com

Bind configuration snippet for zone containing MX:

    update-policy { grant host.example.com. name _25._tcp.host.example.com. TLSA; };
