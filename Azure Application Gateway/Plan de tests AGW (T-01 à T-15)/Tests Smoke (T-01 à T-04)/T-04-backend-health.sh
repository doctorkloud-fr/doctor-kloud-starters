az network application-gateway show-Backend-health \
  --name agw-client-prod-westeu \
  --resource-group rg-client-network-prod-westeu \
  --query "BackendAddressPools[].BackendHttpSettingsCollection[].servers[?health!='Healthy']" \
  -o table
