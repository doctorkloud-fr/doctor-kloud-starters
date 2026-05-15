# Le Backend doit retourner un header identifiant son pool
curl -sI https://shop.client.fr/health | grep -i "x-Backend-pool"
curl -sI https://api.client.fr/health | grep -i "x-Backend-pool"
