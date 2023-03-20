#!/usr/bin/env python3

import json
import numpy as np
import nibabel as nib

def load_parc_data(parc_path):

	return nib.load(parc_path)

def load_label_text(label_text_path):

	with open(label_text_path,'r') as tmp_f:
		label_text = tmp_f.readlines()	

	return label_text

def build_label_list(label_text,hemisphere):
	
	label_text = [ f.split('\n')[0] for f in label_text ]

	label_names = [ label_text[f] for f in range(len(label_text)) if (f % 2) == 0]
	voxel_values = [ int(label_text[f].split(' ')[0]) for f in range(len(label_text)) if (f % 2) == 1]

	label = []

	for f in range(len(label_names)):
		tmp = {}
		tmp['name'] = label_names[f]
		tmp['desc'] = f"value of {voxel_values[f]} indicates voxel belonging to {hemisphere} {label_names[f]}"
		tmp['label'] = voxel_values[f]
		tmp['voxel_value'] = voxel_values[f]
		label.append(tmp)

	return label

def combine_label_lists(lh_label,rh_label):

	len_lh = len(lh_label)

	for i in range(len(rh_label)):

		rh_label[i]['label'] = rh_label[i]['label'] + len_lh
		rh_label[i]['voxel_value'] = rh_label[i]['voxel_value'] + len_lh
		rh_label[i]['desc'] = f"value of {rh_label[i]['voxel_value']} indicates voxel belonging to right hemisphere {rh_label[i]['name']}"

	label = lh_label + rh_label

	return label

def output_label_json(label,label_path):

	with open(label_path,'w') as lab_f:
		json.dump(label,lab_f)

def output_parc_data(parc,outpath):

	nib.save(parc,outpath)

def update_parc(lh_parc,lh_data,rh_data,lh_label,parc_outpath):
	
	# find length of lh data
	len_lh = len(lh_label)

	# add all nonzero values in rh_data by length of lh data
	rh_data[rh_data>0] = rh_data[rh_data>0]+len_lh

	# binarize data in order to compute intersection (i.e. regions where there's overlap)
	lh_bin = (lh_data>0).astype(np.int_)
	rh_bin = (rh_data>0).astype(np.int_)

	# generate a mask and set those values in right hemisphere that overlap with left hemisphere to 0
	mask = lh_bin & rh_bin
	rh_data[mask>0] = 0

	# sum data to generate combined parcellation
	out_data = lh_data + rh_data

	out_parc = nib.Nifti1Image(out_data.astype(int),lh_parc.affine,lh_parc.header)

	output_parc_data(out_parc,parc_outpath)

def main():

	# set paths
	lh_label_path = './lh.label_text.txt'
	rh_label_path = './rh.label_text.txt'
	lh_parc_path = './lh.parc.nii.gz'
	rh_parc_path = './rh.parc.nii.gz'

	# load parcellation data
	lh_parc = load_parc_data(lh_parc_path)
	lh_parc_data = lh_parc.get_fdata()
	rh_parc = load_parc_data(rh_parc_path)
	rh_parc_data = rh_parc.get_fdata()

	# load label data
	lh_label_text = load_label_text(lh_label_path)
	rh_label_text = load_label_text(rh_label_path)

	# combine labels and output
	lh_label = build_label_list(lh_label_text,'left hemsiphere')
	rh_label = build_label_list(rh_label_text,'right hemsiphere')
	label = combine_label_lists(lh_label,rh_label)

	output_label_json(label,'./parcellation/label.json')

	# update right hemisphere parcellation and combine and output
	update_parc(lh_parc,lh_parc_data,rh_parc_data,lh_label,'./parcellation/parc.nii.gz')

if __name__ == '__main__':
	main()
