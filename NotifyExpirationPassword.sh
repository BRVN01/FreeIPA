#!/usr/bin/bash

init() {
#    declare -a days
#    declare -a expiration
    position=0

    export log_file='/var/log/idm_notify_expiration.log'

    # Dias para notificar (60, 30, 14, 3 e 1):
    days="$(date -d "+60 day" +%Y%m%d) $(date -d "+30 day" +%Y%m%d) $(date -d "+14 day" +%Y%m%d) $(date -d "+3 day" +%Y%m%d) $(date -d "+1 day" +%Y%m%d)" 
#    users=$(ldapsearch -x -w $(cat /root/.confignotify.conf) -D uid=usertest,cn=sysaccounts,cn=etc,dc=maddogs,dc=br -H ldaps://idm.maddogs.br uid=* uid givenName mail krbPasswordExpiration)

    # Usando keytab:
    kdestroy
    kinit -k -t /keytab.file USERNAME
    users=$(ldapsearch -LLL -b "cn=users,cn=accounts,dc=maddogs,dc=br"  'uid=*' uid givenName mail krbPasswordExpiration 2>/dev/null)
    kdestroy


    for day in ${days[@]}; do

        if [[ $(grep "${day}" <<<"${users}") ]]; then

            for quantity in $(seq 1 $(grep -c "${day}" <<<"${users}")); do
                expiration[$position]="$(grep -m${quantity} -B3 "${day}" <<<"${users}" | tail -n4 | sed 's/uid: //g; s/givenName: //g; s/mail: //g; s/krbPasswordExpiration: //g' | paste -sd' ')"
                position=$((++position))
            done
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
    template=$(source "template")
    [[ $? -ne 0 ]] && echo "Erro no Script!" && exit 1

    for s in ${!expiration[@]}; do
        #echo ${expiration[$s]}

        while read uid name mail date; do
            dateutc=$(date -d "$(echo "${date}" | awk '{print substr($0,1,4)"/"substr($0,5,2)"/"substr($0,7,2)" "substr($0,9,2)":"substr($0,11,2)":"substr($0,13,2)}')" +'%d/%m/%Y %H:%M:%S %Z')
            template=$(source "template")

            echo "${template}" 
        done <<<${expiration[$s]}
        echo -e "\n\n"
    done
}

send() {
    template=$(source "template")
    [[ $? -ne 0 ]] && echo "Erro no Script!" >> ${log_file} && exit 1

    for s in ${!expiration[@]}; do

        while read uid name mail date; do
            dateutc=$(date -d "$(echo "${date}" | awk '{print substr($0,1,4)"/"substr($0,5,2)"/"substr($0,7,2)" "substr($0,9,2)":"substr($0,11,2)":"substr($0,13,2)}')" +'%d/%m/%Y %H:%M:%S %Z')
            template=$(source "template")

#            echo "${template}" | mail -r "noreply@registro.br" -s "[NOTIFICAÇÃO] Sua senha de e-mail vai expirar em breve" ${mail} && echo "[$(date +%Y-%m-%d\ %H:%M:%S)] ${uid}" >> ${log_file}
        done <<<${expiration[$s]}
    done
}

[[ -z $1 ]] && init && send
[[ $1 = 'dry' ]] && init && show
[[ $1 = 'dry-verbose' ]] && init && show_verbose
