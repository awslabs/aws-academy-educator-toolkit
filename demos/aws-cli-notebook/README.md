# AWS CLI Introduction

This demo uses a jupyter notebook running with [bash_kernel](https://pypi.org/project/bash_kernel/) to introduce the AWS CLI.

## Launching JupyterLab

The simplest way to launch the notebook is from _Amazon Sagemaker_.

- Navigate to _Amazon Sagemaker_ in the AWS Console and under Notebook select _Notebook instances_.
- Select _Create notebook Instance_.
- Give the notebook instance a name
- Select either ml.t2_medium or ml.t3_medium for the instance type. This is in the free tier for the first 2 months after you start using Sagemaker.
- Expand _Git repositories_
- Select _Clone a public Git reposnitoty to this notebook instance only_
- Enter `https://github.com/awslabs/aws-academy-educator-toolkit.git` as the repository
- Press _Create notebook Instance_

Once it is ready select _Open JupyterLab_

## Install bash_kernel

Amazon Sagemaker preinstalls a number of kernels commonly used for machine learning. For this notebook we need a different kernel for running BASH commands known as [bash_kernel](https://pypi.org/project/bash_kernel/).

In the launcher select _Terminal_ and run these commands:

```bash
pip install bash_kernel
python -m bash_kernel.install
```

Navigate back to the launcher and wait for _Bash_ to appear as one of the kernels, which should occur in less than 1 minute.

## Open notebook and select kernel

Navigate to the notebook in the file browser and double click to open the notebook. When prompted for the kernel select _Bash_. You are now ready to work through the notebook.
