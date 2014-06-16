#!/bin/bash

. functions.sh

git_repo_url="https://github.com/somasis/raspui"
version="/$(git rev-parse --short HEAD)"
commit_message="$(git log -1 --pretty=%B)"
if [[ "$version" == "/" ]];then
    version="/dev"
fi

# make cache folder
if [[ ! -d './cache/' ]];then
    mkdir ./cache/
fi

read_config

if [[ ! -f "config.sh" && ! -f "config.example.sh" ]];then
    important_alerts="$important_alerts<div class=\"alert alert-danger\"><strong>Config files missing!</strong> The configuration files are missing, you're going to run into some problems.<br />Run <code>git pull</code> in the raspui directory to get the default config from the <a href='$git_repo_url' class='alert-link'>git repository</a>.</div>"
fi

if [[ "$_calc_bc_exists" -ne 0 ]];then
    footer="$footer<div class=\"alert alert-warning\"><strong>Floating point calculations disabled.</strong>&nbsp;&nbsp;<code><a href='https://duckduckgo.com/?q=bc+$RELEASE_ID+package'>bc</a></code> is not installed, this means that bash's built-in math functions are used. Statistics will not be as accurate.</div>"
fi

get_cpu

unique_users=$(users | tr ' ' '\n')
online_users=$(echo "$unique_users" | wc -l)
unique_users=$(echo "$unique_users" | sort -u | wc -l)

process_total=$(ps --no-header -ax 2>/dev/null | wc -l)

kernel_release="$(</proc/sys/kernel/ostype)/$(</proc/sys/kernel/osrelease) $(uname -m)"
kernel_version=$(</proc/sys/kernel/version)

loadavg=$(cut -d' ' -f1-3 /proc/loadavg)
loadavg_1min=$(echo "$loadavg" | cut -d' ' -f1)
loadavg_5min=$(echo "$loadavg" | cut -d' ' -f2)
loadavg_15min=$(echo "$loadavg" | cut -d' ' -f3)

local_ip=$(ip route | grep src | sed 's/.*src //;s/ .*//')

OLDIFS="$IFS"
IFS=$'\n'
if [[ "$RELEASE_ID_LIKE" == "arch" ]];then
    packages_installed=$(pacman --color never -Qq | wc -l)
    package_manager_version=$(pacman --color never -Q pacman | tr ' ' '/')
elif [[ "$RELEASE_ID_LIKE" == "debian" ]];then
    packages_installed=$(apt-cache pkgnames | wc -l)
    package_manager_version="apt $(apt-cache -q show apt | grep Version | cut -d ' ' -f2 | cut -d'~' -f1 | head -n1)"
else
    important_alerts="$important_alerts<div class=\"alert alert-danger\"><strong>Unable to find package manager methods.</strong> Raspui can't find what package manager you use.<br />Run <code>git pull</code> in the Raspui directory to update to the latest version of Raspui, then see if it works.<br />If it doesn't, <a href='$git_repo_url/issues/new' class='alert-link'>file a bug report</a>. Make sure to include what Linux distribution you're running.</div>"
    packages_installed=
    package_manager_version=
fi

IFS="$OLDIFS"
OLDIFS=
line=

retrieve_ip() {
    remote_ip=$(wget -T 2 -qO - http://whatismyip.akamai.com/)
    if [[ -z "$remote_ip" ]];then
        remote_ip=$(wget -T 3 -qO - "http://canhazip.com" | head -n1)
        if [[ -z "$remote_ip" ]];then
            remote_ip=$(wget -T 4 -qO - http://ipecho.net/plain)
        fi
    fi
    echo "$remote_ip"
}

if [[ ! -f "./cache/ip" ]];then
    remote_ip=$(retrieve_ip)
    echo "$remote_ip" > "./cache/ip"
else
    if [[ $(date +%s -r './cache/ip') -lt $(date +%s --date="60 min ago") ]];then
        remote_ip=$(retrieve_ip)
        echo "$remote_ip" > "./cache/ip"
    else
        remote_ip="$(<'./cache/ip') (cached)"
    fi
fi

active_interface=$(route -n | grep "^0.0.0.0" | rev | cut -d' ' -f1 | rev)

interface_recieved=$(<"/sys/class/net/$active_interface/statistics/rx_bytes")
interface_transferred=$(<"/sys/class/net/$active_interface/statistics/tx_bytes")
interface_total=$(( $interface_recieved + $interface_transferred ))

interface_recieved=$(converttohr "$interface_recieved")
interface_transferred=$(converttohr "$interface_transferred")
interface_total=$(converttohr "$interface_total")

# we used to use a few if statements to get this, but i think EST is more useful
# than giving something like "America/New York" as the timezone.
# to the inquiring user: what timezone is New York in? and further more,
# what timezone is this system in? by giving the user America/New York or similar,
# we do not answer the question being posed as to the timezone we're in. so we use %Z.
timezone=$(date +'%Z (UTC%z)')

# calculate RAM usage
ram_info=$(_grep 'Mem' "/proc/meminfo" | replace_spaces)
ram_total=$(calc $(echo "$ram_info" | _grep MemTotal | cut -d':' -f2 | tr -d '[A-z]') \* 1024)
ram_available=$(calc $(echo "$ram_info" | _grep MemFree | cut -d':' -f2 | tr -d '[A-z]') \* 1024)
ram_used=$(calc "$ram_total - $ram_available")

ram_usage=$(calc "($ram_used*100)/$ram_total")

if [[ "$ram_usage" -gt "$ram_warning_level" ]];then
    ram_usage_level=progress-bar-danger
elif [[ "$ram_usage" -gt "$ram_high_level" ]];then
    ram_usage_level=progress-bar-warning
elif [[ "$ram_usage" -gt "$ram_medium_level" ]];then
    ram_usage_level=progress-bar-success
else
    ram_usage_level=progress-bar-info
fi

ram_total=$(converttohr "$ram_total")
ram_available=$(converttohr "$ram_available")
ram_used=$(converttohr "$ram_used")

if [[ "$(( $(wc -l /proc/swaps | cut -d ' ' -f1) - 1 ))" -ne 0 ]];then
    swap_enabled=true
    swaps=$(cut -d' ' -f1 /proc/swaps | _grep /)
    swap_info=$(_grep 'Swap' "/proc/meminfo" | replace_spaces)
    swap_total=$(calc $(echo "$swap_info" | _grep SwapTotal | cut -d':' -f2 | tr -d '[A-z]') \* 1024)
    swap_available=$(calc $(echo "$swap_info" | _grep SwapFree | cut -d':' -f2 | tr -d '[A-z]') \* 1024 )
    swap_used=$(calc "$swap_total - $swap_available")

    # calculate swap usage
    swap_usage=$(( $(( $swap_used * 100 )) / $swap_total ))

    if [[ "$swap_usage" -gt "$swap_warning_level" ]];then
        swap_usage_level=progress-bar-danger
    elif [[ "$swap_usage" -gt "$swap_high_level" ]];then
        swap_usage_level=progress-bar-warning
    elif [[ "$swap_usage" -gt "$swap_medium_level" ]];then
        swap_usage_level=progress-bar-success
    else
        swap_usage_level=progress-bar-info
    fi

    swap_total=$(converttohr "$swap_total")
    swap_available=$(converttohr "$swap_available")
    swap_used=$(converttohr "$swap_used")
fi

if [[ "$swap_enabled" == "true" ]];then
    swap_column="                <div class=\"col-md-4\">"
else
    swap_column="                <div class=\"col-md-6\">"
fi

swap_usage_data=$(swapon -e --raw --show=name,size,used)

cpu_model=$(echo $(_grep 'model name' /proc/cpuinfo | cut -d':' -f2))

i=0
while true;do
    if [[ ! -d /sys/devices/system/cpu/cpu$i/cpufreq/ ]];then
        break
    fi
    current_gov=$(<"/sys/devices/system/cpu/cpu$i/cpufreq/scaling_governor")
    current_freq=$(calc $(<"/sys/devices/system/cpu/cpu$i/cpufreq/scaling_cur_freq") / 1000)
    min_freq=$(calc $(<"/sys/devices/system/cpu/cpu$i/cpufreq/scaling_min_freq") / 1000)
    max_freq=$(calc $(<"/sys/devices/system/cpu/cpu$i/cpufreq/scaling_max_freq") / 1000)
    i=$(( $i + 1 ))
    cpufreq_data="${cpufreq_data}CPU#$i: $current_gov, ${current_freq}MHz<br />${min_freq}MHz min / ${max_freq}MHz max<br />"
done

cpu_temp_c=$(calc $(</sys/class/thermal/thermal_zone0/temp) / 1000)
cpu_temp_f=$(calc $cpu_temp_c \* 9 / 5 + 32) # celsius to fahrenheit: $c*9/5+32

i=

if [[ "$raspi_logo" == "true" ]];then
    raspi_logo="<div class='header-logo text-center'><a href='$REQUEST_URI'><i style='color:$raspi_logo_color' class='raspi-logo raspi-icon raspi-o1 text-center'></i></a><a title='$commit_message' href='$git_repo_url'><small class='show-on-hover small'>raspui$version</small></a></div>"
else
    raspi_logo=
    footer="$footer<a href='$git_repo_url' title='$commit_message'><small class='small'>raspui$version</small></a>"
fi

uptime=$(</proc/uptime)
uptime=${uptime%%.*}

seconds=$(( uptime%60 ))
minutes=$(( uptime/60%60 ))
hours=$(( uptime/60/60%24 ))
days=$(( uptime/60/60/24 ))
if [[ "$days" -gt 0 ]];then
    days="$days days, "
fi
if [[ "$hours" -gt 0 ]];then
    hours="$hours hours, "
fi
if [[ "$minutes" -gt 0 ]];then
    minutes="$minutes minutes, "
fi
if [[ "$seconds" -gt 0 ]];then
    seconds="$seconds seconds"
fi
uptime="$days$hours$minutes$seconds"

if [[ "$swap_enabled" == "true" ]];then
    swap_html="$swap_html<div class='col-md-4'><h5 class='section-header'>$string_swap</h5><table><tbody><tr><div class=\"progress\"><div class=\"progress-bar $swap_usage_level\" role=\"progressbar\" aria-valuenow=\"$swap_usage\" aria-valuemin=\"0\" aria-valuemax=\"100\" style=\"width: $swap_usage%;\">$swap_usage%</div></div></tr><tr><td class='data-label'>$string_swap_used<i class='fa fa-circle'></i>&nbsp;</td><td>${swap_used}</td></tr><tr><td class='data-label'>$string_swap_free<i class='fa fa-circle-o'></i>&nbsp;</td><td>${swap_available}</td></tr><tr><td class='data-label'>$string_total</td><td>${swap_total}</td></tr><tr><td class='data-label'>$string_swap_devices</td><td>"
    for swap in $swaps;do
        specific_swap_usage=$(echo "$swap_usage_data" | grep "^$swap " | cut -d' ' -f3)
        specific_swap_total=$(echo "$swap_usage_data" | grep "^$swap " | cut -d' ' -f2)
        specific_swap="$specific_swap_usage/$specific_swap_total"
        swap_html="$swap_html<code>$swap</code> - $specific_swap<br />"
    done
    swap_html="$swap_html</td></tr></tbody></table></div>"
fi

if [[ ! -z "$footer" ]];then
    footer="<br /><footer>$footer</footer>"
fi
content_type html

html <<EOF
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="utf-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>$string_title</title>
        <link rel="shortcut icon" sizes="16x16 32x32 48x48 64x64" href="favicon.ico">
        <link rel="shortcut icon" type="image/x-icon" href="favicon.ico">
        <!--[if IE]>
            <link rel="shortcut icon" href="favicon.ico">
        <![endif]-->
        <link rel="icon" type="image/png" sizes="195x195" href="favicon-195.png">
        <link rel="apple-touch-icon" sizes="152x152" href="favicon-152.png">
        <link rel="apple-touch-icon" sizes="144x144" href="favicon-144.png">
        <link rel="apple-touch-icon" sizes="120x120" href="favicon-120.png">
        <link rel="apple-touch-icon" sizes="114x114" href="favicon-114.png">
        <link rel="icon" type="image/png" sizes="96x96" href="favicon-96.png">
        <link rel="apple-touch-icon" sizes="76x76" href="favicon-76.png">
        <link rel="apple-touch-icon" sizes="72x72" href="favicon-72.png">
        <link rel="apple-touch-icon" href="favicon-57.png">
        <meta name="msapplication-TileColor" content="#FFFFFF">
        <meta name="msapplication-TileImage" content="favicon-144.png">
        <link href="$fontawesome_css" rel="stylesheet">
        <link href="$bootstrap_css" rel="stylesheet">
        <link href="$bootstrap_theme_css" rel="stylesheet">
        <link href="raspui.css" rel="stylesheet">
        <!--[if lt IE 9]>
            <script src="$html5shiv_js"></script>
            <script src="$respondjs_js"></script>
        <![endif]-->
        <script src="$jquery_js"></script>
        <script src="$bootstrap_js"></script>
    </head>
    <body>
        <div class='container'>
            <header class='page-header'>$raspi_logo
                <h1 style='font-size: 24px;color:$raspi_logo_color !important' class='text-center'>$HOSTNAME <small>$string_subheading</small></h1>
                <div class='text-center'>
                    <div title='$timezone' style='padding: .2em .6em .3em;font-size: 75%;font-weight: 700;line-height: 1;color: #fff;border-radius: .25em;display:inline;background-color: #428bca;'>
                        $pretty_time
                    </div>
                </div>
            </header>
            $important_alerts
            <div class="row">
                <div class="col-md-4">
                    <h4 class='section-header'>$string_system_header</h4>
                    <table>
                        <tbody>
                            <tr>
                                <td class='data-label'><i class='fa fa-home'></i>&nbsp;</td>
                                <td>$HOSTNAME</td>
                            </tr>
                            <tr>
                                <td class='data-label'><i class='fa fa-users'></i>&nbsp;</td>
                                <td><span class="badge">$unique_users</span> ($online_users$string_users_non_unique)
                            <tr>
                                <td class='data-label'><i class='fa fa-linux'></i>&nbsp;</td>
                                <td><a href="$RELEASE_HOME_URL">$RELEASE_PRETTY_NAME</a></td>
                            </tr>
                            <tr>
                                <td></td>
                                <td>$kernel_release</td>
                            </tr>
                            <tr>
                                <td></td>
                                <td>$kernel_version</td>
                            </tr>
                            <tr>
                                <td class='data-label'><i class='fa fa-clock-o'></i>&nbsp;</td>
                                <td>$uptime</td>
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
                                <td class='data-label'><i class='fa fa-globe'></i>&nbsp;</td>
                                <td>$remote_ip</td>
                            </tr>
                            <tr>
                                <td class='data-label'><i class='fa fa-exchange'></i>&nbsp;</td>
                                <td>$active_interface
                                    <br /><i class='fa fa-arrow-circle-o-down'></i>&nbsp;$interface_recieved
                                    <br /><i class='fa fa-arrow-circle-o-up'></i>&nbsp;$interface_transferred
                                    <br />$string_total&nbsp;$interface_total
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>
                <div class="col-md-4">
                    <h4 class='section-header'>$string_software_header</h4>
                    <table>
                        <tbody>
                            <tr>
                                <td class='data-label'><i class='fa fa-cloud'></i>&nbsp;</td>
                                <td>$SERVER_SOFTWARE</td>
                            </tr>
                            <tr>
                                <td class='data-label'><i class='fa fa-terminal'></i>&nbsp;</td>
                                <td>bash/$BASH_VERSION</td>
                            </tr>
                            <tr>
                                <td class='data-label'><i class='fa fa-dropbox'></i>&nbsp;</td>
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
                $swap_column
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
                                <td class='data-label'>$string_cpu_temp<i class='glyphicon glyphicon-fire'></i>&nbsp;</td>
                                <td>$cpu_temp_c&deg;C / $cpu_temp_f&deg;F</td>
                            </tr>
                            <tr>
                                <td class='data-label'>$string_loadavgs<i class='fa fa-tasks'></i>&nbsp;</td>
                                <td>$loadavg_1min (1min)<br />$loadavg_5min (5min)<br />$loadavg_15min (15min)<br /></td>
                            </tr>
                            <tr>
                                <td class='data-label'><i class='fa fa-cog'></i>&nbsp;</td>
                                <td>$process_total $string_process_total</td>
                            </tr>
                            <tr>
                                <td class='data-label'><i class='fa fa-rocket'></i>&nbsp;</td>
                                <td>
                                    $cpufreq_data
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>
                $swap_column
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
                                <td class='data-label'>$string_ram_used<i class='fa fa-circle'>&nbsp;</i></td>
                                <td>${ram_used}</td>
                            </tr>
                            <tr>
                                <td class='data-label'>$string_ram_free<i class='fa fa-circle-o'></i>&nbsp;</td>
                                <td>${ram_available}</td>
                            </tr>
                            <tr>
                                <td class='data-label'>$string_total</td>
                                <td>${ram_total}</td>
                            </tr>
                        </tbody>
                    </table>
                </div>
                $swap_html
            </div>$footer
            <br />
            <br />
        </div>
    </body>
</html>
EOF

print_html