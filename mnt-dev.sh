#!/bin/bash

# The script mount devices in /mnt:
PNT="mnt"

mount-error () {
  echo "$1"
  sudo rmdir "${B1[i]}"
}

mount-a1 () {
  for i in "${!A1[@]}"; do
    unset {MQ,CL}
    echo "Mount ${A1[i]} at ${B1[i]}? [y/n]"
    read -r MQ
    if [ "$MQ" = y ]; then
      if [ ! -d "${B1[i]}" ]; then
        sudo mkdir -p "${B1[i]}"
      fi
      CL="$(lsblk -npo FSTYPE "${A1[i]}")"
      if [ "$CL" = crypto_LUKS ]; then
        if [ -L "/dev/mapper/${A1[$i]:5}" ]; then
          mount-error "${A1[$i]:5} already exists!"
        else
          if ! sudo cryptsetup open "${A1[i]}" "${A1[$i]:5}"; then
            mount-error "Failed to open /dev/mapper/${A1[$i]:5}!"
          fi
          if ! sudo mount /dev/mapper/"${A1[$i]:5}" "${B1[i]}" 2>/dev/null; then
            mount-error "Failed to mount ${A1[i]}!"
          fi
        fi
      else
        if ! sudo mount "${A1[i]}" "${B1[i]}" 2>/dev/null; then
          mount-error "Failed to mount ${A1[i]}!"
        fi
      fi
    fi
  done
}

unmount-a2 () {
  for i in "${!A2[@]}"; do
    unset UQ
    echo "Unmount ${A2[i]} at ${B2[i]}? [y/n]"
    read -r UQ
    if [ "$UQ" = y ]; then
      if ! sudo umount "${B2[i]}"; then
        echo "Failed to unmount ${A2[i]}!"
      else
        if [ -L "/dev/mapper/${A2[$i]:5}" ]; then
          if ! sudo cryptsetup close "${A2[$i]:5}"; then
            echo "Failed to close /dev/mapper/${A2[$i]:5}!"
          fi
        fi
        if [ -d "${B2[i]}" ]; then
          sudo rmdir "${B2[i]}"
        fi
      fi
    fi
  done
}

list-a1 () {
  for i in "${!A1[@]}"; do
    printf '\t%s\n' "$((N += 1)). Mount ${A1[$i]} at ${B1[$i]}"
  done
}

list-a2 () {
  for i in "${!A2[@]}"; do
    printf '\t%s\n' "$((N += 1)). Unmount ${A2[$i]} at ${B2[$i]}"
  done
}

prune-a1 () {
  TempA="${A1[(($OP - 1))]}"
  TempB="${B1[(($OP - 1))]}"
  unset {A1,B1}
  A1[0]="$TempA"
  B1[0]="$TempB"
}

prune-a2 () {
  TempA="${A2[(($OP - "${#A1[*]}" - 1))]}"
  TempB="${B2[(($OP - "${#A1[*]}" - 1))]}"
  unset {A2,B2}
  A2[0]="$TempA"
  B2[0]="$TempB"
}

menu () {
  until [[ "$OP" =~ ^[1-9]+$ ]] && [ "$OP" -le "$N" ]; do
    printf '%s\n\n' "Please choose:"
    if [ "${#A1[*]}" -ge 1 ]; then
      list-a1
    fi
    if [ "${#A2[*]}" -ge 1 ]; then
      list-a2
    fi
    if [ "${#A1[*]}" -gt 1 ]; then
      printf '\t%s\n' "$((N += 1)). Mount all listed devices"
    fi
    if [ "${#A2[*]}" -gt 1 ]; then
      printf '\t%s\n' "$((N += 1)). Unmount all listed devices"
    fi
    printf '\t%s\n' "$((N += 1)). Exit"
    read -r OP
    if [ "$OP" = "$N" ]; then
      exit 1
    elif [[ "$OP" =~ ^[1-9]+$ ]] && [ "$OP" -le "${#A1[*]}" ]; then
      prune-a1
      mount-a1
    elif [[ "$OP" =~ ^[1-9]+$ ]] && [ "$OP" -gt "${#A1[*]}" ] && [ "$OP" -le "$((${#A1[*]} + ${#A2[*]}))" ]; then
      prune-a2
      unmount-a2
    elif [[ "$OP" =~ ^[1-9]+$ ]] && [ "${#A1[*]}" -gt "1" ] && [ "$OP" -eq "$((${#A1[*]} + ${#A2[*]} + 1))" ]; then
      mount-a1
    elif [[ "$OP" =~ ^[1-9]+$ ]] && [ "${#A2[*]}" -gt "1" ] && [ "$OP" -lt "$N" ]; then
      unmount-a2
    fi
  done
}

loop-menu () {
  printf '\n%s\n' "Return to menu? [y/n]"
  read -r LOOP
  if [ "$LOOP" = y ]; then
    unset {A1,A2,B1,B2,N,OP}
    arrays-a
    arrays-b

# Go to chk-menu here, not menu. Why? Because at this point, you might
# have unmounted and removed a device and plugged another in.

    chk-menu
  fi
}

chk-menu () {
  if [ "${#A1[*]}" -eq 1 ] && [ "${#A2[*]}" -eq 0 ]; then
    mount-a1
  elif [ "${#A1[*]}" -eq 0 ] && [ "${#A2[*]}" -eq 1 ]; then
    unmount-a2
  else
    menu
    loop-menu
  fi
}

chk-a1-arg () {
  if [ "$1" = all ]; then
    if [ "${#A1[*]}" -eq 0 ]; then
      echo "All connected devices are mounted!"
      exit 1
    else
      mount-a1
    fi
  else
    for i in "${A2[@]}"; do
      if [ "$i" = "$1" ]; then
        echo "'$1' is mounted!"
        exit 1
      fi
    done
    for i in "${A1[@]}"; do
      if [ "$i" = "$1" ]; then
        unset {A1,B1}
        A1[0]="$1"
        B1[0]="/$PNT/${A1[0]:5}"
        mount-a1
        break;
      fi
    done
    if [ "${A1[0]}" != "$1" ]; then
      echo "No '$1' found!"
      exit 1
    fi
  fi
}

chk-a2-arg () {
  if [ "$1" = all ]; then
    if [ "${#A2[*]}" -eq 0 ]; then
      echo "No connected devices are mounted!"
      exit 1
    else
      unmount-a2
    fi
  else
    for i in "${A1[@]}"; do
      if [ "$i" = "$1" ]; then
        echo "'$1' is not mounted!"
        exit 1
      fi
    done
    for i in "${A2[@]}"; do
      if [ "$i" = "$1" ]; then
        unset {A2,B2}
        A2[0]="$1"
        B2[0]="$(lsblk -no MOUNTPOINT "${A2[0]}" | tail -1)"
        unmount-a2
        break;
      fi
    done
    if [ "${A2[0]}" != "$1" ]; then
      echo "No '$1' found!"
      exit 1
    fi
  fi
}

arrays-a () {
  readarray -t A1 < <(lsblk -po NAME,FSTYPE | grep -vE "^/dev/sd[b-z]\s+$" | grep -oE "/dev/sd[b-z][1-9]|/dev/sd[b-z]")
  if [ "${#A1[*]}" -eq 0 ]; then
    echo "No connected devices!"
    exit 1
  else
    for i in "${A1[@]}"; do
      if [ "$(lsblk -no MOUNTPOINT "$i")" ]; then
        A2+=("$i")
        for j in "${!A1[@]}"; do
          if [ "${A1[$j]}" = "$i" ]; then
            unset "A1[$j]"
            A1=("${A1[@]}")
          fi
        done
      fi
    done
  fi
}

arrays-b () {
  for i in "${!A1[@]}"; do
    B1+=("/$PNT/${A1[$i]:5}")
  done
  for i in "${!A2[@]}"; do
    B2+=("$(lsblk -no MOUNTPOINT "${A2[$i]}" | tail -1)")
  done
}

arrays-a
arrays-b
case $1 in
  mount) chk-a1-arg "$2" ;;
  unmount | umount) chk-a2-arg "$2" ;;
  *) chk-menu ;;
esac
