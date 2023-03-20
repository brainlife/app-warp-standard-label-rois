#!/bin/bash

# top variables defined from config.json
freesurfer=`jq -r '.freesurfer' config.json` # /home/bacaron/Desktop/tracking-test-liberty/output
fsaverage_left=`jq -r '.fsaverage_left' config.json` # fsaverage surfaces
fsaverage_right=`jq -r '.fsaverage_right' config.json` # fsaverage surfaces
apply_affine=`jq -r '.apply_affine' config.json` # for hcp, should be False
label_left=`jq -r '.label_left' config.json` # path to left label gifti
label_right=`jq -r '.label_right' config.json` # path to right label gifti
label_json=`jq -r '.label_json' config.json` # path to label.json
rois=`jq -r '.rois' config.json` # set up only so all rois can be added into one directory without additional app

if [ ! -f ${label_json} ]; then
	name="label"
else
	name=`jq -r '.name' ${label_json}` # pmhg
fi

# make some directories
[ ! -d ./parcellation ] && mkdir parcellation
[ ! -d verts ] && mkdir verts verts/left verts/right
[ ! -d labels_out ] && mkdir labels_out
[ ! -d labels ] && mkdir labels
[ ! -d raw ] && mkdir raw
[ ! -d fsaverage ] && mkdir fsaverage
fsaverage="./fsaverage"

# copy over the subjects freesurfe directory
[ ! -d ./freesurfer ] && cp -R ${freesurfer} ./freesurfer && freesurfer="./freesurfer"

# loop through hemispheres and surfaces to convert to naming schema for connectome workbench
hemispheres="lh rh"
surfaces="pial white inflated sphere.reg"
for hem in ${hemispheres}
do
	if [[ ${hem} == "lh" ]]; then
		hemi=${fsaverage_left}
	else
		hemi=${fsaverage_right}
	fi

	for surf in ${surfaces}
	do
		if [[ ${surf} == "sphere.reg" ]] && [ ! -f ${hemi}/${hem}.${surf}.gii ]; then
			echo "surface vertices input is missing sphere.reg. this is required to map between the template and subject spaces. please check and reupload if necessary"
			exit 1
		fi
		[ ! -f ${fsaverage}/${hem}.${surf}.surf.gii ] && mris_convert ${hemi}/${hem}.${surf}.gii ${fsaverage}/${hem}.${surf}.surf.gii
	done
done

# convert labels to proper naming schema for connectome workbench then set loopable variable for labels
[ ! -f labels/lh.${name}.label.gii ] && cp ${label_left} labels/lh.${name}.label.gii && wb_command -set-structure labels/lh.${name}.label.gii "CORTEX_LEFT"
[ ! -f labels/rh.${name}.label.gii ] && cp ${label_right} labels/rh.${name}.label.gii && wb_command -set-structure labels/rh.${name}.label.gii "CORTEX_RIGHT"
labels=(`find labels/*.gii`)

# # convert brain.finalsurfs to nii
[ ! -f ${freesurfer}/mri/brain.finalsurfs.nii.gz ] && mri_convert ${freesurfer}/mri/brain.finalsurfs.mgz ${freesurfer}/mri/brain.finalsurfs.nii.gz

# # identify appropriate transform if requested by user. copied directly from HCP pipelines
if [[ ${apply_affine} == true ]]; then
	if [ ! -f c_ras.mat ]; then
		echo "identifying transform between freesurfer and anat space"
		MatrixXYZ=`mri_info --cras ${freesurfer}/mri/brain.finalsurfs.mgz`
		MatrixX=`echo ${MatrixXYZ} | awk '{print $1;}'`
		MatrixY=`echo ${MatrixXYZ} | awk '{print $2;}'`
		MatrixZ=`echo ${MatrixXYZ} | awk '{print $3;}'`
		echo "1 0 0 ${MatrixX}" >  c_ras.mat
		echo "0 1 0 ${MatrixY}" >> c_ras.mat
		echo "0 0 1 ${MatrixZ}" >> c_ras.mat
		echo "0 0 0 1"          >> c_ras.mat
	fi
fi

# # convert and apply c_ras transform
for hem in ${hemispheres}
do
	for surf in ${surfaces}
	do
		echo $surf $hemi
		[ ! -f ${freesurfer}/surf/${hem}.${surf}.surf.gii ] && mris_convert ${freesurfer}/surf/${hem}.${surf} ${freesurfer}/surf/${hem}.${surf}.surf.gii
		if [[ ${apply_afine} == True ]]; then
			[ ! -f ./${hem}.${surf}.surf.gii ] && wb_command -surface-apply-affine ${freesurfer}/surf/${hem}.${surf}.surf.gii c_ras.mat ./${hem}.${surf}.surf.gii
		else
			[ ! -f ./${hem}.${surf}.surf.gii ] && cp ${freesurfer}/surf/${hem}.${surf}.surf.gii ./
		fi
	done
done

# # convert label file to gifti
for labs in ${labels[*]}
do
	labname=${labs##labels/}
	hem=${labname%%.*}
	echo $name
	[ ! -f ./${name}.native.label.gii ] && wb_command -label-resample ${labs} ${fsaverage}/${hem}.sphere.reg.surf.gii ./${hem}.sphere.reg.surf.gii ADAP_BARY_AREA -area-surfs ${fsaverage}/${hem}.white.surf.gii ./${hem}.white.surf.gii ./${hem}.${name}.native.label.gii
	[ ! -f ./${hem}.parc.nii.gz ] && wb_command -label-to-volume-mapping ./${hem}.${name}.native.label.gii ./${hem}.white.surf.gii ${freesurfer}/mri/brain.finalsurfs.nii.gz ./${hem}.parc.nii.gz -ribbon-constrained ./${hem}.white.surf.gii ./${hem}.pial.surf.gii
done

# copy files to output directories
for hem in ${hemispheres}
do
	if [[ ${hem} == "lh" ]]; then
		hemi="left"
	else
		hemi="right"
	fi

	for surf in ${surfaces}
	do
		[ ! -f verts/${hemi}/${hem}.${surf}.gii ] && cp ${hem}.${surf}.surf.gii ./verts/${hemi}/${hem}.${surf}.gii
	done

	[ ! -f labels_out/${hemi}.gii ] && cp ${hem}.${name}.native.label.gii ./labels_out/${hemi}.gii
	# [ ! -f labels_out/label.json ] && cp ${label_json} ./labels_out/label.json
done

# final check
if [ ! -f labels_out/left.gii ] || [ ! -f labels_out/right.gii ]; then
	echo "something went wrong. check logs and derivative files"
	exit 1
else
	echo "complete"
	# mv *.gii ./freesurfer ./fsaverage ./labels ./raw/
	exit 0
fi
