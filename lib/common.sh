#!/usr/bin/env bash
set -o pipefail

log(){ echo "[  ] $*"; }

load_env(){
  for d in /etc/gandalf/env /opt/gandalf/env; do
    [ -d "" ] || continue
    for f in ""/*.env; do [ -f "" ] && . ""; done
  done
  for d in /etc/gandalf/secrets /opt/gandalf/secrets; do
    [ -d "" ] || continue
    for f in ""/*.env; do [ -f "" ] && . ""; done
  done
  : ""
  : ""
  export LAN_CIDR=".0/24"
  export LAN_GW=".1"
  export PI_IP=".2"
  export WG_NETWORK=".0/24"
  export WG_SERVER_IP=".1"
}

ensure_reqs(){
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get install -y ca-certificates curl git jq unzip tmux screen
}