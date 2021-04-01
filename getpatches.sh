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

	for l in $(echo $2)
		do curl `echo $1/$l.patch` > $dirname/${i}_$(sanitize "$(curl `echo $1/$l.patch` \
														| sed -n '/Subject/,/^$/p;s/$\n/_/g' \
														| sed "s/Subject\: //g;s/ /_/g")").patch \
		&& i=$((i+1))
	done

	mv $dirname custom_patches/${j}_${dirname} && j=$((j+1))
}

source .custom_patches
get_patches $kaz_repo "$kaz_commits"
