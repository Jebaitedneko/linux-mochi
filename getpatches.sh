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
	dirname=` echo $1 | cut -c20- | sed "s/\/commit//g;s/\//_/g" `
	echo -e "Getting patches from ${dirname}..."
	dir_setup=`rm -rf $dirname && mkdir $dirname`
	[ -d $dirname ] && $dir_setup || mkdir $dirname

	for l in $(echo $2); do
# 		do curl `echo $1/$l.patch` > $dirname/${i}_$(sanitize "$(curl `echo $1/$l.patch` \
# 													| sed -n '/Subject/,/^$/p;s/$\n/_/g' \
# 													| sed "s/Subject\: //g;s/ /_/g")").patch \
# 		&& i=$((i+1))
		curl `echo $1/$l.patch` > $dirname/${i}.patch \
		&& new_name=`cat $dirname/${i}.patch | sed -n '/Subject/,/^$/p;s/$\n/_/g' | sed "s/Subject\: //g;s/ /_/g"` \
		&& mv $dirname/${i}.patch $dirname/${i}_$(sanitize "${new_name}").patch \
		&& i=$((i+1))
	done

	[ -d custom_patches/${j}_${dirname} ] && rm -rf custom_patches/${j}_${dirname}
	mv $dirname custom_patches/${j}_${dirname} && j=$((j+1))
}
# for fetching sha: curl "repo_link" | grep "Copy the full SHA" | cut -f2 -d \" | grep -v "[0-9]:[0-9]"
# for cleanup: cat *.patch | grep From | grep -v From\: | cut -f 2 -d ' '
source .custom_patches
get_patches $kaz_repo "$kaz_commits"
get_patches $lazer_repo "$lazer_commits"
