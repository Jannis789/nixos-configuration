fastfetch

source ~/.config/.bash_aliases

source ~/.config/.bash_env

# source blesh
[[ $- == *i* ]] && source "$(blesh-share)"/ble.sh --noattach
[[ ! ''${BLE_VERSION-} ]] || ble-attach