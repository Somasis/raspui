#!/bin/bash

. functions.sh

version="/$(git rev-parse --short HEAD)"
if [[ "$version" == "/" ]];then
    version="/dev"
fi

# set default variables in case you didn't configure them
cpu_track_count=2

cpu_warning_level=85
cpu_high_level=60
cpu_medium_level=25

ram_warning_level=85
ram_high_level=70
ram_medium_level=30

get_package_manager_version=$(pacman --color never -Q pacman)
get_installed_packages=$(pacman --color never -Qq | wc -l)

time=$(date +'%r')
date=$(date +'%B %d, %Y')
pretty_time="It's currently $time, on $date."

string_title="$HOSTNAME - running $RELEASE_PRETTY_NAME"
string_subheading="running $RELEASE_PRETTY_NAME"

string_cpu="CPU"
string_ram="RAM"

string_system_header="System"
string_network_header="Network"
string_software_header="Software"

string_process_total="running processes"
string_packages_installed="packages installed"

fontawesome_css="//netdna.bootstrapcdn.com/font-awesome/latest/css/font-awesome.min.css"
bootstrap_css="//netdna.bootstrapcdn.com/bootstrap/latest/css/bootstrap.min.css"
bootstrap_theme_css="//netdna.bootstrapcdn.com/bootstrap/latest/css/bootstrap-theme.min.css"
jquery_js="//code.jquery.com/jquery-1.11.0.min.js"
bootstrap_js="//netdna.bootstrapcdn.com/bootstrap/latest/js/bootstrap.min.js"
html5shiv_js="//cdn.jsdelivr.net/html5shiv/latest/html5shiv.js"
respondjs_js="//cdn.jsdelivr.net/respond/latest/respond.min.js"

# read configuration files
if [[ -f "config.example.sh" ]];then
    . config.example.sh
fi
if [[ -f "config.sh" ]];then
    . config.sh
fi

process_total=$(ps --no-header -ax 2>/dev/null | wc -l)

packages_installed="$get_installed_packages"
package_manager_version="$get_package_manager_version"

local_ip=$(ip route | grep src | sed 's/.*src //;s/ .*//')
remote_ip=$(wget -qO - "http://canhazip.com" | head -n1)

if [[ -z "$TZ" ]];then
    if [[ -z "$ZONE" ]];then
        if [[ ! -f /etc/localtime ]];then
            timezone=$(date +%Z)
        else
            timezone=$(readlink /etc/localtime)
            timezone="${timezone##*zoneinfo/}"
            while [[ "$timezone" =~ "_" ]];do
                timezone="${timezone/_/ }"
            done
        fi
    else
        timezone="$ZONE"
    fi
else
    timezone="$TZ"
fi

# calculate RAM usage
ram_info=$(_grep 'Mem' "/proc/meminfo" | remove_spaces)
ram_total=$(echo "$ram_info" | _grep MemTotal | cut -d':' -f2 | tr -d '[A-z]')
ram_available=$(echo "$ram_info" | _grep MemFree | cut -d':' -f2 | tr -d '[A-z]')
ram_used=$(( $ram_total - $ram_available ))

# most ways recommended using bc, but to reduce dependencies
#   we can just use expr, which is a part of coreutils.
#   as far as my testing goes, it works just as well.
ram_usage=$(expr $(expr "$ram_used" \* 100 ) / $ram_total )

if [[ "$ram_usage" -gt "$ram_warning_level" ]];then
    ram_usage_level=progress-bar-danger
elif [[ "$ram_usage" -gt "$ram_high_level" ]];then
    ram_usage_level=progress-bar-warning
elif [[ "$ram_usage" -gt "$ram_medium_level" ]];then
    ram_usage_level=progress-bar-success
else
    ram_usage_level=progress-bar-info
fi

if [[ "$ram_total" -ge 1024 ]];then
    ram_prefix=MB
else
    ram_prefix=kB
fi
ram_total=$(round "$ram_total" 1024)$ram_prefix # now convert to megabytes for presenting
if [[ "$ram_available" -ge 1024 ]];then
    ram_prefix=MB
else
    ram_prefix=kB
fi
ram_available=$(round "$ram_available" 1024)$ram_prefix
if [[ "$ram_used" -ge 1024 ]];then
    ram_prefix=MB
else
    ram_prefix=kB
fi
ram_used=$(round "$ram_used" 1024)$ram_prefix

cpus=$(_grep 'processor' "/proc/cpuinfo" | remove_spaces | remove_tabs | grep 'processor:' | wc -l)

cpu_model=$(echo $(_grep 'model name' /proc/cpuinfo | cut -d':' -f2))
# calculating CPU usage
count=0
PREV_TOTAL=0
PREV_IDLE=0
while [[ "$count" -ne $cpu_track_count ]];do
    CPU=($(sed -n 's/^cpu\s//p' /proc/stat))
    IDLE=${CPU[3]} # Just the idle CPU time.
    TOTAL=0
    for VALUE in "${CPU[@]}"; do
        let "TOTAL=$TOTAL+$VALUE"
    done
    let "DIFF_IDLE=$IDLE-$PREV_IDLE"
    let "DIFF_TOTAL=$TOTAL-$PREV_TOTAL"
    let "DIFF_USAGE=(1000*($DIFF_TOTAL-$DIFF_IDLE)/$DIFF_TOTAL+5)/10"
    PREV_TOTAL="$TOTAL"
    PREV_IDLE="$IDLE"
    count=$(( $count + 1 ))
    sleep .1s
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
content_type html

cat <<EOF
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="utf-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>$string_title</title>
        <link href="$fontawesome_css" rel="stylesheet">
        <link href="$bootstrap_css" rel="stylesheet">
        <link href="$bootstrap_theme_css" rel="stylesheet">
        <link href="bootstrap-mods.css" rel="stylesheet">
        <!--[if lt IE 9]>
            <script src="$html5shiv_js"></script>
            <script src="$respondjs_js"></script>
        <![endif]-->
        <script src="$jquery_js"></script>
        <script src="$bootstrap_js"></script>
    </head>
    <body>
        <div class='container'>
            <header class='page-header'>
                <img class='logo' src='logo.png'>
                <h1 style='display: inline; font-size: 24px;'>$HOSTNAME <small>$string_subheading</small></h1><br />
                <h4 style='display: inline; font-size: 13px;'>$pretty_time</h4>
            </header>
            <div class="row">
                <div class="col-md-4">
                    <h4 class='section-header'>$string_system_header</h4>
                    <table>
                        <tbody>
                            <tr>
                                <td><i class='fa fa-home'></i>&nbsp;</td>
                                <td>$HOSTNAME</td>
                            </tr>
                            <tr>
                                <td><i class='fa fa-linux'></i>&nbsp;</td>
                                <td><a href="$RELEASE_HOME_URL">$RELEASE_PRETTY_NAME</a></td>
                            </tr>
                            <tr>
                                <td><i class='fa fa-clock-o'></i>&nbsp;</td>
                                <td>$timezone</td>
                            </tr>
                        </tbody>
                    </table>
                </div>
                <div class="col-md-4">
                    <h4 class='section-header'>$string_network_header</h4>
                    <table>
                        <tbody>
                            <tr>
                                <td class='text-center'><i class='fa fa-map-marker'></i>&nbsp;</td>
                                <td>$local_ip</td>
                            </tr>
                            <tr>
                                <td><i class='fa fa-globe'></i>&nbsp;</td>
                                <td>$remote_ip</td>
                            </tr>
                        </tbody>
                    </table>
                </div>
                <div class="col-md-4">
                    <h4 class='section-header'>$string_software_header</h4>
                    <table>
                        <tbody>
                            <tr>
                                <td><i class='fa fa-cloud'></i>&nbsp;</td>
                                <td>$SERVER_SOFTWARE</td>
                            </tr>
                            <tr>
                                <td><i class='fa fa-terminal'></i>&nbsp;</td>
                                <td>bash/$BASH_VERSION</td>
                            </tr>
                            <tr>
                                <td><i class='fa fa-dropbox'></i>&nbsp;</td>
                                <td>$package_manager_version</td>
                            </tr>
                            <tr>
                                <td></td>
                                <td>$packages_installed $string_packages_installed</td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div><br />
            <div class="row">
                <div class="col-md-4">
                    <h5 class='section-header'>$string_cpu</h5>
                    <table>
                        <tbody>
                            <tr>
                                <div class="progress">
                                    <div class="progress-bar $cpu_usage_level" role="progressbar" aria-valuenow="$cpu_usage" aria-valuemin="0" aria-valuemax="100" style="width: $cpu_usage%;">
                                        $cpu_usage%
                                    </div>
                                </div>
                            </tr>
                            <tr>
                                <td></td>
                                <td>$cpu_model</td>
                            </tr>
                            <tr>
                                <td><i class='fa fa-cog'></i>&nbsp;</td>
                                <td>$process_total $string_process_total</td>
                            </tr>
                        </tbody>
                    </table>
                </div>
                <div class="col-md-4">
                    <h5 class='section-header'>$string_ram</h5>
                    <table>
                        <tbody>
                            <tr>
                                <div class="progress">
                                    <div class="progress-bar $ram_usage_level" role="progressbar" aria-valuenow="$ram_usage" aria-valuemin="0" aria-valuemax="100" style="width: $ram_usage%;">
                                        $ram_usage%
                                    </div>
                                </div>
                            </tr>
                            <tr>
                                <td><i class='fa fa-circle'></i>&nbsp;&nbsp;</td>
                                <td>${ram_used}</td>
                            </tr>
                            <tr>
                                <td><i class='fa fa-circle-o'></i>&nbsp;&nbsp;</td>
                                <td>${ram_available}</td>
                            </tr>
                            <tr>
                                <td>Total:&nbsp;</td>
                                <td>${ram_total}</td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>
            <footer>
                <p class='text-right'><small class='small'>Powered by <a href="https://github.com/somasis/raspui">raspui$version</a></small></p>
            </footer>
        </div>
    </body>
</html>
EOF