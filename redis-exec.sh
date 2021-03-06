#!/usr/bin/env bash
#
# Pull Redis stats to Collectd
#
# Basics from https://collectd.org/wiki/index.php/Plugin:exec-redis.sh
#
# (c) 2014, Benjamin Dos Santos <benjamin.dossantos@gmail.com>
# https://github.com/bdossantos/collectd-plugins
#

HOSTNAME="${COLLECTD_HOSTNAME:-$(hostname -f)}"
INTERVAL="${COLLECTD_INTERVAL:-10}"
PORT=6379

while true; do
  timestamp=$(date +%s)
  info=$(echo 'info' | nc -w1 127.0.0.1 $PORT)

  connected_clients=$(echo "$info" | awk -F : '$1 == "connected_clients" {print $2}')
  connected_slaves=$(echo "$info" | awk -F : '$1 == "connected_slaves" {print $2}')
  blocked_clients=$(echo "$info" | awk -F : '$1 == "blocked_clients" {print $2}')
  uptime=$(echo "$info" | awk -F : '$1 == "uptime_in_seconds" {print $2}')
  used_memory=$(echo "$info" | awk -F ":" '$1 == "used_memory" {print $2}'|sed -e 's/\r//')
  rdb_changes_since_last_save=$(echo "$info" | awk -F : '$1 == "rdb_changes_since_last_save" {print $2}')
  evicted_keys=$(echo "$info" | awk -F : '$1 == "evicted_keys" {print $2}')
  used_memory=$(echo "$info" | awk -F : '$1 == "used_memory" {print $2}')
  total_connections_received=$(echo "$info" | awk -F : '$1 == "total_connections_received" {print $2}')
  total_commands_processed=$(echo "$info" | awk -F : '$1 == "total_commands_processed" {print $2}')
  instantaneous_ops_per_sec=$(echo "$info" | awk -F : '$1 == "instantaneous_ops_per_sec" {print $2}')
  keys=$(echo "$info"|egrep -e "^db0" | sed -e 's/^.\+:keys=//'|sed -e 's/,.\+//')

  echo "PUTVAL ${HOSTNAME}/redis-${PORT}/gauge-connected_clients interval=${INTERVAL} ${timestamp}:${connected_clients}"
  echo "PUTVAL ${HOSTNAME}/redis-${PORT}/gauge-connected_slaves interval=${INTERVAL} ${timestamp}:${connected_slaves}"
  echo "PUTVAL ${HOSTNAME}/redis-${PORT}/gauge-blocked_clients interval=${INTERVAL} ${timestamp}:${blocked_clients}"
  echo "PUTVAL ${HOSTNAME}/redis-${PORT}/gauge-uptime_in_seconds interval=${INTERVAL} ${timestamp}:${uptime}"
  echo "PUTVAL ${HOSTNAME}/redis-${PORT}/gauge-used_memory interval=${INTERVAL} ${timestamp}:${used_memory}"
  echo "PUTVAL ${HOSTNAME}/redis-${PORT}/gauge-rdb_changes_since_last_save interval=${INTERVAL} ${timestamp}:${rdb_changes_since_last_save}"
  echo "PUTVAL ${HOSTNAME}/redis-${PORT}/gauge-evicted_keys interval=${INTERVAL} ${timestamp}:${evicted_keys}"
  echo "PUTVAL ${HOSTNAME}/redis-${PORT}/bytes-used_memory interval=${INTERVAL} ${timestamp}:${used_memory}"
  echo "PUTVAL ${HOSTNAME}/redis-${PORT}/counter-total_connections_received interval=${INTERVAL} ${timestamp}:${total_connections_received}"
  echo "PUTVAL ${HOSTNAME}/redis-${PORT}/counter-total_commands_processed interval=${INTERVAL} ${timestamp}:${total_commands_processed}"
  echo "PUTVAL ${HOSTNAME}/redis-${PORT}/gauge-instantaneous_ops_per_sec interval=${INTERVAL} ${timestamp}:${instantaneous_ops_per_sec}"
  echo "PUTVAL ${HOSTNAME}/redis-${PORT}/counter-items-db0 interval=${INTERVAL} ${timestamp}:${keys}"

  sleep "$INTERVAL"
done
