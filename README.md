# acme-scripts
Helper scripts for the ACME-client.

`upssl` will walk through the dehydrated certs directory structure and copy new **Let's Encrypt** certificates to the server's ssl repository. New certificates will be added and renewed ones will be replaced.

    /etc/dehydrated/certs/
    ├── host.example.com
    │   ├── fullchain.pem -> /etc/ssl/certs/host_example_com_ACME.pem
    │   └── privkey.pem   -> /etc/ssl/private/host_example_com_ACME.key
    └── host.example1.com
        ├── fullchain.pem
        └── privkey.pem
