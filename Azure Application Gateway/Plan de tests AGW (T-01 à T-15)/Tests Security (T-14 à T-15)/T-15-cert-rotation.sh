# Étape 1 — capturer le thumbprint actuel servi par l'AGW
THUMBPRINT_AVANT=$(echo | openssl s_client -connect shop.client.fr:443 \
  -servername shop.client.fr 2>/dev/null | \
  openssl x509 -fingerprint -noout | cut -d= -f2)
echo "Thumbprint avant : ${THUMBPRINT_AVANT}"

# Étape 2 — importer une nouvelle version dans Key Vault
az keyvault certificate import \
  --vault-name kv-client-tls-prod \
  --name cert-Wildcard-client \
  --file new-cert.pfx \
  --password "$CERT_PASSWORD"

# Étape 3 — attendre 4h puis re-capturer le thumbprint
# (à exécuter dans un cron ou manuellement)
sleep 14400
THUMBPRINT_APRES=$(echo | openssl s_client -connect shop.client.fr:443 \
  -servername shop.client.fr 2>/dev/null | \
  openssl x509 -fingerprint -noout | cut -d= -f2)
echo "Thumbprint après 4h : ${THUMBPRINT_APRES}"

# Étape 4 — comparer
if [ "$THUMBPRINT_AVANT" != "$THUMBPRINT_APRES" ]; then
  echo "Rotation propagée avec succès"
else
  echo "Rotation non propagée — investigation requise"
fi
