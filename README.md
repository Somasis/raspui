# raspui

raspberry pi web interface, providing a look at the system status. probably works great on other systems as well, but i use it on my raspberry pi.

heavily inspired by [raspcontrol](https://github.com/imjacobclark/Raspcontrol), but i thought i could do better. we'll just have to see about that!

## features

- basic info
    - local time and date
    - hostname
    - linux distribution being ran (given [/etc/os-release](http://www.freedesktop.org/software/systemd/man/os-release.html) files are present)
    - local network and remote IP address (courtesy of [canhazip.com](http://canhazip.com))
- software information
    - server software/version
    - bash version (raspui runs on bash, if you didn't know)
    - package manager version
- package information
    - package manager version
    - number of packages installed
- CPU information
    - display accurate CPU usage
    - running processes

## installation

[make sure you have enabled CGI for .sh scripts.](#cgi)

    cd /path/to/webserver/directory/you/want/to/install/to/
    git clone https://github.com/Somasis/raspui.git
    cd raspui

and if you need to change the defaults:

    mv config.example.sh config.sh

then, go to your webserver and open index.sh. [adjust config.sh as needed.](#configuration)
don't change settings in config.example.sh, as they are overwritten on [update](#updating)

## updating

    cd /path/to/raspui/
    git pull

## configuration

any variables not specified in config.sh will be inherited from config.example.sh and hardcoded defaults.

- cpu_track_count: how many times to check the CPU usage before printing it out.
    - this is a variable you probably don't want to mess with unless you think you're getting inaccurate readings, or it's taking too much time to load the page. the default is pretty minimal, and it hasn't given me inaccurate readings yet, however.
    - the reason this is needed is because reading /proc/stat only gives you the current CPU usage at the very moment you read it. every program that has to calculate CPU usage *must* read this file multiple times, or else the usage is inaccurate.
- cpu_<level>_level: when cpu_usage reaches a certain amount, set progress bar style to <level>
    - warning_level: when the progress bar will turn red.
    - high_level: when the progress bar turns orange.
    - medium_level: when the progress bar turns green
    - anything below the medium level will set the progress bar to blue
- get_package_manager_version: command that will give the version of the package manager.
    - default command is for arch linux, it prints 'pacman <package-version>'
    - for a system running debian, try "echo $(dpkg-query -W apt) | cut -d' ' -f2"
- get_installed_packages: command that will give a total of install packages, and nothing else
    - default command is for arch linux
    - for a system running debian (or a derivative of debian), try "dpkg-query -l | wc -l"
- time/date: command to give current time/date in a nice format
    - pretty_time: subheading used on header to show pretty_time. you can basically make it anything, but by default it is used for time. 
    - by default, $pretty_time is "It's currently $time, on $date."
    - by default, time is displayed as %r, which is the locale default 12-hour clock time. ex. 11:11:04 PM
    - by default, date is displayed as %B %d, %Y, which is the full month name, current day, and then four-number year. ex. February 23, 2014
- any variable prefixed with string_ is a variable used to customize the way data is shown on the page.
    - string_title: changes the string used as the page title (this is not the title used in the header)
    - string_subheading: changes the string used for the subheading.
    - string_cpu: changes the word used for CPU. ex. $string_cpu usage
    - string_process_total: changes the suffix of the number of running processes. ex. 75 $string_process_total
    - string_packages_installed: changes the suffix used after the number of packages installed. ex. 200 $string_packages_installed

## cgi
how to enable CGI for .sh scripts:

### lighttpd
add this line to your lighttpd.conf file, which is probably located at /etc/lighttpd/lighttpd.conf or similar.

    cgi.assign = ( ".sh" => "/bin/bash" )

change the path to the bash shell if needed.

### apache
I use lighttpd, so that's what has the most support. if you run into any problems, I probably can't help you very well unless you're certain it's a problem with the script.

add this line to your apache configuration, which could be located at /etc/apache2/apache2.conf, or a similar location.

    AddHandler cgi-script .sh

## planned
- user information
- RAM information
- CPU hog display
- integration with daemons like CouchPotato, SickBeard, Headphones.
- world domination
- ???

## credits

portions borrowed (namely bits and pieces of [functions.sh](functions.sh)) from [bashlib](http://bashlib.sourceforge.net/), which is under the [GPLv2](https://www.gnu.org/licenses/gpl-2.0.html).

font Awesome was created by dave gandy, and [can be found here](http://fontawesome.io).
font awesome is licensed under the [SL OFL 1.1](http://scripts.sil.org/OFL).
css files for font awesome are licensed under [the MIT License](LICENSE).

bootstrap code is copyright 2011-2014 twitter, inc., and is released under [the MIT license](LICENSE).
