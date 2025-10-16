#!/bin/bash
# sys_manager.sh - Midsem Shell Script
# does system tasks like user add, report, etc

# colors
R='\033[0;31m'
G='\033[0;32m'
Y='\033[1;33m'
C='\033[0;36m'
N='\033[0m'

# check root
if [ $EUID -ne 0 ]; then
  echo -e "${R}Run as root${N}"
  exit 1
fi


# ---------- add users ----------
add_users() {
  f=$1
  if [ ! -f "$f" ]; then
    echo "File not found!"
    exit 1
  fi
  while read u; do
    [ -z "$u" ] && continue
    if id "$u" &>/dev/null; then
      echo -e "${Y}$u exists${N}"
    else
      useradd -m "$u" && echo -e "${G}User $u added${N}"
    fi
  done < "$f"
}

# ---------- setup projects ----------
setup_projects() {
  user=$1
  num=$2
  if ! id "$user" &>/dev/null; then
    echo "No such user"
    exit 1
  fi
  if ! [[ "$num" =~ ^[0-9]+$ ]]; then
    echo "Invalid number"
    exit 1
  fi
  base="/home/$user/projects"
  mkdir -p "$base"
  for ((i=1;i<=num;i++)); do
    p="$base/project$i"
    mkdir -p "$p"
    echo "Project $i created on $(date)" > "$p/README.txt"
    chmod 755 "$p"
    chmod 640 "$p/README.txt"
    chown -R "$user:$user" "$p"
    echo "Made $p"
  done
}

# ---------- sys report ----------
sys_report() {
  out=$1
  echo "System report at $(date)" > "$out"
  echo "Disk:" >> "$out"
  df -h >> "$out"
  echo "" >> "$out"
  echo "Memory:" >> "$out"
  free -h >> "$out"
  echo "" >> "$out"
  echo "CPU Info:" >> "$out"
  lscpu | grep "Model name" >> "$out"
  echo "" >> "$out"
  echo "Top 5 MEM procs:" >> "$out"
  ps -eo pid,comm,%mem --sort=-%mem | head -6 >> "$out"
  echo "" >> "$out"
  echo "Top 5 CPU procs:" >> "$out"
  ps -eo pid,comm,%cpu --sort=-%cpu | head -6 >> "$out"
  echo -e "${G}Report saved to $out${N}"
}
# ---------- process manage ----------
process_manage() {
  u=$1
  a=$2
  if ! id "$u" &>/dev/null; then
    echo "Invalid user"
    exit 1
  fi

  case $a in
    list_zombies)
      ps -u "$u" -o pid,stat,comm | awk '$2=="Z"{print}'
      ;;
    list_stopped)
      ps -u "$u" -o pid,stat,comm | awk '$2~/T/{print}'
      ;;
    kill_zombies)
      echo "Cannot kill zombie directly"
      ;;
    kill_stopped)
      ps -u "$u" -o pid,stat | awk '$2~/T/{print $1}' | xargs -r kill -9
      echo "Stopped processes killed"
      ;;
    *)
      echo "Wrong action"
      ;;
  esac
}

# ---------- permission & owner ----------
perm_owner() {
  u=$1
  p=$2
  per=$3
  o=$4
  g=$5
  if [ ! -e "$p" ]; then
    echo "Path not found"
    exit 1
  fi
  chmod -R "$per" "$p"
  chown -R "$o:$g" "$p"
  echo "Updated permissions and ownership"
  ls -ld "$p"
}



# ---------- help ----------
show_help() {
  echo "Usage: ./sys_manager.sh <method> [arguments]"
  echo ""
  echo "Mothods Available:"
  echo "  add_users file : "
  echo "  setup_projects user count"
  echo "  sys_report outfile"
  echo "  process_manage user action"
  echo "  perm_owner user path perm owner group"
  echo "  show_help : To get help"
}

case "$1" in
  add_users) add_users "$2" ;;
  setup_projects) setup_projects "$2" "$3" ;;
  sys_report) sys_report "$2" ;;
  process_manage) process_manage "$2" "$3" ;;
  perm_owner) perm_owner "$2" "$3" "$4" "$5" "$6" ;;
  show_help) show_help ;;
  *) echo "Invalid mothod, use method show_help to get a guide";;
esac
