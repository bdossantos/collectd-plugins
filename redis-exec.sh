#!/usr/bin/env bash
# https://collectd.org/wiki/index.php/Plugin:exec-redis.sh

HOSTNAME="${COLLECTD_HOSTNAME:-$(hostname -f)}"
INTERVAL="${COLLECTD_INTERVAL:-10}"
PORT=6379

while sleep "$INTERVAL"; do
  info=$(echo 'info' | nc -w1 127.0.0.1 $PORT)

  connected_clients=$(echo "$info" | awk -F : '$1 == "connected_clients" {print $2}')
  connected_slaves=$(echo "$info" | awk -F : '$1 == "connected_slaves" {print $2}')
  uptime=$(echo "$info" | awk -F : '$1 == "uptime_in_seconds" {print $2}')
  used_memory=$(echo "$info" | awk -F ":" '$1 == "used_memory" {print $2}'|sed -e 's/\r//')
  changes_since_last_save=$(echo "$info" | awk -F : '$1 == "changes_since_last_save" {print $2}')
  total_commands_processed=$(echo "$info" | awk -F : '$1 == "total_commands_processed" {print $2}')
  keys=$(echo "$info"|egrep -e "^db0" | sed -e 's/^.\+:keys=//'|sed -e 's/,.\+//')

  echo "PUTVAL ${HOSTNAME}/redis-${PORT}/connected_clients interval=${INTERVAL} N:${connected_clients}"
  echo "PUTVAL ${HOSTNAME}/redis-${PORT}/connected_slaves interval=${INTERVAL} N:${connected_slaves}"
  echo "PUTVAL ${HOSTNAME}/redis-${PORT}/uptime_in_seconds interval=${INTERVAL} N:${uptime}"
  echo "PUTVAL ${HOSTNAME}/redis-${PORT}/used_memory interval=${INTERVAL} N:${used_memory}:U"
  echo "PUTVAL ${HOSTNAME}/redis-${PORT}/changes_since_last_save interval=${INTERVAL} N:${changes_since_last_save}"
  echo "PUTVAL ${HOSTNAME}/redis-${PORT}/total_commands_processed interval=${INTERVAL} N:${total_commands_processed}"
  echo "PUTVAL ${HOSTNAME}/redis-${PORT}/items-db0 interval=${INTERVAL} N:${keys}"
done
