#!/bin/bash

left=`jq -r '.label_left' config.json`
right=`jq -r '.label_right' config.json`
fsaverage=`jq -r '.fsaverage' config.json`

hemispheres='lh rh'

# convert annot to volume parcellation
for hemi in ${hemispheres}
do
	if [[ ${hemi} == 'lh' ]]; then
		annot_data=${left}
	else
		annot_data=${right}
	fi

	[ ! -f ./${hemi}.label_text.txt ] && cp ${annot_data} ./${hemi}.annot.label.gii && wb_command -label-export-table ./${hemi}.annot.label.gii ./${hemi}.label_text.txt
done

if [ ! -f lh.label_text.txt ] || [ ! -f rh.label_text.txt ]; then
	echo "something went wrong. check logs and derivatives"
	exit 1
fi