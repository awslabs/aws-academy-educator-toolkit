# AWS CLI Introduction

This demo uses a jupyter notebook running with [bash_kernel](https://pypi.org/project/bash_kernel/) to introduce the AWS CLI.

## Launching JupyterLab

The simplest way to launch the notebook is navigate to _Amazon Sagemaker_ in the AWS Console and under Notebook select _Notebook instances_. Then select _Create notebook Instance_.

TODO: Describe fields

TODO: Clone this repo

## Install bash_kernel

Amazon Sagemaker preinstalls a number of kernels commonly used for machine learning. For this notebook we need a different kernel for running BASH commands known as [bash_kernel](https://pypi.org/project/bash_kernel/).

In the launcher select _Terminal_ and run these commands:

```bash
pip install bash_kernel
python -m bash_kernel.install
```

Navigate back to the launcher and wait for _Bash_ to appear as one of the kernels, which should occur in less than 1 minute.

## Open notebook and select kernel

Navigate to the notebook in the file browser and double click to open the notebook. When prompted for the kernel select _Bash_.
