az network public-ip show \
  --name pip-agw-client-prod-westeu \
  --resource-group rg-client-network-prod-westeu \
  --query "{sku:sku.name, zones:zones}" -o json
