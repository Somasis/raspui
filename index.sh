#!/bin/bash

. functions.sh

# set default variables in case you didn't configure them
cpu_track_count=2
cpu_warning_level=85
cpu_high_level=60
cpu_medium_level=25
get_package_manager_version="[Package manager integration not configured]"
get_installed_packages="[Package manager integration not configured]"
time=$(date +'%r')
date=$(date +'%B %d, %Y')
pretty_time="It's currently $time, on $date."
string_title="$HOSTNAME - running $RELEASE_PRETTY_NAME"
string_subheading="running $RELEASE_PRETTY_NAME"
string_cpu="CPU"
string_process_total="running processes"
string_packages_installed="packages installed"

if [[ -f "config.example.sh" ]];then
    . config.example.sh
fi
if [[ -f "config.sh" ]];then
    . config.sh
fi

project_url="https://github.com/somasis/raspui"
version="/$(git rev-parse --short HEAD)"
if [[ "$version" == "/" ]];then
    version="/dev"
fi

process_total=$(ps --no-header -x 2>/dev/null | wc -l)

packages_installed="$get_installed_packages"
package_manager_version="$get_package_manager_version"

local_ip=$(ip route | grep src | sed 's/.*src //;s/ .*//')
remote_ip=$(wget -qO - "http://canhazip.com" | head -n1)

cpu_model=$(echo $(cat /proc/cpuinfo | grep 'model name' | cut -d':' -f2))
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
        <link href="//netdna.bootstrapcdn.com/font-awesome/latest/css/font-awesome.min.css" rel="stylesheet">
        <link href="//netdna.bootstrapcdn.com/bootstrap/latest/css/bootstrap.min.css" rel="stylesheet">
        <link href="//netdna.bootstrapcdn.com/bootstrap/latest/css/bootstrap-theme.min.css" rel="stylesheet">
        <link href="bootstrap-mods.css" rel="stylesheet">
        <!--[if lt IE 9]>
            <script src="//cdn.jsdelivr.net/html5shiv/latest/html5shiv.js"></script>
            <script src="//cdn.jsdelivr.net/respond/latest/respond.min.js"></script>
        <![endif]-->
        <script src="//code.jquery.com/jquery-1.11.0.min.js"></script>
        <script src="//netdna.bootstrapcdn.com/bootstrap/latest/js/bootstrap.min.js"></script>
    </head>
    <body>
        <div class='container'>
            <header class='page-header'>
                <h1>$HOSTNAME <small>$string_subheading</small></h1>
                <h4>$pretty_time</h4>
            </header>
            <h4 class='section-header'>System</h4>
            <div class="row">
                <div class="col-md-4">
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
                        </tbody>
                    </table>
                </div>
                <div class="col-md-4">
                    <table>
                        <tbody>
                            <tr>
                                <td><i class='fa fa-map-marker'></i>&nbsp;</td>
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
                    <table>
                        <tbody>
                            <tr>
                                <td><i class='fa fa-cloud-download'></i>&nbsp;</td>
                                <td>$SERVER_SOFTWARE</td>
                            </tr>
                            <tr>
                                <td><i class='fa fa-terminal'></i>&nbsp;</td>
                                <td>bash/$BASH_VERSION</td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div><br />
            <div class="row">
                <div class="col-md-4">
                    <table>
                        <tbody>
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
                    <table>
                        <tbody>
                            <tr>
                                <td><i class='fa fa-tasks'></i>&nbsp;</td>
                                <td>$string_cpu</td>
                            </tr>
                        </tbody>
                    </table>
                </div>
                <div class="col-md-4">
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
                                <td><i class='fa fa-cog'></i>&nbsp;</td>
                                <td>$cpu_model</td>
                            </tr>
                            <tr>
                                <td></td>
                                <td>$process_total $string_process_total</td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>
            <footer>
                <p class='text-right'><small class='small'>Powered by <a href="$project_url">raspui$version</a></small></p>
            </footer>
        </div>
    </body>
</html>
EOF