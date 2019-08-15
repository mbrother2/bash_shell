#!/bin/bash

USER_DIR="/usr/local/directadmin/data/users"
BASH_FILE="$0"

count_user(){
    cat ${USER_DIR}/*/user.conf | grep -c "^usertype=$1"
}

show_summary(){
    COUNT_USER=`count_user user`
    COUNT_RESELLER=`count_user reseller`
    COUNT_ADMIN=`count_user admin`
    echo ""
    echo "+ Summary:"
    echo "  Admin:    ${COUNT_ADMIN}"
    echo "  Reseller: ${COUNT_RESELLER}"
    echo "  User:     ${COUNT_USER}"
}

check_exist(){
    if [ ! -d ${USER_DIR}/$1 ]
    then
        echo "[Error] User $1 does not exists!"
        exit
    fi
}

check_user_type(){
    if [ -f ${USER_DIR}/$2/user.conf ]
    then
        USER_TYPE=`cat ${USER_DIR}/$2/user.conf | grep "^usertype=" | cut -d"=" -f2`
        if [ "${USER_TYPE}" != "$1" ]
        then
            echo "[Error] Wrong user type. $2 is ${USER_TYPE}"
            echo "Use: sh ${BASH_FILE} list ${USER_TYPE} $2"
            exit
        fi
    else
        echo "[Error] File ${USER_DIR}/$2/user.conf does not exist."
    fi
}

show_account(){
    echo ""
    echo "+ List $1:"
    for i in $(ls -1 ${USER_DIR})
    do
        if [ -f ${USER_DIR}/$i/user.conf ]
        then
            USER_TYPE=`cat ${USER_DIR}/$i/user.conf | grep "^usertype=$1" | cut -d"=" -f2`
            if [ "$USER_TYPE" == "$1" ]
            then
                if [ "$USER_TYPE" == "reseller" ]
                then
                    SUM_USER=`cat ${USER_DIR}/$i/users.list | wc -l`
                    echo "  $i(${SUM_USER})"
                else
                    echo "  $i"
                fi
            fi
        fi
    done
}

show_single_account(){
    echo ""
    check_exist $2
    check_user_type $1 $2
    if [ "$1" == admin ]
    then
        k=0
        rm -f /tmp/tmp_$2
        for m in $(ls -1 ${USER_DIR})
        do
            if [ -f ${USER_DIR}/$m/user.conf ]
            then
                USER_TYPE=`cat ${USER_DIR}/$m/user.conf | grep "^usertype=" | cut -d"=" -f2`
                if [ "${USER_TYPE}" == "reseller" ]
                then
                    CREATOR=`cat ${USER_DIR}/$m/user.conf | grep "^creator=" | cut -d"=" -f2`
                    if [ ${CREATOR} == "$2" ]
                    then
                        ((k++))
                         echo $m >> /tmp/tmp_$2
                    fi
                fi
            fi
        done
        if [ $k -gt 0 ]
        then
            echo "+ List resellers were created by $1 $2:"
            cat /tmp/tmp_$2 | sed 's/^/  /g' | pr -4 -t
            rm -f /tmp/tmp_$2
        else
            echo "[Warning] No resellers were created by $2"
        fi
    fi
    if [[ -f ${USER_DIR}/$2/users.list ]] && [[ $(cat ${USER_DIR}/$2/users.list) != "" ]]
    then
        echo "+ List users were created by $1 $2:"
        cat ${USER_DIR}/$2/users.list | sed 's/^/  /g' | pr -4 -t
    else
        echo "[Warning] No users were created by $2"
    fi
}

[[ -z $1 ]] && show_summary

if [ "$1" == "list" ]
then
    if [ -z $2 ]
    then
        for j in admin reseller user
        do
            show_account $j
        done
    else
        if [ -z $3 ]
        then
            show_account $2
        else
            show_single_account $2 $3
        fi
    fi
fi
