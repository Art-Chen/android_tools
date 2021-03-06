#!/bin/bash

# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2019 Shivam Kumar Jha <jha.shivam3@gmail.com>
#
# Helper functions

# Store project path
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null && pwd )"

# Common stuff
source $PROJECT_DIR/tools/common_script.sh

# Exit if no arguements
if [ -z "$1" ] ; then
	echo -e "${bold}${red}Supply dir's as arguements!${nocol}"
	exit
fi

# Exit if missing token's
if [ -z "$GIT_TOKEN" ] || [ -z "$TG_API" ] ; then
	echo -e "${bold}${cyan}Missing GitHub token. Exiting.${nocol}"
	exit
fi

# o/p
for var in "$@"; do
	ROM_PATH=$( realpath "$var" )
	if [ ! -d "$ROM_PATH" ] ; then
		echo -e "${bold}${red}$ROM_PATH is not a valid directory!${nocol}"
		exit
	fi
	cd "$ROM_PATH"
	GIT_OAUTH_TOKEN="$DUMPYARA_TOKEN"
	ORG=AndroidDumps
	TG_TOKEN="$TG_API"
	cd $ROM_PATH/
	ls system/build*.prop 2>/dev/null || ls system/system/build*.prop 2>/dev/null || { echo "No system build*.prop found, pushing cancelled!" && exit ;}
	flavor=$(grep -oP "(?<=^ro.build.flavor=).*" -hs {system,system/system,vendor}/build*.prop)
	[[ -z "${flavor}" ]] && flavor=$(grep -oP "(?<=^ro.vendor.build.flavor=).*" -hs vendor/build*.prop)
	[[ -z "${flavor}" ]] && flavor=$(grep -oP "(?<=^ro.system.build.flavor=).*" -hs {system,system/system}/build*.prop)
	[[ -z "${flavor}" ]] && flavor=$(grep -oP "(?<=^ro.build.type=).*" -hs {system,system/system}/build*.prop)
	release=$(grep -oP "(?<=^ro.build.version.release=).*" -hs {system,system/system,vendor}/build*.prop)
	[[ -z "${release}" ]] && release=$(grep -oP "(?<=^ro.vendor.build.version.release=).*" -hs vendor/build*.prop)
	[[ -z "${release}" ]] && release=$(grep -oP "(?<=^ro.system.build.version.release=).*" -hs {system,system/system}/build*.prop)
	id=$(grep -oP "(?<=^ro.build.id=).*" -hs {system,system/system,vendor}/build*.prop)
	[[ -z "${id}" ]] && id=$(grep -oP "(?<=^ro.vendor.build.id=).*" -hs vendor/build*.prop)
	[[ -z "${id}" ]] && id=$(grep -oP "(?<=^ro.system.build.id=).*" -hs {system,system/system}/build*.prop)
	incremental=$(grep -oP "(?<=^ro.build.version.incremental=).*" -hs {system,system/system,vendor}/build*.prop)
	[[ -z "${incremental}" ]] && incremental=$(grep -oP "(?<=^ro.vendor.build.version.incremental=).*" -hs vendor/build*.prop)
	[[ -z "${incremental}" ]] && incremental=$(grep -oP "(?<=^ro.system.build.version.incremental=).*" -hs {system,system/system}/build*.prop)
	tags=$(grep -oP "(?<=^ro.build.tags=).*" -hs {system,system/system,vendor}/build*.prop)
	[[ -z "${tags}" ]] && tags=$(grep -oP "(?<=^ro.vendor.build.tags=).*" -hs vendor/build*.prop)
	[[ -z "${tags}" ]] && tags=$(grep -oP "(?<=^ro.system.build.tags=).*" -hs {system,system/system}/build*.prop)
	fingerprint=$(grep -oP "(?<=^ro.build.fingerprint=).*" -hs {system,system/system,vendor}/build*.prop)
	[[ -z "${fingerprint}" ]] && fingerprint=$(grep -oP "(?<=^ro.vendor.build.fingerprint=).*" -hs vendor/build*.prop)
	[[ -z "${fingerprint}" ]] && fingerprint=$(grep -oP "(?<=^ro.system.build.fingerprint=).*" -hs {system,system/system}/build*.prop)
	brand=$(grep -oP "(?<=^ro.product.brand=).*" -hs {system,system/system,vendor}/build*.prop | head -1)
	[[ -z "${brand}" ]] && brand=$(grep -oP "(?<=^ro.product.vendor.brand=).*" -hs vendor/build*.prop | head -1)
	[[ -z "${brand}" ]] && brand=$(grep -oP "(?<=^ro.vendor.product.brand=).*" -hs vendor/build*.prop | head -1)
	[[ -z "${brand}" ]] && brand=$(grep -oP "(?<=^ro.product.system.brand=).*" -hs {system,system/system}/build*.prop | head -1)
	[[ -z "${brand}" ]] && brand=$(echo $fingerprint | cut -d / -f1 )
	codename=$(grep -oP "(?<=^ro.product.device=).*" -hs {system,system/system,vendor}/build*.prop | head -1)
	[[ -z "${codename}" ]] && codename=$(grep -oP "(?<=^ro.product.vendor.device=).*" -hs vendor/build*.prop | head -1)
	[[ -z "${codename}" ]] && codename=$(grep -oP "(?<=^ro.vendor.product.device=).*" -hs vendor/build*.prop | head -1)
	[[ -z "${codename}" ]] && codename=$(grep -oP "(?<=^ro.product.system.device=).*" -hs {system,system/system}/build*.prop | head -1)
	[[ -z "${codename}" ]] && codename=$(echo $fingerprint | cut -d / -f3 | cut -d : -f1 )
	[[ -z "${codename}" ]] && codename=$(grep -oP "(?<=^ro.build.fota.version=).*" -hs {system,system/system}/build*.prop | cut -d - -f1 | head -1)
	description=$(grep -oP "(?<=^ro.build.description=).*" -hs {system,system/system,vendor}/build*.prop)
	[[ -z "${description}" ]] && description=$(grep -oP "(?<=^ro.vendor.build.description=).*" -hs vendor/build*.prop)
	[[ -z "${description}" ]] && description=$(grep -oP "(?<=^ro.system.build.description=).*" -hs {system,system/system}/build*.prop)
	[[ -z "${description}" ]] && description="$flavor $release $id $incremental $tags"
	branch=$(echo $description | tr ' ' '-')
	repo=$(echo $brand\_$codename\_dump | tr '[:upper:]' '[:lower:]')
	printf "\nflavor: $flavor\nrelease: $release\nid: $id\nincremental: $incremental\ntags: $tags\nfingerprint: $fingerprint\nbrand: $brand\ncodename: $codename\ndescription: $description\nbranch: $branch\nrepo: $repo\n"

	git init
	if [ -z "$(git config --get user.email)" ]; then
		git config user.email AndroidDumps@github.com
	fi
	if [ -z "$(git config --get user.name)" ]; then
		git config user.name AndroidDumps
	fi
	git checkout -b $branch
	find -size +97M -printf '%P\n' -o -name *sensetime* -printf '%P\n' -o -name *.lic -printf '%P\n' > .gitignore
	git add --all

	curl -s -X POST -H "Authorization: token ${GIT_OAUTH_TOKEN}" -d '{ "name": "'"$repo"'" }' "https://api.github.com/orgs/${ORG}/repos" #create new repo
	git remote add origin https://github.com/$ORG/${repo,,}.git
	git commit -asm "Add ${description}"
	git push https://$GIT_OAUTH_TOKEN@github.com/$ORG/${repo,,}.git $branch ||

	(git update-ref -d HEAD ; git reset system/ vendor/ ;
	git checkout -b $branch ;
	git commit -asm "Add extras for ${description}" ;
	git push https://$GIT_OAUTH_TOKEN@github.com/$ORG/${repo,,}.git $branch ;
	git add vendor/ ;
	git commit -asm "Add vendor for ${description}" ;
	git push https://$GIT_OAUTH_TOKEN@github.com/$ORG/${repo,,}.git $branch ;
	git add system/system/app/ system/system/priv-app/ || git add system/app/ system/priv-app/ ;
	git commit -asm "Add apps for ${description}" ;
	git push https://$GIT_OAUTH_TOKEN@github.com/$ORG/${repo,,}.git $branch ;
	git add system/ ;
	git commit -asm "Add system for ${description}" ;
	git push https://$GIT_OAUTH_TOKEN@github.com/$ORG/${repo,,}.git $branch ;)

	# Telegram channel
	if [ ! -z "$TG_TOKEN" ]; then
		CHAT_ID="@android_dumps"
		commit_head=$(git log --format=format:%H | head -n 1)
		commit_link=$(echo "https://github.com/$ORG/$repo/commit/$commit_head")
		echo -e "Sending telegram notification"
		printf "<b>Brand: $brand</b>" > $PROJECT_DIR/working/tg.html
		printf "\n<b>Device: $codename</b>" >> $PROJECT_DIR/working/tg.html
		printf "\n<b>Version:</b> $release" >> $PROJECT_DIR/working/tg.html
		printf "\n<b>Fingerprint:</b> $fingerprint" >> $PROJECT_DIR/working/tg.html
		printf "\n<b>GitHub:</b>" >> $PROJECT_DIR/working/tg.html
		printf "\n<a href=\"$commit_link\">Commit</a>" >> $PROJECT_DIR/working/tg.html
		printf "\n<a href=\"https://github.com/$ORG/$repo/tree/$branch/\">$codename</a>" >> $PROJECT_DIR/working/tg.html
		TEXT=$(cat $PROJECT_DIR/working/tg.html)
		curl -s "https://api.telegram.org/bot${TG_TOKEN}/sendmessage" --data "text=${TEXT}&chat_id=${CHAT_ID}&parse_mode=HTML&disable_web_page_preview=True" > /dev/null
		rm -rf $PROJECT_DIR/working/tg.html
	fi
	cd "$PROJECT_DIR"
done
