# cpu_track_count: how many times to get cpu usage.
# recommended is 2 or more times. the higher the number the more accurate, but more page loading
cpu_track_count=2

# cpu_<level>_level: when cpu_usage reaches a certain amount, set progress bar style to <level>
cpu_warning_level=85
cpu_high_level=60
cpu_medium_level=25

# get_package_manager_version: command that will give the version of the package manager.
# get_installed_packages: command that will give a total of install packages, and nothing else
get_package_manager_version=$(pacman --color never -Q pacman)
get_installed_packages=$(pacman --color never -Qq | wc -l)

# time/date: command to give current time/date in a nice format
# pretty_time: subheading used on header to show pretty_time.
# you can basically make it anything, but i use it for time.
time=$(date +'%r')
date=$(date +'%B %d, %Y')
pretty_time="It's currently $time, on $date."

string_title="$HOSTNAME - running $RELEASE_PRETTY_NAME"
string_subheading="running $RELEASE_PRETTY_NAME"
string_cpu="CPU"
string_process_total="running processes"
string_packages_installed="packages installed"