# Test TLS 1.0 (doit échouer)
echo | openssl s_client -connect shop.client.fr:443 -tls1 2>&1 | grep -E "(handshake failure|alert)"

# Test TLS 1.2 (doit réussir)
echo | openssl s_client -connect shop.client.fr:443 -tls1_2 2>&1 | grep "Verify return code"
Résultat attendu :
# TLS 1.0
... handshake failure ...

# TLS 1.2
Verify return code: 0 (ok)
