#!/bin/bash

# ipa user-mod --password-expiration=2023-05-22Z fulano
# ipa user-mod --password-expiration='2023-05-22 18:35:10Z' fulano

init() {
#    declare -a days
#    declare -a expiration
#    position=0

    export log_file='/var/log/idm_expiration_notify.log'

    # Dias para notificar (60, 30, 14, 3 e 1):
    days="$(date -d "+60 day" +%Y%m%d) $(date -d "+30 day" +%Y%m%d) $(date -d "+14 day" +%Y%m%d) $(date -d "+3 day" +%Y%m%d) $(date -d "+1 day" +%Y%m%d)"
    users=$(ldapsearch -x -w $(cat /root/.confignotify.conf) -D uid=usertest,cn=sysaccounts,cn=etc,dc=maddogs,dc=br -H ldaps://idm.maddogs.br uid=* uid givenName mail krbPasswordExpiration)

#   Another way:
#   kdestroy
#   kinit -k -t FILENAME USERNAME
#   users$(ldapsearch -Y GSSAPI -b "cn=users,cn=accounts,dc=maddogs,dc=br"  uid=* uid givenName mail krbPasswordExpiration)
#   kdestroy

    for day in ${days[@]}; do

        if [[ $(grep -B1 "${day}" <<<"${users}") ]]; then
            expiration[$position]="$(grep -B3 "${day}" <<<${users} | sed 's/uid: //g; s/givenName: //g; s/mail: //g; s/krbPasswordExpiration: //g' | paste -sd' ')"
            position=$((++position))
        fi
    done

    export expiration
}

show() {
    for s in ${!expiration[@]}; do
        echo ${expiration[$s]}

        while read uid name mail date; do
            echo "UID=${uid} Name=${name} Email=${mail} Expiration=${date}"
            echo ""
        done <<<${expiration[$s]}
    done
}

show_verbose() {
    template=$(source "/root/.template")
    [[ $? -ne 0 ]] && echo "Erro no Script!" && exit 1

    for s in ${!expiration[@]}; do
        echo ${expiration[$s]}

        while read uid name mail date; do
            dateutc=$(date -d "$(echo "${date}" | awk '{print substr($0,1,4)"/"substr($0,5,2)"/"substr($0,7,2)" "substr($0,9,2)":"substr($0,11,2)":"substr($0,13,2)}')" +'%d/%m/%Y %H:%M:%S %Z')
            template=$(source "/root/.template")

            echo "${template}" 
        done <<<${expiration[$s]}
        echo -e "\n\n"
    done
}

send() {
    template=$(source "/root/.template")
    [[ $? -ne 0 ]] && echo "Erro no Script!" >> ${log_file} && exit 1

    for s in ${!expiration[@]}; do

        while read uid name mail date; do
            dateutc=$(date -d "$(echo "${date}" | awk '{print substr($0,1,4)"/"substr($0,5,2)"/"substr($0,7,2)" "substr($0,9,2)":"substr($0,11,2)":"substr($0,13,2)}')" +'%d/%m/%Y %H:%M:%S %Z')
            template=$(source "/root/.template")

            echo "${template}" | mail -r "noreply@DOMAIN" -s "[NOTIFICATION] Your password will expire soon" ${mail} && echo "[$(date +%Y-%m-%d\ %H:%M:%S)] ${uid}" >> ${log_file}
        done <<<${expiration[$s]}
    done
}

[[ -z $1 ]] && init && send
[[ $1 = 'dry' ]] && init && show
[[ $1 = 'dry-verbose' ]] && init && show_verbose
