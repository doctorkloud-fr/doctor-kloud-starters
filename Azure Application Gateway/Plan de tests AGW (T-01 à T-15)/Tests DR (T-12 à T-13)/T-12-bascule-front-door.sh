# Étape 1 — désactiver l'origin primaire
az afd origin update \
  --resource-group rg-client-frontdoor-prod \
  --profile-name afd-client-global \
  --origin-group-name og-default \
  --origin-name origin-primary-westeu \
  --enabled-state Disabled

# Étape 2 — mesurer le temps de bascule depuis un poste utilisateur
START=$(date +%s)
while true; do
  RESPONSE=$(curl -sf -H "x-debug-region: 1" https://shop.client.fr/health 2>/dev/null)
  if echo "$RESPONSE" | grep -q "northeu"; then
    END=$(date +%s)
    echo "Bascule : $((END - START)) secondes"
    break
  fi
  sleep 1
done
