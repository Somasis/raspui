#!/bin/bash

OLDIFS="$IFS"
IFS=$'\n'
# read /etc/*-release files, they contain information about what system is being used.
for file in /etc/*-release;do
    for release_line in $(<"$file");do
        eval "RELEASE_$release_line"
    done
done
IFS="$OLDIFS"

# tells the script what protocol the browser is using
# we probably should do this a different way, however...
# I'm not sure of any other method, other than $SERVER_PORT
# but that'd mess up if you ran HTTP on a different port, so for now
# we're going by $HTTPS, since it is set by the server to show if
# we are using HTTPS. anything else means HTTP.
if [[ "$HTTPS" == "on" ]];then
    PROTOCOL=https
else
    PROTOCOL=http
fi

STDIN=$(</dev/stdin) # get stdin input, used for things like POST requests.
if [[ -n "${STDIN}" ]]; then # and then if there's anything
  QUERY_STRING="${STDIN}&${QUERY_STRING}" # shove it into the QUERY_STRING
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

# cookie([cookie name],[cookie value])
#   if no args, print all cookies
#   if only cookie name given, print [cookie name]'s value
#   if cookie name and cookie value given, set [cookie name] to [cookie value]
cookie() {
  if [[ "$#" -eq 1 ]]; then
    name="$1"
    name=$(echo "${name}" | sed -e 's/cookie_//')
    value=$(env | grep "^cookie_${name}" | sed -e 's/cookie_//' | cut -d= -f2-)
    echo "${value}"
  elif [[ $# -gt 1 ]]; then
    name="$1"
    shift
    value="$*"
    bashlib_cookies="${bashlib_cookies}; ${name}=${value}"
    bashlib_cookies="${bashlib_cookies#;}"
    eval "export 'cookie_${name}=$*'"
  else
    value=$(env | grep '^cookie_' | sed -e 's/cookie_//' | cut -d= -f1)
    echo "${value}"
  fi
  name=
  value=
}

# keywords(): returns a list of keywords.
#   this is only set when the script is called with an ISINDEX form
#   you shouldn't need to use this, if you are, consider using
#   a different method, as ISINDEX is deprecated in HTML5 specification
keywords() {
  echo "${KEYWORDS}"
}

# send_redirect(uri): sends the browser a request to redirect to $uri
send_redirect() {
  uri="$@"
  echo "Location: ${uri}"
  echo
}


# get_content_type(file): returns mime type that can be fed into content_type()
get_content_type() {
    file -b --mime-type "$@"
}

# content_type(content_type): prints content-type in http header format
content_type() {
    case "$@" in
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
        *)
            content_type="$@"
            ;;
    esac
    echo "Content-type: $content_type"
    echo
}

# grep(string to search for,[file, if empty stdin will be used]): very, very basic grep replacement.
_grep() {
    grep_for="$1"
    grep_file="$2"
    if [[ -z "$grep_file" ]];then
        grep_input="$(</dev/stdin)"
    elif [[ ! -f "$grep_file" ]];then
        echo "$grep_file is not a real file"
        exit 2
    else
        grep_input="$(<$grep_file)"
    fi
    grep_line=
    OLDIFS="$IFS"
    IFS=$'\n'
    echo "$grep_input" | while read grep_line; do
        if [[ "$grep_line" == *"$grep_for"* ]];then
            echo "$grep_line"
        fi
    done 
    IFS="$OLDIFS"
    grep_for=
    grep_file=
    grep_input=
    grep_line=
    OLDIFS=
}

# round(dividend/divisor): gives you a properly rounded version of $dividend/$divisor
round() { # src: http://ubuntuforums.org/showthread.php?t=1371892&p=8606385#post8606385
    x="$1"
    y="$2"
    a=$(( $x/$y ))
    b=$(( ($x * 10) / $y ))
    c=$(( $b - ($a *10 ) ))
    if [[ "$c" -lt 5 ]]; then
        a=$(( $a + 1 ))
    fi
    echo "$a"
    x=
    y=
    a=
    b=
    c=
}

# remove_spaces(string): gives a version of the string without any spaces, can use stdin instead
remove_spaces() { # replaces tr -d ' '
    if [[ -z "$@" ]];then
        rm_spaces_string=$(</dev/stdin)
    else
        rm_spaces_string="$@"
    fi
    while [[ "$rm_spaces_string" == *" "* ]];do
        rm_spaces_string="${rm_spaces_string/ /}"
    done
    echo "$rm_spaces_string"
    rm_spaces_string=
}

# remove_spaces(string): gives a version of the string without any spaces, can use stdin instead
remove_tabs() {
    if [[ -z "$@" ]];then
        rm_tabs_string=$(</dev/stdin)
    else
        rm_tabs_string="$@"
    fi
    echo "$rm_tabs_string" | tr -d '\011'
    rm_tabs_string=
}