#!/bin/bash

# https://stackoverflow.com/a/44811468
sanitize() {
   local s="${1?need a string}" # receive input in first argument
   s="${s//[^[:alnum:]]/-}"     # replace all non-alnum characters to -
   s="${s//+(-)/-}"             # convert multiple - to single -
   s="${s/#-}"                  # remove - from start
   s="${s/%-}"                  # remove - from end
   echo "${s,,}"                # convert to lowercase
}

j=0
get_patches() {
	i=0
	[[ `echo $1 | grep github` ]] \
		&& dirname=` echo $1 | cut -c20- | sed "s/\/commit//g;s/\//_/g" ` \
		|| dirname=` echo $1 | grep -o "git/.*" | grep -o ".*.git" | sed "s/.git//g;s/git\///g;s/\//_/g" `
	echo -e "Getting patches from ${dirname}"
	dir_setup=`rm -rf $dirname && mkdir $dirname`
	[ -d $dirname ] && $dir_setup || mkdir $dirname

	for l in $(echo $2); do
		if [[ `echo $1 | grep github` ]]; then
			echo -e "Getting ${1}/${l}" && curl -s `echo $1/$l.patch` > $dirname/${i}.patch
		else
			echo -e "Getting ${1}=${l}" && curl -s `echo $1=$l` > $dirname/${i}.patch
		fi \
		&& new_name=`cat $dirname/${i}.patch | sed -n '/Subject/,/^$/p;s/$\n/_/g' | sed "s/Subject\: //g;s/ /_/g"` \
		&& mv $dirname/${i}.patch $dirname/${i}_$(sanitize "${new_name}").patch \
		&& i=$((i+1))
	done

	[ -d custom_patches/${j}_${dirname} ] && rm -rf custom_patches/${j}_${dirname}
	mv $dirname custom_patches/${j}_${dirname} && j=$((j+1))
}
# for fetching sha: curl -s "repo_link" | grep "Copy the full SHA" | cut -f2 -d \"
# for fetching sha from korg curl -s "repo_link" | grep -E "[0-9a-f]{40}" | sed "s/.*id=//g;s/'>.*//g"
# for cleanup: cat *.patch | grep -E "[0-9a-f]{40}" | cut -f2 -d ' '
# for regenerating: for l in $(cat *.patch | grep -E "[0-9a-f]{40}" | cut -f2 -d ' '); do sed -i "/${l}/d" ../../../.custom_patches; done
source .custom_patches
#get_patches $kaz_repo "$kaz_commits"
#get_patches $lazer_repo "$lazer_commits"
#get_patches $buzz_repo "$buzz_commits"
#get_patches $sarisan_repo "$sarisan_commits"
#get_patches $andi_repo "$andi_commits"
