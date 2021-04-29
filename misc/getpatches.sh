#!/bin/bash

# https://stackoverflow.com/a/44811468
sanitize() {
   local s="${1?need a string}"     # receive input in first argument
   s="${s//[^[:alnum:]]/-}"         # replace all non-alnum characters to -
   s="${s//+(-)/-}"                 # convert multiple - to single -
   s="${s/#-}"                      # remove - from start
   s="${s/%-}"                      # remove - from end
   echo "${s,,}" | sed "s/--/-/g"   # convert to lowercase and remove multiple '-'
}

j=0
get_patches() {
	i=0
	case $3 in
		"git")
			dirname=` echo $1 | cut -c20- | sed "s/\/commit//g;s/\//_/g" ` ;;
		"korg")
			dirname=` echo $1 | grep -oE "([a-z0-9-]+[/][a-z0-9-]+[.]git)" | grep -oE "([a-z0-9-]+)" | head -n1 ` ;;
	esac
	echo -e "Getting patches from ${dirname} from ${3}...\n"
	dir_setup=`rm -rf $dirname && mkdir $dirname`
	[ -d $dirname ] && $dir_setup || mkdir $dirname

	for l in $(echo $2); do
		case $3 in
			"git")
				echo $l
				curl -s `echo $1/$l.patch` > $dirname/${i}.patch ;;
			"korg")
				echo $l
				curl -s `echo $1=$l` > $dirname/${i}.patch ;;
		esac \
		&& new_name=`cat $dirname/${i}.patch | grep "Subject:" | sed "s/Subject: //g"` \
		&& echo -e "$new_name\n" \
		&& mv $dirname/${i}.patch $dirname/${i}_$(sanitize "${new_name}").patch \
		&& i=$((i+1))
	done

	[ -d misc/patches/${j}_${dirname} ] && rm -rf misc/patches/${j}_${dirname}
	mv $dirname misc/patches/${j}_${dirname} && j=$((j+1))
}
# for fetching sha: curl "repo_link" | grep "Copy the full SHA" | cut -f2 -d \" | grep -v "[0-9]:[0-9]"
# for cleanup: cat *.patch | grep -E "[0-9a-f]{40}" | cut -f2 -d ' '
# for regenerating: for l in $(cat *.patch | grep -E "[0-9a-f]{40}" | cut -f2 -d ' '); do sed -i "/${l}/d" ../../../patchsrc; done
source misc/patchsrc
# get_patches $andi "$andi_commits_1" "korg" # lto-5.12.1-wip
# get_patches $andi "$andi_commits_2" "korg" # lto-5.12.2-wip
get_patches $andi "$andi_commits_3" "korg" # lto-5.12.3
get_patches $clear "$clear_commits" "git" # 5.11/clearlinux
