$TTL 86400
@   IN  SOA     ns1.example.com. admin.example.com. (
                2023101001 ; Serial
                3600       ; Refresh
                1800       ; Retry
                1209600    ; Expire
                86400 )    ; Minimum TTL

    IN  NS      ns1.example.com.
    IN  NS      ns2.example.com.

ns1 IN  A       10.10.1.21
ns2 IN  A       10.10.1.21

www IN  A       192.0.2.3
ftp IN  CNAME   www
mail IN  A      192.0.2.4
     IN  MX 10  mail.example.com.