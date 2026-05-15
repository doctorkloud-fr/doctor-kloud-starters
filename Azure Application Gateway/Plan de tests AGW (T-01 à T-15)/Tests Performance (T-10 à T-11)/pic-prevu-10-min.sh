az load test-run create \
  --test-id "test-agw-pic-80pct" \
  --test-run-id "tr-$(date +%Y%m%d-%H%M%S)" \
  --resource-group rg-client-loadtest-prod-westeu \
  --load-test-resource lt-client-prod-westeu \
  --display-name "AGW pic 80% — 10min"

# Récupérer les résultats après exécution
az load test-run show \
  --test-run-id "<id-précédent>" \
  --resource-group rg-client-loadtest-prod-westeu \
  --load-test-resource lt-client-prod-westeu \
  --query "testRunStatistics" -o json
