#!/usr/bin/env bash
# configure-static-ips.sh
# AlmaLinux 10 / NetworkManager (nmcli) compatible
# Supports --dry-run (prints commands, does not apply changes)
set -euo pipefail
DRY_RUN=0
usage() {
  cat <<'EOF'
Usage:
  sudo ./configure-static-ips.sh [--dry-run|-n] <IP[/CIDR]> [IP[/CIDR]] ...
Examples:
  sudo ./configure-static-ips.sh 192.168.10.50
  sudo ./configure-static-ips.sh 192.168.10.50/24 192.168.10.51/24
  sudo ./configure-static-ips.sh --dry-run 10.20.30.40/20 10.20.31.40
Notes:
  - If CIDR is omitted, script uses current adapter prefix if available, else /24.
  - Gateway is auto-detected from current default route on the selected adapter.
    If not found, it is derived from the first IP/CIDR (network first host).
EOF
}
err() { echo "ERROR: $*" >&2; exit 1; }
require_root() {
  (( DRY_RUN == 1 )) && return 0
  [[ ${EUID:-$(id -u)} -eq 0 ]] || err "Run as root (use sudo), or use --dry-run."
}
require_nmcli() {
  command -v nmcli >/dev/null 2>&1 || err "nmcli not found. Install/enable NetworkManager."
}
run_cmd() {
  if (( DRY_RUN == 1 )); then
    printf '[dry-run] '
    printf '%q ' "$@"
    printf '\n'
  else
    "$@"
  fi
}
is_valid_ipv4() {
  local ip="$1"
  [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1
  IFS='.' read -r o1 o2 o3 o4 <<<"$ip"
  for o in "$o1" "$o2" "$o3" "$o4"; do
    (( o >= 0 && o <= 255 )) || return 1
  done
}
is_valid_cidr() {
  local c="$1"
  [[ "$c" =~ ^[0-9]{1,2}$ ]] || return 1
  (( c >= 0 && c <= 32 ))
}
ip_to_int() {
  local ip="$1"
  IFS='.' read -r a b c d <<<"$ip"
  echo $(( (a << 24) | (b << 16) | (c << 8) | d ))
}
int_to_ip() {
  local n="$1"
  echo "$(( (n >> 24) & 255 )).$(( (n >> 16) & 255 )).$(( (n >> 8) & 255 )).$(( n & 255 ))"
}
derive_gateway_from_ip_cidr() {
  local ip="$1" cidr="$2"
  local ip_int mask network gw
  ip_int=$(ip_to_int "$ip")
  if (( cidr == 0 )); then
    IFS='.' read -r a b c _ <<<"$ip"
    echo "${a}.${b}.${c}.1"
    return
  fi
  mask=$(( (0xFFFFFFFF << (32 - cidr)) & 0xFFFFFFFF ))
  network=$(( ip_int & mask ))
  if (( cidr >= 31 )); then
    gw="$network"
  else
    gw=$(( network + 1 ))
  fi
  int_to_ip "$gw"
}
get_first_real_iface() {
  local iface
  for iface in $(ls /sys/class/net); do
    [[ "$iface" == "lo" ]] && continue
    [[ -e "/sys/class/net/$iface/device" ]] || continue
    echo "$iface"
    return 0
  done
  for iface in $(ls /sys/class/net); do
    [[ "$iface" == "lo" ]] && continue
    echo "$iface"
    return 0
  done
  return 1
}
main() {
  require_nmcli
  # Parse flags
  local -a positional=()
  while (( $# > 0 )); do
    case "$1" in
      --dry-run|-n) DRY_RUN=1; shift ;;
      --help|-h) usage; exit 0 ;;
      --) shift; while (( $# > 0 )); do positional+=("$1"); shift; done ;;
      -*) err "Unknown option: $1" ;;
      *) positional+=("$1"); shift ;;
    esac
  done
  (( ${#positional[@]} >= 1 )) || { usage; exit 1; }
  require_root
  local iface con_name current_prefix gateway first_ip first_cidr
  iface="$(get_first_real_iface)" || err "No non-loopback network adapter found."
  echo "Using adapter: $iface"
  con_name="$(nmcli -t -f NAME,DEVICE connection show --active | awk -F: -v d="$iface" '$2==d{print $1; exit}')"
  if [[ -z "${con_name:-}" ]]; then
    con_name="$(nmcli -t -f NAME,DEVICE connection show | awk -F: -v d="$iface" '$2==d{print $1; exit}')"
  fi
  if [[ -z "${con_name:-}" ]]; then
    con_name="static-${iface}"
    run_cmd nmcli connection add type ethernet ifname "$iface" con-name "$con_name" >/dev/null
  fi
  echo "Using connection profile: $con_name"
  current_prefix="$(ip -o -4 addr show dev "$iface" | awk '{print $4}' | head -n1 | cut -d/ -f2)"
  [[ -n "${current_prefix:-}" ]] || current_prefix="24"
  local -a normalized=()
  local arg ip cidr
  for arg in "${positional[@]}"; do
    if [[ "$arg" == */* ]]; then
      ip="${arg%/*}"
      cidr="${arg#*/}"
      is_valid_ipv4 "$ip" || err "Invalid IPv4 address: $ip"
      is_valid_cidr "$cidr" || err "Invalid CIDR: $cidr (must be 0-32)"
      normalized+=("${ip}/${cidr}")
    else
      ip="$arg"
      is_valid_ipv4 "$ip" || err "Invalid IPv4 address: $ip"
      normalized+=("${ip}/${current_prefix}")
    fi
  done
  gateway="$(ip route show default dev "$iface" | awk '{print $3; exit}')"
  if [[ -z "${gateway:-}" ]]; then
    first_ip="${normalized[0]%/*}"
    first_cidr="${normalized[0]#*/}"
    gateway="$(derive_gateway_from_ip_cidr "$first_ip" "$first_cidr")"
  fi
  run_cmd nmcli connection modify "$con_name" ipv4.method manual ipv4.addresses "${normalized[0]}"
  if (( ${#normalized[@]} > 1 )); then
    local i
    for (( i=1; i<${#normalized[@]}; i++ )); do
      run_cmd nmcli connection modify "$con_name" +ipv4.addresses "${normalized[$i]}"
    done
  fi
  run_cmd nmcli connection modify "$con_name" ipv4.gateway "$gateway"
  run_cmd nmcli connection modify "$con_name" ipv4.dns "8.8.8.8 8.8.4.4"
  run_cmd nmcli connection modify "$con_name" ipv4.ignore-auto-dns yes
  run_cmd nmcli connection modify "$con_name" connection.autoconnect yes
  run_cmd nmcli connection down "$con_name"
  run_cmd nmcli connection up "$con_name"
  echo
  echo "Planned/Applied configuration:"
  echo "  Interface : $iface"
  echo "  Connection: $con_name"
  echo "  Addresses : ${normalized[*]}"
  echo "  Gateway   : $gateway"
  echo "  DNS       : 8.8.8.8, 8.8.4.4"
  (( DRY_RUN == 1 )) && echo "  Mode      : dry-run (no changes applied)"
}
main "$@"
