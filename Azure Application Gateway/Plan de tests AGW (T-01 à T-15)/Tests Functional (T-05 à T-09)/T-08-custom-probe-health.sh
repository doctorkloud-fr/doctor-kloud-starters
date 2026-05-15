# Depuis une VM du VNet (jumpbox), tester chaque Backend
for BACKEND in 10.40.10.4 10.40.10.5 10.40.10.6; do
  STATUS=$(curl -sk -o /dev/null -w "%{http_code}" "https://${BACKEND}/health")
  echo "${BACKEND} : ${STATUS}"
done
