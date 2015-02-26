#!/bin/bash
set -e

declare cmd="shellinaboxd --user shellinabox --group shellinabox"
                                                                                                                                                                                                                   
[ -n "$SHELLINABOX_DISABLE_SSL" ] && cmd+=" --disable-ssl"                                                                                                                                                         

declare -a vars=( $(grep -vE "^(\s*#.*|\s*)$" shellinabox_services  | awk '{print $1}') )
declare -a urls=( $(grep -vE "^(\s*#.*|\s*)$" shellinabox_services  | awk '{print $2}') )
IFS=$'\n' apps=( $(grep -vE "^(\s*#.*|\s*)$" shellinabox_services  | awk '{print substr($0, index($0,$3))}') )


#[ -n "$SHELLINABOX_SERVICE_LOCAL" ] && urls[${#urls[@]}]="local" && apps[${#apps[@]}]="LOGIN"
#[ -n "$SHELLINABOX_SERVICE_HOST" ] && urls[${#urls[@]}]="$SHELLINABOX_SERVICE_HOST" && apps[${#apps[@]}]="SSH:$DOCKER_HOST"
#[ -n "$SHELLINABOX_SERVICE_WHO" ] && urls[${#urls[@]}]="$SHELLINABOX_SERVICE_WHO" && apps[${#apps[@]}]="nobody:nogroup:/:w | awk '{ if($8!=\"w\") print $0 }'"

# add dummy service if no service is enabled
[ ${#vars[@]} -lt 1 ] && vars[0]="" && surls[0]="" && apps[0]="nobody:nogroup:/:echo NO SERVICE DEFINED, PLEASE DEFINE SOME TO BE USEFUL"

for ((i = 0; i < ${#vars[@]}; i++)); do
	option=$(eval echo "\$${vars[$i]}")
	#printf "  %s=%s -> %s:%s\n" "${vars[$i]}" "$option" "${urls[$i]}" "${apps[$i]}"
	if [ -n "$option" ]; then
		urls[$i]="$option"
	fi
        cmd+=" -s \"/${urls[$i]}:${apps[$i]}\""
        # add default without url
        [ -n "$SHELLINABOX_DEFAULT" ] && [ "$SHELLINABOX_DEFAULT" == "${urls[$i]}" ] && cmd+=" -s \"/:${apps[$i]}\""
done
echo "Starting: $cmd"

eval $cmd \                                                                                                                                                                                                        
                    $(for i in $(ls /etc/shellinabox/options-enabled/*.css |
                                 sed -e                                       \
                                    's/.*[/]\([0-9]*\)[-_+][^/:,;]*[.]css/\1/'|
                                 sort -u); do
                        for j in /etc/shellinabox/options-enabled/"$i"*.css; do
                          echo -n "$j" |
                          sed -e 's/\(.*[/]\)\([0-9]*\)\([-_+]\)\([^/:,;]*\)[.]css/\4:\3\1\2\3\4.css,/
                                  s/:_/:-/'
                        done |
                        sed -e 's/,$/;/'
                      done |
                      sed -e 's/;$//
                              //b
                              s/.*/--user-css "\0"/')

