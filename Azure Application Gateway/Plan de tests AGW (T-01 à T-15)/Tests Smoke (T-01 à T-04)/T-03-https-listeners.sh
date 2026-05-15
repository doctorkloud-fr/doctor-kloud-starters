for HOSTNAME in shop.client.fr api.client.fr admin.client.fr; do
  STATUS=$(curl -sI -o /dev/null -w "%{http_code}" "https://${HOSTNAME}/")
  echo "${HOSTNAME} : ${STATUS}"
done
