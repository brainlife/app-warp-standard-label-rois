<h1 align="center">Warp standard surface labels to subject volume</h1>

<p align="center">
  Template-surface labels (for example on fsaverage) resampled to a subject's FreeSurfer surfaces and mapped into volume ROIs or a volumetric parcellation with Connectome Workbench.
</p>

<p align="center">
  <a href="https://github.com/brainlife/abcd-spec"><img src="https://img.shields.io/badge/ABCD_Spec-v1.1-green.svg" alt="ABCD Spec v1.1"></a>
  <a href="https://doi.org/10.25663/brainlife.app.748"><img src="https://img.shields.io/badge/Brainlife-brainlife.app.748-blue.svg" alt="Run on brainlife.io"></a>
  <a href="https://github.com/brainlife/app-warp-standard-label-rois/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-MIT-lightgrey.svg" alt="MIT license"></a>
</p>

> 📍 **This branch, `parcellation-app-v1.0_wb-v1.5.0`, is the brainlife.io App Warp and resample surface label annotation to parcellation volume (Freesurfer space)** ([doi:10.25663/brainlife.app.748](https://doi.org/10.25663/brainlife.app.748)). The other Apps in this repository are listed under **Versions on brainlife.io** below.

## 🧠 At a glance

<!-- brainlife-app:begin (generated from the App manifest; edit the manifest, not this block) -->

> **Resamples a template-surface parcellation to a subject's FreeSurfer surfaces and builds a volumetric parcellation in FreeSurfer space with Connectome Workbench 1.5.0.**

Resamples left and right label GIFTIs from the template sphere to the subject sphere (wb_command -label-resample), maps them into the FreeSurfer volume with ribbon-constrained label-to-volume mapping, exports the label tables and combines both hemispheres into parc.nii.gz with a label.json. Use it to obtain a subject-space volumetric version of a surface atlas, for example for connectomics.

| | |
|---|---|
| 📥 **Inputs** | `neuro/freesurfer` · `neuro/surface/vertices` · `neuro/surface/data` |
| 📤 **Outputs** | `neuro/parcellation/volume` · `neuro/surface/data` · `neuro/surface/vertices` · `raw` |
| 🐳 **Container** | `brainlife/connectome_workbench:1.5.0` |
| ⚙️ **Resources** | 8 CPUs · 1.5 h walltime |
| 🔑 **Requires** | `FREESURFER_LICENSE` |
| 🔗 **Run it** | [doi.org/10.25663/brainlife.app.748](https://doi.org/10.25663/brainlife.app.748) |

#### 📥 Inputs

| Input | Datatype | Required | Description |
|---|---|---|---|
| `freesurfer` | `neuro/freesurfer` | yes | FreeSurfer recon-all output of the target subject. |
| `standard_verts` | `neuro/surface/vertices` | yes | Template (for example fsaverage) surfaces for left and right hemispheres on which the labels are defined. Must include ?h.sphere.reg.gii; the App exits otherwise. |
| `standard_label` | `neuro/surface/data` | yes | Left and right GIFTI label files on the template surfaces, with a label.json key. |

#### 📤 Outputs

| Output | Datatype | Description |
|---|---|---|
| `parcellation` | `neuro/parcellation/volume` | Volumetric parcellation (parc.nii.gz) and label.json in FreeSurfer subject space. |
| `labels_out` | `neuro/surface/data` | Labels resampled to the subject's native surfaces (left.gii, right.gii) and label.json. |
| `verts` | `neuro/surface/vertices` | Subject pial, white, inflated and sphere.reg surfaces in GIFTI format. |
| `raw` | `raw` | Intermediate surfaces, labels and volumes. |

<details>
<summary><b>⚙️ Parameters</b> (1)</summary>

| Parameter | Type | Default | Description |
|---|---|---|---|
| `apply_affine` | boolean | `false` | This may be an optional parameter for your data. Sometimes the correspondence between freesurfer volume and surface space is off. This will apply a fix in those situations if true. if the final ROIs don't properly align, try rerunning and setting this to true |

</details>

<!-- brainlife-app:end -->

## 🏷️ Versions on brainlife.io

Each App is built from its own branch of this repository.

| App | Output | Branch | Run it | Status |
|---|---|---|---|---|
| **Warp and resample surface label annotation to parcellation volume (Freesurfer space)** (this branch) | `neuro/parcellation/volume` | [`parcellation-app-v1.0_wb-v1.5.0`](https://github.com/brainlife/app-warp-standard-label-rois/tree/parcellation-app-v1.0_wb-v1.5.0) | [doi:10.25663/brainlife.app.748](https://doi.org/10.25663/brainlife.app.748) | current |
| Warp and resample surface label ROIs to volume (Freesurfer space) | `neuro/rois` | [`app-v1.0_wb-v1.5.0`](https://github.com/brainlife/app-warp-standard-label-rois/tree/app-v1.0_wb-v1.5.0) | [doi:10.25663/brainlife.app.731](https://doi.org/10.25663/brainlife.app.731) | current |

## 🔬 How it works

1. The template surfaces (`pial`, `white`, `inflated`, `sphere.reg`) and the subject's FreeSurfer surfaces are converted to GIFTI.
2. Each hemisphere's label file is resampled from the template sphere to the subject sphere with `wb_command -label-resample` (`ADAP_BARY_AREA`, using the white surfaces as area surfaces).
3. The resampled labels are mapped into the subject's FreeSurfer volume (`brain.finalsurfs`) with ribbon-constrained `wb_command -label-to-volume-mapping`.
4. The **ROIs** App writes one ROI volume per hemisphere. The **parcellation** App also exports the label tables (`wb_command -label-export-table`) and combines both hemispheres into `parc.nii.gz` with a `label.json` (right-hemisphere values are offset by the number of left-hemisphere labels).

## 🚀 Running the App

### ☁️ On brainlife.io

Open the App at [doi.org/10.25663/brainlife.app.748](https://doi.org/10.25663/brainlife.app.748) (parcellation) or [doi.org/10.25663/brainlife.app.731](https://doi.org/10.25663/brainlife.app.731) (ROIs) and choose:

- a `neuro/freesurfer` dataset of the subject;
- a `neuro/surface/vertices` dataset with the template surfaces, which must include `sphere.reg`;
- a `neuro/surface/data` dataset with the left and right label GIFTIs and `label.json`;
- optionally (ROIs App only) an existing `neuro/rois` dataset, so the new ROIs are added to it.

Press **Execute**. The ROIs or the parcellation, the labels on the subject's native surfaces and the subject surfaces in GIFTI format are archived to your project.

### 💻 Locally

You need [Singularity/Apptainer](https://apptainer.org/), [`jq`](https://jqlang.github.io/jq/) and a [FreeSurfer license](https://surfer.nmr.mgh.harvard.edu/registration.html). `main` runs in `brainlife/connectome_workbench:1.5.0` (and `brainlife/dipy:1.4.1` for the parcellation step).

1. Clone this repository and check out the App you want (for example `git checkout parcellation-app-v1.0_wb-v1.5.0`).
2. Create `config.json` with the paths to your inputs:

   ```json
   {
       "freesurfer": "/input/freesurfer/output",
       "fsaverage_left": "/input/verts/left",
       "fsaverage_right": "/input/verts/right",
       "label_left": "/input/labels/left.gii",
       "label_right": "/input/labels/right.gii",
       "label_json": "/input/labels/label.json",
       "apply_affine": false
   }
   ```

   The ROIs App also reads an optional `"rois"` key pointing to an existing ROIs directory.

3. Export the contents of your license and run the App:

   ```bash
   export FREESURFER_LICENSE="$(cat ~/freesurfer/license.txt)"
   ./main
   ```

## 📦 Outputs

```text
rois/rois/       lh.<name>.nii.gz and rh.<name>.nii.gz volume ROIs (ROIs App)
parcellation/    parc.nii.gz and label.json (parcellation App)
labels_out/      left.gii and right.gii labels on the subject's native surfaces, label.json
verts/left/      lh.pial.gii, lh.white.gii, lh.inflated.gii, lh.sphere.reg.gii
verts/right/     the same surfaces for the right hemisphere
raw/             intermediate surfaces, labels and volumes
```

`<name>` is the `name` field of the input `label.json` (or `label` when there is none).

## 🩺 Troubleshooting

- **`surface vertices input is missing sphere.reg…`**: the template surfaces must include `lh.sphere.reg.gii` and `rh.sphere.reg.gii`; they are needed to map between template and subject spaces.
- **`Please set FREESURFER_LICENSE in .bashrc`**: export your FreeSurfer license in `FREESURFER_LICENSE` before running `./main`.
- **`something went wrong. check logs and derivative files`**: the resampled label files were not produced; check the log. In the parcellation App, `something went wrong. check logs and derivatives` means `parc.nii.gz` or `label.json` was not produced.
- **ROIs do not line up with the anatomy**: `apply_affine` is meant to correct a mismatch between FreeSurfer volume and surface coordinates (the `c_ras` offset, as in the HCP pipelines). In the current code the transform is computed but not applied to the surfaces, because the check uses a misspelled variable (`apply_afine`) in `warp-labels.sh`.

## 📚 Citing

> [!TIP]
> If you use this App in your work, please cite the App, the software it builds on and brainlife.io (below). GitHub's **Cite this repository** button gives the App citation in APA and BibTeX.

- Warp and resample surface label annotation to parcellation volume (Freesurfer space). brainlife.io App. [doi:10.25663/brainlife.app.748](https://doi.org/10.25663/brainlife.app.748)
- Fischl. FreeSurfer. *NeuroImage* 62:774-781 (2012). [doi:10.1016/j.neuroimage.2012.01.021](https://doi.org/10.1016/j.neuroimage.2012.01.021)
- Garyfallidis et al. Dipy, a library for the analysis of diffusion MRI data. *Frontiers in Neuroinformatics* 8 (2014). [doi:10.3389/fninf.2014.00008](https://doi.org/10.3389/fninf.2014.00008)
- Marcus et al. Informatics and Data Mining Tools and Strategies for the Human Connectome Project. *Frontiers in Neuroinformatics* 5 (2011). [doi:10.3389/fninf.2011.00004](https://doi.org/10.3389/fninf.2011.00004)
- Hayashi S, Caron BA, Heinsfeld AS, et al. brainlife.io: a decentralized and open-source cloud platform to support neuroscience research. *Nature Methods* 21:809–813 (2024). [doi:10.1038/s41592-024-02237-2](https://doi.org/10.1038/s41592-024-02237-2)
- Avesani P, McPherson B, Hayashi S, et al. The open diffusion data derivatives, brain data upcycling via integrated publishing of derivatives and reproducible open cloud services. *Scientific Data* 6:69 (2019). [doi:10.1038/s41597-019-0073-y](https://doi.org/10.1038/s41597-019-0073-y)

## 👥 Authors

- Brad Caron

## 💰 Funding

[![Wellcome-226486/Z/22/Z](https://img.shields.io/badge/Wellcome-226486%2FZ%2F22%2FZ-purple.svg)](https://wellcome.org/)
[![NIH-NINDS-U24NS140384](https://img.shields.io/badge/NIH_NINDS-U24NS140384-green.svg)](https://reporter.nih.gov/project-details/11261037)
[![NIH-NINDS-UM1NS132207](https://img.shields.io/badge/NIH_NINDS-UM1NS132207-green.svg)](https://reporter.nih.gov/project-details/11411328)
[![NIH-NIBIB-R01EB029272](https://img.shields.io/badge/NIH_NIBIB-R01EB029272-green.svg)](https://reporter.nih.gov/project-details/10262925)
[![NIH-NIBIB-R01EB030896](https://img.shields.io/badge/NIH_NIBIB-R01EB030896-green.svg)](https://reporter.nih.gov/project-details/10428625)
[![NIH-NIMH-R01MH126699](https://img.shields.io/badge/NIH_NIMH-R01MH126699-green.svg)](https://reporter.nih.gov/project-details/10460628)
[![NIH-NIDCD-R01DC020088](https://img.shields.io/badge/NIH_NIDCD-R01DC020088-green.svg)](https://reporter.nih.gov/project-details/11140284)
[![NSF-BCS-1734853](https://img.shields.io/badge/NSF_BCS-1734853-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=1734853)
[![NSF-BCS-2203524](https://img.shields.io/badge/NSF_BCS-2203524-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=2203524)
[![NSF-IIS-1636893](https://img.shields.io/badge/NSF_IIS-1636893-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=1636893)
[![NSF-OAC-2148729](https://img.shields.io/badge/NSF_OAC-2148729-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=2148729)
[![NSF-IIS-1912270](https://img.shields.io/badge/NSF_IIS-1912270-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=1912270)
[![NSF-IIS-2148700](https://img.shields.io/badge/NSF_IIS-2148700-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=2148700)
[![NSF-OAC-1916518](https://img.shields.io/badge/NSF_OAC-1916518-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=1916518)

<sub>brainlife.io is publicly funded, and acknowledging that support helps keep it running. This App was developed with support from Wellcome, the U.S. National Institutes of Health (including the BRAIN Initiative BRAIN CONNECTS program: The Axonal Projectome EXchange, U24NS140384, and the Center for Mesoscale Connectomics, UM1NS132207) and the U.S. National Science Foundation.</sub>

## ⚖️ License

[MIT](https://github.com/brainlife/app-warp-standard-label-rois/blob/main/LICENSE). Connectome Workbench and FreeSurfer are distributed under their own licences.
