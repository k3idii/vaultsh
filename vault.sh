#!/bin/bash

VALUT_DIR="~/.vaultsh/"
mkdir -p ${VALUT_DIR}

function mkkey(){  echo "${1}" | md5sum | sed "s/ .*//" ; }
function make_secrets(){
    echo -en "Password?:" >&2; read -s XPASS < /dev/tty ; echo '  OK' >&2
    K=`mkkey "key_$XPASS"`
    IV=`mkkey "iv_$XPASS_iv"`
    unset XPASS
}

function clear_secrets(){
  unset K IV
}

function fail(){ echo "[!] $1"; exit 1; }

if [[ $# -lt 2 ]]; then
 fail "Bad number of arguments ($#)!"
fi

KEY="${2}"
FILE="${VALUT_DIR}/${KEY}"


case "${1}" in
  "get"|"export")
    if [ ! -f ${FILE} ]; then
        fail "No such slot : ${KEY}"
    fi
    make_secrets
    case "${1}" in
      "get")
         cat $FILE | base64 -d | openssl aes-256-cbc -d -K $K -iv $IV
      ;;
      "export")
        if [[ "${3}" == "" ]]; then
          fail "Need variable name !!!";
        fi
        VALUE=`cat $FILE | base64 -d | openssl aes-256-cbc -d -K $K -iv $IV`
        export "${3}='${VALUE}'"
        unset VALUE
      ;;
    esac
    clear_secrets
    ;;
  "set")
    if [ -f ${FILE} ]; then
      if [[ "${3}" == "-y" ]]; then
        echo "[i] Will override"
      else
        fail "[!] Key exists, ues -y to override !"
      fi
    fi
    make_secrets
    echo "[<] enter secret (stdin, EOF terminated):"
    cat - | openssl aes-256-cbc -K $K -iv $IV | base64 > $FILE
    clear_secrets
    echo "[+] OK, stored in '$KEY' slot"
    ;;
  "list")
      ls $VALUT_DIR
    ;;
  *)  echo "USAGE : ${0} [get|set|export|list] [slot]"
esac
