#!/bin/bash

#########CONFIG##########
uSeRnAmE="${1}"
aCtIoN="${2}"
jAiLpAtH='/srv/JAILS'
lOgFiLe="${jAiLpAtH}/jailLog.log"
hOsTfIlEpAtH="accesible_clusters"
dEvElOpMeNt=false
#########################
#######ERROR CODES#######
# 001: Bad permissions
# 002: Bad usage (username)
# 003: Bad usage (action)
# 004: Whitespaces on input username
# 005: Unable to create Jails folder
#########################
####ERROR AND LOGGING####
logData(){
  local data_to_log="###############\n$(date +'%d/%m/%y %T')\n${1}\n###############"
  echo -e "${data_to_log}" >> ${lOgFiLe}
}
# error func (error msg, error code, exit code)
panicErr(){
  local err_file="${BASH_SOURCE[1]}";local err_func="${FUNCNAME[1]}";local err_msg="${1}";local err_code="${2}";local exit_code="${3}"
  data_to_log=$(cat<<EOF
ERROR:
    FILE:                    ${err_file}
    FUNCTION:                ${err_func}
    ERRORMSG:                ${err_msg}
    ERRORCODE:               ${err_code}
EOF
)
  logData "${data_to_log}"
  echo -e "\n${data_to_log}\n"
  exit $exit_code
}
#########################
######JAIL HANDLING######
# handle action create
createJail() {
    local uSeRnAmE="${1}"
    local tHiSjAiL="${jAiLpAtH}/${uSeRnAmE}"
    
    mkdir -p "${tHiSjAiL}"/{home,etc,bin,lib64,lib,usr,dev} 2>/dev/null
    mkdir -p "${tHiSjAiL}/home/${uSeRnAmE}"
    mkdir -p "${tHiSjAiL}/lib/x86_64-linux-gnu"
    mkdir -p "${tHiSjAiL}/usr/share"

    cd "${tHiSjAiL}/dev" 
    mknod -m 666 null c 1 3
    mknod -m 666 tty c 5 0
    mknod -m 666 zero c 1 5
    mknod -m 666 random c 1 8
    cd ${OLDPWD}

    useradd -s /bin/bash "${uSeRnAmE}"
    usermod -p '*' "${uSeRnAmE}"

    cp /bin/bash "${tHiSjAiL}/bin/"
    cp /lib64/ld-linux-x86-64.so.* "${tHiSjAiL}/lib64/"
    cp /lib/x86_64-linux-gnu/libtinfo.so.* "${tHiSjAiL}/lib/x86_64-linux-gnu/"
    cp /lib/x86_64-linux-gnu/libdl.so.* "${tHiSjAiL}/lib/"
    cp /lib/x86_64-linux-gnu/libc.so.* "${tHiSjAiL}/lib/"

    cp /bin/{ssh,scp,clear,nano,ls,cat,sh,mkdir} "${tHiSjAiL}/bin/"
    while read dep; do
        cp "${dep}" "${tHiSjAiL}/lib/x86_64-linux-gnu/" 2>/dev/null
    done < <(ldd /bin/scp | awk '{print $3}')

    cat <<EOF |base64 -d > "${tHiSjAiL}/home/${uSeRnAmE}/.bashrc"
Y2FzZSAkLSBpbgogICAgKmkqKSA7OwogICAgICAqKSByZXR1cm47Owplc2FjCgpISVNUQ09OVFJP
TD1pZ25vcmVib3RoCgpzaG9wdCAtcyBoaXN0YXBwZW5kCgpISVNUU0laRT0xMDAwCkhJU1RGSUxF
U0laRT0yMDAwCgpzaG9wdCAtcyBjaGVja3dpbnNpemUKCmNhc2UgIlhURVJNIiBpbgogICAgeHRl
cm0tY29sb3J8Ki0yNTZjb2xvcikgY29sb3JfcHJvbXB0PXllczs7CmVzYWMKCgpjYXNlICIkVEVS
TSIgaW4KeHRlcm0qfHJ4dnQqKQogICAgUFMxPSdTVEFSR0FURX4kOiAnCiAgICA7OwoqKQogICAg
OzsKZXNhYwoKaWYgWyAteCAvdXNyL2Jpbi9kaXJjb2xvcnMgXTsgdGhlbgogICAgdGVzdCAtciB+
Ly5kaXJjb2xvcnMgJiYgZXZhbCAiJChkaXJjb2xvcnMgLWIgfi8uZGlyY29sb3JzKSIgfHwgZXZh
bCAiJChkaXJjb2xvcnMgLWIpIgogICAgYWxpYXMgbHM9J2xzIC0tY29sb3I9YXV0bycKZmkKCmV4
cG9ydCBURVJNSU5GTz0vdXNyL3NoYXJlL3Rlcm1pbmZvCmV4cG9ydCBURVJNPXh0ZXJtLWJhc2lj
CgplY2hvIC1lICJcblxuIyMjIyNBdmFsaWFibGUgQ2x1c3RlcnMjIyMjI1xuIgpjYXQgL2V0Yy9o
b3N0cyB8d2hpbGUgcmVhZCBsaW5lIDsgZG8gZWNobyAkbGluZSA7IGRvbmUKZWNobyAtZSAiXG4i
Cg==
EOF

    cat <<EOF |base64 -d > "${tHiSjAiL}/home/${uSeRnAmE}/.bash_profile"
IyB+Ly5wcm9maWxlOiBleGVjdXRlZCBieSB0aGUgY29tbWFuZCBpbnRlcnByZXRlciBmb3IgbG9n
aW4gc2hlbGxzLgojIFRoaXMgZmlsZSBpcyBub3QgcmVhZCBieSBiYXNoKDEpLCBpZiB+Ly5iYXNo
X3Byb2ZpbGUgb3Igfi8uYmFzaF9sb2dpbgojIGV4aXN0cy4KIyBzZWUgL3Vzci9zaGFyZS9kb2Mv
YmFzaC9leGFtcGxlcy9zdGFydHVwLWZpbGVzIGZvciBleGFtcGxlcy4KIyB0aGUgZmlsZXMgYXJl
IGxvY2F0ZWQgaW4gdGhlIGJhc2gtZG9jIHBhY2thZ2UuCgojIHRoZSBkZWZhdWx0IHVtYXNrIGlz
IHNldCBpbiAvZXRjL3Byb2ZpbGU7IGZvciBzZXR0aW5nIHRoZSB1bWFzawojIGZvciBzc2ggbG9n
aW5zLCBpbnN0YWxsIGFuZCBjb25maWd1cmUgdGhlIGxpYnBhbS11bWFzayBwYWNrYWdlLgojdW1h
c2sgMDIyCgojIGlmIHJ1bm5pbmcgYmFzaAppZiBbIC1uICIkQkFTSF9WRVJTSU9OIiBdOyB0aGVu
CiAgICAjIGluY2x1ZGUgLmJhc2hyYyBpZiBpdCBleGlzdHMKICAgIGlmIFsgLWYgIiRIT01FLy5i
YXNocmMiIF07IHRoZW4KICAgICAgICAuICIkSE9NRS8uYmFzaHJjIgogICAgZmkKZmkKCiMgc2V0
IFBBVEggc28gaXQgaW5jbHVkZXMgdXNlcidzIHByaXZhdGUgYmluIGlmIGl0IGV4aXN0cwppZiBb
IC1kICIkSE9NRS9iaW4iIF0gOyB0aGVuCiAgICBQQVRIPSIkSE9NRS9iaW46JFBBVEgiCmZpCgoj
IHNldCBQQVRIIHNvIGl0IGluY2x1ZGVzIHVzZXIncyBwcml2YXRlIGJpbiBpZiBpdCBleGlzdHMK
aWYgWyAtZCAiJEhPTUUvLmxvY2FsL2JpbiIgXSA7IHRoZW4KICAgIFBBVEg9IiRIT01FLy5sb2Nh
bC9iaW46JFBBVEgiCmZpCg==
EOF
    
    cat /etc/passwd | grep "${uSeRnAmE}" > "${tHiSjAiL}/etc/passwd"
    cat /etc/group | grep "${uSeRnAmE}" > "${tHiSjAiL}/etc/group"
    cat /etc/shadow | grep "${uSeRnAmE}" > "${tHiSjAiL}/etc/shadow"

    cat <<EOF > "/etc/ssh/sshd_config.d/${uSeRnAmE}_Jail.conf"
    Match User ${uSeRnAmE}
    ChrootDirectory ${tHiSjAiL}
    AuthorizedKeysFile ${tHiSjAiL}/home/${uSeRnAmE}/.ssh/authorized_keys
    PubkeyAuthentication yes
    PasswordAuthentication no
    ClientAliveInterval 600
    ClientAliveCountMax 0
    KbdInteractiveAuthentication no
    Banner /etc/issue.net
EOF

    cat <<EOF > "${tHiSjAiL}/etc/hosts"
      $(cat ${hOsTfIlEpAtH})
EOF

    mkdir -p "${tHiSjAiL}/home/${uSeRnAmE}/.ssh"
    sudo -u "${uSeRnAmE}" ssh-keygen -t rsa -N '' -f "/tmp/${uSeRnAmE}_key" &> /dev/null

    mkdir -p "${jAiLpAtH}/JAILS_KEYS"
    mv "/tmp/${uSeRnAmE}_key" "${jAiLpAtH}/JAILS_KEYS/${uSeRnAmE}_key"
    mv "/tmp/${uSeRnAmE}_key.pub" "${tHiSjAiL}/home/${uSeRnAmE}/.ssh/authorized_keys"

    chown -R root:root "${tHiSjAiL}"
    chmod -R 'u=rwx,g=x,o=x' "${tHiSjAiL}"
    chmod -R 'u=rwx,g=rwx,o=rwx' "${tHiSjAiL}/dev"
    chmod -R 'u=rwx,g=xr,o=xr' "${tHiSjAiL}/"{lib,lib64,bin,etc,usr}
    chown -R "${uSeRnAmE}:${uSeRnAmE}" "${tHiSjAiL}/home/${uSeRnAmE}"
    chmod -R 'u=rwx,o=r,g=r' "${tHiSjAiL}/home/${uSeRnAmE}"

    chmod 700 "${tHiSjAiL}/home/${uSeRnAmE}/.ssh"
    chmod 600 "${tHiSjAiL}/home/${uSeRnAmE}/.ssh/authorized_keys"

    chattr +i "${tHiSjAiL}/home/${uSeRnAmE}/"{.bashrc,.bash_profile,.ssh/authorized_keys}

    logData "${uSeRnAmE} - Jail created successfully"
    service sshd reload
}
# handle action delete
deleteJail() {
    local tHiSjAiL="${jAiLpAtH}/${uSeRnAmE}"

    userdel "${uSeRnAmE}"
    if [ $? -ne 0 ]; then
        panic_err "Error al eliminar el usuario ${uSeRnAmE}" "DELETE_USER-001" "1"
    fi
    if [ -f "${tHiSjAiL}/home/${uSeRnAmE}/.bashrc" ]; then
        chattr -i "${tHiSjAiL}/home/${uSeRnAmE}/.bashrc"
    fi
    if [ -f "${tHiSjAiL}/home/${uSeRnAmE}/.bash_profile" ]; then
        chattr -i "${tHiSjAiL}/home/${uSeRnAmE}/.bash_profile"
    fi
    if [ -f "${tHiSjAiL}/home/${uSeRnAmE}/.ssh/authorized_keys" ]; then
        chattr -i "${tHiSjAiL}/home/${uSeRnAmE}/.ssh/authorized_keys"
    fi
    if [ -d "${tHiSjAiL}" ]; then
        rm -rf "${tHiSjAiL}"
    fi
    if [ -f "/etc/ssh/sshd_config.d/${uSeRnAmE}_Jail.conf" ]; then
        rm -f "/etc/ssh/sshd_config.d/${uSeRnAmE}_Jail.conf"
    fi
    if [ -f "${jAiLpAtH}/JAILS_KEYS/${uSeRnAmE}_key" ]; then
        rm -f "${jAiLpAtH}/JAILS_KEYS/${uSeRnAmE}_key"
    fi

    logData "${uSeRnAmE} - Deleted successfully"
    service sshd reload
}
##################################




# starting env
init() {
  if [ $dEvElOpMeNt = true ]; then
    set -x
    echo -e "Running Script:Debug Mode...\n"
    return
  fi
  echo -e "Running Script...\n"
}

# perform firsts checks (params, permissions, etc..)
checks() {
  ## Test if root permission
  [[ $(id -u) == "0" ]] || panicErr "This Script needs root privileges" "001" "2"
  ## Test for usage error
  [[ -z "${uSeRnAmE}" ]] && panicErr "Usage: ./${0##*/} *Username* add|delete || Ex: ./${0##*/} jdoe add" "002" "2"
  [[ -z "${aCtIoN}" ]] && panicErr "Need one more argument: username <add | delete>" "003" "2"
  ## Test no whitespaces
  [[ "${uSeRnAmE}" =~ \  ]] && panicErr "User name contains whitespaces" "004" "2"
  ## Test if jails directory exists
  [[ -d "${jAiLpAtH}" ]] || mkdir -p "${jAiLpAtH}/JAILS_KEYS" 2>/dev/null
  [[ -d "${jAiLpAtH}/JAILS_KEYS" ]] || panicErr "Unable to create jails directory on \'${jAiLpAtH}\'" "005" "2"
}

# validate action string is correct and user status
validateAction() {
  local user_exists
  id "${uSeRnAmE}" &>/dev/null
  user_exists=$?

  case "${aCtIoN}" in
    add)
      if [ ${user_exists} -eq 0 ]; then
        panicErr "User '${uSeRnAmE}' already exists. Cannot add." "003" "2"
      fi
      ;;
    delete)
      if [ ${user_exists} -ne 0 ]; then
        panicErr "User '${uSeRnAmE}' does not exist. Cannot delete." "003" "2"
      fi
      ;;
    *)
      panicErr "Invalid action '${aCtIoN}'. Allowed actions are: add | delete" "003" "2"
      ;;
  esac
}

# call action func based on input action
performAction() {
  case "${aCtIoN}" in
    add)
      createJail "${uSeRnAmE}"
      ;;
    delete)
      deleteJail "${uSeRnAmE}"
      ;;
    *)
      panicErr "unhandled exception, you shouldn't see that error never" "003" "2"
      ;;
  esac
}

# Log status ok, everything is working.
logEndStatusOK() {
  local msg="Operation '${aCtIoN}' for user '${uSeRnAmE}' completed successfully."
  logData "${msg}"
  echo -e "\n${msg}\n"
}


# starting Program...
## before start
init
## perform checks
checks
## verify action avaliability
validateAction # if action==add and user==!exists, do nothing;else don't add user and give usage error;fi (same with delete)
## perform action
performAction # switch case add:createJail;case del:deleteJail; esac
## log ending ok
logEndStatusOK
# ending Program....
## exit status ok
exit 0