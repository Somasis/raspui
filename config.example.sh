# https://github.com/somasis/raspui#configuration
# visit the github's readme for help with configuration,
# i don't maintain that thing for nothin' bub
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
jquery_js="//cdn.jsdelivr.net/jquery/1.10.0/jquery.min.js"
bootstrap_js="//netdna.bootstrapcdn.com/bootstrap/latest/js/bootstrap.min.js"
html5shiv_js="//cdn.jsdelivr.net/html5shiv/latest/html5shiv.js"
respondjs_js="//cdn.jsdelivr.net/respond/latest/respond.min.js"