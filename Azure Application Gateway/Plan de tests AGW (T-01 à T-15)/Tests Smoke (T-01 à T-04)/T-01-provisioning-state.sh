az network application-gateway show \
  --name agw-client-prod-westeu \
  --resource-group rg-client-network-prod-westeu \
  --query "provisioningState" -o tsv
