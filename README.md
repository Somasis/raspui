# raspui
![raspui logo](favicon-195.png)

raspberry pi web interface, providing a look at the system status. probably works great on other systems as well, but i use it on my raspberry pi.

heavily inspired by [raspcontrol](https://github.com/imjacobclark/Raspcontrol), but i thought i could do better. we'll just have to see about that!

licensed under [the MIT License](LICENSE).

## features
- a pretty interface :)
- basic info
    - local time and date
    - hostname
    - logged in users
    - linux distribution being ran (given [/etc/os-release](http://www.freedesktop.org/software/systemd/man/os-release.html) files are present)
    - kernel version, release, and machine hardware name
    - uptime
- network information
    - local network and remote IP address
    - current active network interface
    - up/down stats for network interface
- software information
    - server software/version
    - bash version (raspui runs on bash, if you didn't know)
    - package manager version
- package information
    - package manager version
    - number of packages installed
- CPU information
    - display accurate CPU usage
    - load averages over 1min/5min/15min
    - running processes
    - current cpufreq governor (per-core)
- RAM usage
    - free/used/total in human-readable amounts
- Swap (only shows if you have any swap files or partitions)
    - free/used/total in human-readable amounts
    - show active swap devices and per-device usage
## requirements
currently, the only requirements are:

	- a moderately recent version of bash
    - i develop on version 4.2.45, but basically any version from about 3.0 up should work
- [bc](https://www.gnu.org/software/bc/)
    - if you want precise numbers for usage statistics, you need bc. it's a small package though, so it's not too much of a problem.
    - if you don't have it, raspui will fallback to using bash's built-in calculations, which is not floating-point based.

## installation
[check the requirements before installing](#requirements), and [make sure you have enabled CGI for .sh scripts](#cgi).

    cd /path/to/webserver/directory/you/want/to/install/to/
    git clone https://github.com/Somasis/raspui.git
    cd raspui

if you want to change the defaults: ```mv config.example.sh config.sh```

then, go to your webserver and open index.sh. [adjust config.sh as needed.](#configuration)
don't change settings in config.example.sh, as they are overwritten on [update](#updating)
## updating
    cd /path/to/raspui/
    git pull

## configuration
any variables not specified in config.sh will be inherited from config.example.sh and hardcoded defaults.

- force_floating_point: attempt to force the usage of floating point calculations
    - warning: this will probably fail if you don't have 'bc' in the $PATH
- use_cpu_cache: this will read cpu usage from /tmp/raspui-cpu-stats.txt
    - this is only useful if you have a crontab entry updating it
    - /tmp/raspui-cpu-stats.txt can be generated thirty seconds with ```bash /path/to/raspui/functions.sh manual_cpu_calc tocache```
    - crontab entry that i use: ```* * * * * bash /var/www/raspui/functions.sh manual_cpu_calc tocache >/dev/null 2>&1```
- cpu_track_count: how many times to check the CPU usage before printing it out.
    - this is a variable you probably don't want to mess with unless you think you're getting inaccurate readings, or it's taking too much time to load the page. the default is pretty minimal, and it hasn't given me inaccurate readings yet, however.
    - the reason this is needed is because reading /proc/stat only gives you the current CPU usage at the very moment you read it. every program that has to calculate CPU usage *must* read this file multiple times, or else the usage is inaccurate.
- {cpu,ram}_<level>_level: when {cpu,ram}_usage reaches a certain amount, set progress bar style to <level>
    - warning_level: when the progress bar will turn red.
    - high_level: when the progress bar turns orange.
    - medium_level: when the progress bar turns green
    - anything below the medium level will set the progress bar to blue
- time/date: command to give current time/date in a nice format
    - pretty_time: subheading used on header to show pretty_time. you can basically make it anything, but by default it is used for time. 
        - by default, $pretty_time is "It's currently $time, on $date."
    - by default, time is displayed as %r, which is the locale default 12-hour clock time. ex. 11:11:04 PM
    - by default, date is displayed as %B %d, %Y, which is the full month name, current day, and then four-number year. ex. February 23, 2014
- raspi_logo: sets the visibility of the raspberry pi logo in the header
    - this also sets the raspui version and link to be in the footer of the page instead of appearing on logo hover.
- raspi_logo_color: sets the color of the logo
    - also sets the color used for the hostname in the header.
- any variable prefixed with string_ is a variable used to customize the way data is shown on the page.
    - string_title: changes the string used as the page title (this is not the title used in the header)
    - string_subheading: changes the string used for the subheading.
    - string_cpu: changes the word used for CPU.
    - string_ram: changes the word used for RAM.
    - string_swap: changes the word used for swap.
    - string_loadavgs: changes the word used for load averages.
    - string_{ram,swap}_{used,free,total}: changes the prefix for the {used,free,total} amount of {ram,swap}
    - string_swap_devices: changes the word used for swap devices.
    - string_{system,network,software}_header: changes the word used in the header above the {system,network,software} section
    - string_users_non_unique: changes the phrase used for the amount of non-unique currently logged in users
    - string_process_total: changes the suffix of the number of running processes. ex. 75 $string_process_total
    - string_packages_installed: changes the suffix used after the number of packages installed. ex. 200 $string_packages_installed
- locations of dependency css/js:
    - by default all these point to either [bootstrapcdn](http://bootstrapcdn.com) or [jsdelivr](http://jsdelivr.net)
    - fontawesome_css: url used for the css for font awesome
    - bootstrap_css: url of bootstrap.min.css
    - bootstrap_theme_css: url of bootstrap-theme.min.css
    - jquery_js: url used to get jquery.min.js
    - bootstrap_js: url used for bootstrap.min.js
    - html5shiv_js: url used for html5shiv.js
    - respondjs_js: url used for respond.min.js
    - if you'd prefer to have local copies of these files, you can just give a relative path. for example, bootstrap_css in a folder named "styles" in the raspui folder, just do "styles/bootstrap.min.css"

## cgi
how to enable CGI for .sh scripts:

### lighttpd
add this line to your lighttpd.conf file, which is probably located at /etc/lighttpd/lighttpd.conf or similar.

```cgi.assign = ( ".sh" => "/bin/bash" )```

change the path to the bash shell if needed.

### apache
I use lighttpd, so that's what has the most support. if you run into any problems, I probably can't help you very well unless you're certain it's a problem with the script.
add this line to your apache configuration, which could be located at /etc/apache2/apache2.conf, or a similar location.

```AddHandler cgi-script .sh```

## planned
- CPU hog display
- integration with daemons like CouchPotato, SickBeard, Headphones.
- world domination
- ???

## credits
- [codepunker](https://github.com/codepunker) for their design tips, it looks a lot better because of them
- [the raspberry pi foundation](http://www.raspberrypi.org/) for making this great device
- [the lighttpd project](http://www.lighttpd.net/) for making a very fast and very easy to set up development server

portions borrowed (namely bits and pieces of [functions.sh](functions.sh)) from [bashlib](http://bashlib.sourceforge.net/), which is under the [GPLv2](https://www.gnu.org/licenses/gpl-2.0.html).

font Awesome was created by dave gandy, and [can be found here](http://fontawesome.io).
font awesome is licensed under the [SL OFL 1.1](http://scripts.sil.org/OFL).
css files for font awesome are licensed under [the MIT License](LICENSE).

bootstrap code is copyright 2011-2014 twitter, inc., and is released under [the MIT license](LICENSE).