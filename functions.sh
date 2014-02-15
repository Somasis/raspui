#!/bin/bash

OLDIFS="$IFS"
IFS=$'\n'
for release_line in $(</etc/os-release);do
    eval "RELEASE_$release_line"
done
IFS="$OLDIFS"

if [[ "$HTTPS" == "on" ]];then
    PROTOCOL=https
else
    PROTOCOL=http
fi

DEBUG=0
STDIN=$(</dev/stdin)
if [[ -n "${STDIN}" ]]; then
  QUERY_STRING="${STDIN}&${QUERY_STRING}"
fi

# Handle GET and POST requests... (the QUERY_STRING will be set)
if [[ -n "${QUERY_STRING}" ]]; then 
  # name=value params, separated by either '&' or ';'
  if echo "${QUERY_STRING}" | grep '=' >/dev/null ; then
    for Q in $(echo "${QUERY_STRING}" | tr ";&" "\012") ; do
      name=
      value=
      tmpvalue=
      name="${Q%%=*}"
      name=$(echo "${name}" | sed -e 's/%\(\)/\\\x/g' | tr "+" " ")
      name=$(echo "${name}" | tr -d ".-")
      name=$(printf "${name}")
      tmpvalue="${Q#*=}"
      tmpvalue=$(echo "${tmpvalue}" | sed -e 's/%\(..\)/\\\x\1 /g')
      for i in ${tmpvalue}; do
          g=$(printf "${i}")
          value="${value}${g}"
      done
      eval "export ${name}='${value}'"
    done
  else
    Q=$(echo "${QUERY_STRING}" | tr '+' ' ')
    eval "export KEYWORDS='${Q}'"
  fi
fi

if [[ -n "${HTTP_COOKIE}" ]]; then 
  for Q in ${HTTP_COOKIE}; do
    name=
    value=
    tmpvalue=

    Q="${Q%;}"

    name="${Q%%=*}"
    name=$(echo "${name}" | sed -e 's/%\(\)/\\\x/g' | tr "+" " ")
    name=$(echo "${name}" | tr -d ".-")
    name=$(printf "${name}")

    tmpvalue="${Q#*=}"
    tmpvalue=$(echo "${tmpvalue}" | sed -e 's/%\(..\)/\\\x\1 /g')

    for i in ${tmpvalue}; do
        g=$(printf "${i}")
        value="${value}${g}"
    done
    eval "export cookie_${name}='${value}'"
  done
fi


cookie() {
  if [[ "$#" -eq 1 ]]; then
    name="$1"
    name=$(echo "${name}" | sed -e 's/cookie_//')
    value=$(env | grep "^cookie_${name}" | sed -e 's/cookie_//' | cut -d= -f2-)
  elif [[ $# -gt 1 ]]; then
    name=$1
    shift
    eval "export 'cookie_${name}=$*'"
  else
    value=$(env | grep '^cookie_' | sed -e 's/cookie_//' | cut -d= -f1)
  fi
  echo ${value}
  unset name
  unset value
}

# keywords returns a list of keywords. This is only set when the script is
# called with an ISINDEX form (these are pretty rare nowadays).
keywords() {
  echo "${KEYWORDS}"
}

set_cookie() {
  name="$1"
  shift
  value="$*"
  bashlib_cookies="${bashlib_cookies}; ${name}=${value}"
  bashlib_cookies="${bashlib_cookies#;}"
  cookie "$name" "$value"
}

send_redirect() {
  if [[ "$#" -eq 1 ]]; then
    uri="$1"
  else
    uri="$PROTOCOL://${SERVER_NAME}/${SCRIPT_NAME}"
  fi
  echo "Location: ${uri}"
  echo
}

content_type() {
    case "$1" in
        html)
            content_type="text/html"
            ;;
        text)
            content_type="text/plain"
            ;;
        css)
            content_type="text/css"
            ;;
        js)
            content_type="application/javascript"
            ;;
    esac
    echo "Content-type: $content_type"
    echo
}