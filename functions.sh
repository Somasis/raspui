#!/bin/bash

_OLDIFS="$IFS"
IFS=$'\n'
# read /etc/*-release files, they contain information about what system is being used.
for file in /etc/*-release;do
    for release_line in $(<"$file");do
        eval "RELEASE_$release_line"
    done
done
RELEASE_ID=${RELEASE_ID:-$RELEASE_DISTRIB_ID}
RELEASE_PRETTY_NAME=${RELEASE_PRETTY_NAME:-$RELEASE_NAME}
RELEASE_PRETTY_NAME=${RELEASE_PRETTY_NAME:-$RELEASE_DISTRIB_ID}
IFS="$_OLDIFS"

_calc_bc_exists=$(type -fp bc 2>&1 >/dev/null; echo $?) # use the builtin path search instead of `which`

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

if [[ -z "$@" ]];then
    STDIN=$(</dev/stdin) # get stdin input, used for things like POST requests.
    if [[ -n "${STDIN}" ]]; then # and then if there's anything
      QUERY_STRING="${STDIN}&${QUERY_STRING}" # shove it into the QUERY_STRING
    fi
fi

# Handle GET and POST requests... (the QUERY_STRING will be set)
if [[ -n "${QUERY_STRING}" ]]; then 
  # name=value params, separated by either '&' or ';'
  if echo "${QUERY_STRING}" | grep '=' >/dev/null ; then
    for _Q in $(echo "${QUERY_STRING}" | tr ";&" "\012") ; do
      _name=
      _value=
      _tmpvalue=
      _name="${_Q%%=*}"
      _name=$(echo "${_name}" | sed -e 's/%\(\)/\\\x/g' | tr "+" " ")
      _name=$(echo "${_name}" | tr -d ".-")
      _name=$(printf "${_name}")
      _tmpvalue="${_Q#*=}"
      _tmpvalue=$(echo "${_tmpvalue}" | sed -e 's/%\(..\)/\\\x\1 /g')
      for _i in ${_tmpvalue}; do
          _g=$(printf "${_i}")
          _value="${_value}${_g}"
      done
      eval "export ${_name}='${_value}'"
    done
  else
    _Q=$(echo "${QUERY_STRING}" | tr '+' ' ')
    eval "export KEYWORDS='${Q}'"
  fi
fi

if [[ -n "${HTTP_COOKIE}" ]]; then 
  for _Q in ${HTTP_COOKIE}; do
    _name=
    _value=
    _tmpvalue=

    _Q="${_Q%;}"

    _name="${_Q%%=*}"
    _name=$(echo "${_name}" | sed -e 's/%\(\)/\\\x/g' | tr "+" " ")
    _name=$(echo "${_name}" | tr -d ".-")
    _name=$(printf "${_name}")

    _tmpvalue="${_Q#*=}"
    _tmpvalue=$(echo "${_tmpvalue}" | sed -e 's/%\(..\)/\\\x\1 /g')

    for _i in ${_tmpvalue}; do
        _g=$(printf "${_i}")
        _value="${_value}${_g}"
    done
    eval "export cookie_${_name}='${_value}'"
  done
fi

# cookie([cookie name],[cookie value])
#   if no args, print all cookies
#   if only cookie name given, print [cookie name]'s value
#   if cookie name and cookie value given, set [cookie name] to [cookie value]
cookie() {
  if [[ "$#" -eq 1 ]]; then
    _name="$1"
    _name=$(echo "${_name}" | sed -e 's/cookie_//')
    _value=$(env | grep "^cookie_${_name}" | sed -e 's/cookie_//' | cut -d= -f2-)
    echo "${_value}"
  elif [[ $# -gt 1 ]]; then
    _name="$1"
    shift
    _value="$*"
    bashlib_cookies="${bashlib_cookies}; ${_name}=${_value}"
    bashlib_cookies="${bashlib_cookies#;}"
    eval "export 'cookie_${_name}=$*'"
  else
    _value=$(env | grep '^cookie_' | sed -e 's/cookie_//' | cut -d= -f1)
    echo "${_value}"
  fi
  _name=
  _value=
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
  _uri="$@"
  echo "Location: ${_uri}"
  echo
  _uri=
}


# get_content_type(file): returns mime type that can be fed into content_type()
get_content_type() {
    file -b --mime-type "$@"
}

# content_type(content_type): prints content-type in http header format
content_type() {
    case "$@" in
        html)
            _content_type="text/html"
            ;;
        text)
            _content_type="text/plain"
            ;;
        css)
            _content_type="text/css"
            ;;
        js)
            _content_type="application/javascript"
            ;;
        *)
            _content_type="$@"
            ;;
    esac
    echo "Content-type: $_content_type"
    echo
}

read_config() {
    if [[ -f "config.example.sh" ]];then
        . config.example.sh
    fi

    if [[ -f "config.sh" ]];then
        . config.sh
    fi
}

# grep(string to search for,[file, if empty stdin will be used]): very, very basic grep replacement.
_grep() {
    _grep_for="$1"
    _grep_file="$2"
    if [[ -z "$_grep_file" ]];then
        _grep_input="$(</dev/stdin)"
    elif [[ ! -f "$_grep_file" ]];then
        echo "$_grep_file is not a real file"
        exit 2
    else
        _grep_input="$(<$_grep_file)"
    fi
    _grep_line=
    _OLDIFS="$IFS"
    IFS=$'\n'
    echo "$_grep_input" | while read _grep_line; do
        if [[ "$_grep_line" == *"$_grep_for"* ]];then
            echo "$_grep_line"
        fi
    done 
    IFS="$_OLDIFS"
    _grep_for=
    _grep_file=
    _grep_input=
    _grep_line=
    _OLDIFS=
}

# replace_spaces(string,): gives a version of the string with spaces replaced with <1>, can use stdin instead
replace_spaces() { # replaces tr -d ' '
    if [[ -z "$1" ]];then
        _spaces_string=$(</dev/stdin)
    else
        _spaces_string="$1"
    fi
    while [[ "$_spaces_string" == *" "* ]];do
        _spaces_string="${_spaces_string/ /}"
    done
    echo "$_spaces_string"
    _spaces_string=
}

# remove_spaces(string): gives a version of the string without any spaces, can use stdin instead
remove_tabs() {
    if [[ -z "$@" ]];then
        _tabs_string=$(</dev/stdin)
    else
        _tabs_string="$@"
    fi
    echo "$_tabs_string" | tr -d '\011'
    _tabs_string=
}

# html([html]): append to the final html output. accepts stdin input.
html() {
    if [[ -z "$@" ]];then
        _html_input=$(</dev/stdin)
    else
        _html_input="$@"
    fi
    _html=$(echo "$_html$_html_input" | sed -e "s/^[ \t]*//g;/^$/d;s/>[ ]*</\>\</g" | tr -d '\n')
}

# print_html(): just prints the html in the $_html variable, which has been minimized
print_html() {
    echo "$_html"
}

# calc([arithmetic]): calculate math functions. tries to use bc if it exists, otherwise fallback to bash builtins.
#   if no args given, it'll use stdin. scale=[number] is also removed from input if bc does not exist, so it basically
#   functions as a drop-in replacement for bc in most shell script usages.
calc() {
    _calc_input=${*:-stdin}
    if [[ $_calc_input == stdin ]];then # use stdin if no args
        _calc_input=$(</dev/stdin)
    fi
    if [[ $force_floating_point != 'true' && $_calc_bc_exists -ne 0 ]];then # make sure floating point calc is not forced and that bc exists
        _calc=$(echo "$_calc_input" | sed 's/scale=.*; //')
        echo "$(( $_calc ))"
    else
        echo "$_calc_input" | bc | sed 's/\.[0]*$//g' # get rid of leftover zeros, those are annoying
    fi
    _calc=
    _calc_input=
    _calc_bc_exists=
}

# get_cpu: get cpu stats and export them to variables, use cached version if we're using that method
get_cpu() {
    if [[ "$use_cpu_cache" == "true" && -f /tmp/raspui-cpu-stats.txt ]];then
        cpu_usage=$(cut -d':' -f1 /tmp/raspui-cpu-stats.txt)
        cpu_usage_level=$(cut -d':' -f2 /tmp/raspui-cpu-stats.txt)
    else
        manual_cpu_calc
    fi
}

manual_cpu_calc() {
    count=0
    PREV_TOTAL=0
    PREV_IDLE=0
    while [[ "$count" -ne $cpu_track_count ]];do
        CPU=($(sed -n 's/^cpu\s//p' /proc/stat))
        IDLE=${CPU[3]} # Just the idle CPU time.
        TOTAL=0
        for VALUE in "${CPU[@]}"; do
            TOTAL=$(( $TOTAL + $VALUE ))
        done
        DIFF_IDLE=$(( $IDLE - $PREV_IDLE ))
        DIFF_TOTAL=$(( $TOTAL - $PREV_TOTAL ))
        DIFF_USAGE=$(( $(( $(( $(( 1000 * $(( $DIFF_TOTAL - $DIFF_IDLE)) )) / $DIFF_TOTAL )) + 5)) / 10 ))
        PREV_TOTAL="$TOTAL"
        PREV_IDLE="$IDLE"
        count=$(( $count + 1 ))
        sleep .05s
    done
    cpu_usage="$DIFF_USAGE"
    if [[ "$cpu_usage" -gt "$cpu_warning_level" ]];then
        cpu_usage_level=progress-bar-danger
    elif [[ "$cpu_usage" -gt "$cpu_high_level" ]];then
        cpu_usage_level=progress-bar-warning
    elif [[ "$cpu_usage" -gt "$cpu_medium_level" ]];then
        cpu_usage_level=progress-bar-success
    else
        cpu_usage_level=progress-bar-info
    fi
    
    if [[ "$1" == "tocache" ]];then
        echo "$cpu_usage:$cpu_usage_level" > /tmp/raspui-cpu-stats.txt
    fi
}

# converttohr(byte amount): converts to human readable amount
converttohr() {
    _SLIST="bytes,kB,MB,GB,TB,PB,EB,ZB,YB"

    _POWER=1
    _VAL=$(echo "scale=2; $1 / 1" | calc)
    _VINT=$(echo $_VAL / 1024 | calc)
    while [[ $_VINT -gt 0 ]];do
        let _POWER=_POWER+1
        _VAL=$(echo "scale=2; $_VAL / 1024" | calc)
        _VINT=$(echo $_VAL / 1024 | calc)
    done

    echo "$_VAL $(echo $_SLIST | cut -f$_POWER -d, )"
    _SLIST=
    _POWER=
    _VAL=
    _VINT=
}

if [[ ! -z "$@" ]];then
    read_config
    eval "$@"
fi