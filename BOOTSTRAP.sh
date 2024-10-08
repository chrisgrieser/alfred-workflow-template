#!/usr/bin/env zsh

# GUARD
set -e # abort when any command errors, prevents this script from self-removing at the end if anything went wrong

# ensure the local folder has the same name as the this repo's folder
# requirement for rsync-transfer of files
workflow_id=$(basename "$PWD")
prefs_location=$(defaults read com.runningwithcrayons.Alfred-Preferences syncfolder | sed "s|^~|$HOME|")
local_workflow="$prefs_location/Alfred.alfredpreferences/workflows/$workflow_id"

if [[ ! -d "$local_workflow" ]]; then
	print "\e[1;31mThere is no folder called '$workflow_id' in the local Alfred workflow folder.\e[0m"
	print "Rename the respective folder. For convenience, \e[1;34m$workflow_id\e[0m has been copied to the clipboard."
	echo -n "$workflow_id" | pbcopy
	open "$prefs_location/Alfred.alfredpreferences/workflows/"
	exit 1
fi

#───────────────────────────────────────────────────────────────────────────────

# plugin name is the same as the git repo name and can therefore be inferred
repo=$(git remote -v | head -n1 | sed 's/.*:\(.*\) .*/\1/')
id=$(echo "$repo" | cut -d/ -f2)
owner=$(echo "$repo" | cut -d/ -f1)
display_name=$(echo "$id" | tr "-" " " | sed 's/alfred/Alfred/')

# desc can be inferred from github description (not using jq for portability)
desc=$(curl -sL "https://api.github.com/repos/$repo" | grep "description" | head -n1 | cut -d'"' -f4)

# current year for license
year=$(date +"%Y")

#───────────────────────────────────────────────────────────────────────────────

LC_ALL=C # prevent byte sequence error

# replace them all
# $1: placeholder name as {{mustache-template}}
# $2: the replacement
function replacePlaceholders() {
	# INFO macOS' sed requires `sed -i ''`, remove the `''` when on Linux or using GNU sed
	find . -type f -not -path '*/\.git/*' -exec sed -i '' "s|$1|$2|g" {} \;
}

replacePlaceholders "{{repo}}" "$repo" # has `/`, so `sed` must use different delimiter
replacePlaceholders "{{owner}}" "$owner"
replacePlaceholders "{{workflow-id}}" "$id"
replacePlaceholders "{{workflow-name}}" "$display_name"
replacePlaceholders "{{workflow-description}}" "$desc"
replacePlaceholders "{{year}}" "$year"

#───────────────────────────────────────────────────────────────────────────────

# transfer local files
# INFO will also delete this script, since it does not exist in local repo
just transfer-changes-FROM-local

git add --all && git commit -m "init: bootstrap"

print "\033[1;32mSuccess.\033[0m"
echo "Opening Alfred Forum for sharing…"
sleep 1
open "https://www.alfredforum.com/forum/3-share-your-workflows/"
