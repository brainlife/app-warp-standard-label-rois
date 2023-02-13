#!/bin/bash

freesurfer=`jq -r '.freesurfer' config.json` # /home/bacaron/Desktop/tracking-test-liberty/output
fsaverage=`jq -r '.fsaverage' config.json` # fsaverage
apply_affine=`jq -r '.apply_affine' config.json` # for hcp, should be False
labeldir=`jq -r '.label' config.json` # path to surface label datatype
rois=`jq -r '.rois' config.json` # set up only so all rois can be added into one directory without additional app
labels=(`find ${labeldir}/*.gii`)
surfaces="pial white inflated sphere.reg"
hemispheres="lh rh"

[ ! -d ./freesurfer ] && cp -R ${freesurfer} ./freesurfer && freesurfer="./freesurfer"
[ ! -d ${rois} ] && mkdir rois && cp -R ${rois} ./rois/rois/ || mkdir rois rois/rois
[ ! -d ./fsaverage ] && cp -R /usr/local/freesurfer/subjects/${fsaverage} ./fsaverage && fsaverage="./fsaverage"

[ ! -f ${freesurfer}/mri/brain.finalsurfs.nii.gz ] && mri_convert ${freesurfer}/mri/brain.finalsurfs.mgz ${freesurfer}/mri/brain.finalsurfs.nii.gz

# identify appropriate transform (IS THIS NEEDED?)
if [[ ${apply_affine} == True ]]; then
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

# convert and apply c_ras transform
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
		[ ! -f ${fsaverage}/surf/${hem}.${surf}.surf.gii ] && mris_convert ${fsaverage}/surf/${hem}.${surf} ${fsaverage}/surf/${hem}.${surf}.surf.gii
	done
done

# convert label file to gifti
for labs in ${labels[*]}
do
	name=${labs%%.label}
	hem=${name%%.*}
	echo $name
	[ ! -f ./${labs}.gii ] && mris_convert --label ${labeldir}/${labs} ${name##*h.} ${fsaverage}/surf/${hem}.white.surf.gii ./${labs}.gii

	[ ! -f ./${name}.native.label.gii ] && wb_command -label-resample ./${labs}.gii ${fsaverage}/surf/${hem}.sphere.reg.surf.gii ${freesurfer}/surf/${hem}.sphere.reg.surf.gii ADAP_BARY_AREA -area-surfs ${fsaverage}/surf/${hem}.white.surf.gii ${freesurfer}/surf/${hem}.white.surf.gii ./${name}.native.label.gii

	[ ! -f ./${name}.nii.gz ] && wb_command -label-to-volume-mapping ./${name}.native.label.gii ./${hem}.white.surf.gii ${freesurfer}/mri/brain.finalsurfs.nii.gz ./${name}.nii.gz -ribbon-constrained ./${hem}.white.surf.gii ./${hem}.pial.surf.gii
done
