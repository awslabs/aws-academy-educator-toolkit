# ACO - Demonstrate multi-account setup using CLI

Create an auditor user and gives them view only-rights in another account. You need to have full IAM rights to two accounts to do this demo.

## Resources

- [Tutorial: Delegate Access Across AWS Accounts Using IAM Roles](https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_cross-account-with-roles.html)
- [Switching to an IAM Role (AWS CLI)](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-cli.html)

### Demo Setup

- Have 3 windows open, 2 visible to students
- One visible window has cli setup so it has iam privileges in the target account, so change the prompt:

```bash
TARGET_ACCT=$(aws sts get-caller-identity \
  --query 'Account' \
  --output text)

echo TARGET_ACCT=$TARGET_ACCT

PS1="Target Account ($TARGET_ACCT) $"
```

- The second visible window has iam privileges in the source account, so change the prompt:

```bash
SOURCE_ACCT=$(aws sts get-caller-identity \
  --query 'Account' \
  --output text)

echo SOURCE_ACCT=$SOURCE_ACCT

PS1="Source Account ($SOURCE_ACCT) $"
```

### Check we cleaned up last time

- In case you are running this demo a few times, check that we cleaned up target account

```bash
aws iam list-roles --query 'Roles[*].RoleName' | grep view-from-other-account
```

- Check that we cleaned up source account

```bash
aws iam list-users --query 'Users[*].UserName' | grep auditor

aws iam list-policies --query 'Policies[*].PolicyName' | grep assume-view-role
```

- The third window should also be in the same directory as the others, but is hidden from view (on your laptop screen that is not projected) so that you can edit the password and access keys without the students seeing the details.

## Target Account

- In target account create role that
  - Creates trust relationship to other account
    - [Trust policy](./multi-account-trust-policy.json)
  - Substitute source account numver for SOURCE_ACCT

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
        "Effect": "Allow",
        "Principal": {
            "AWS": "arn:aws:iam::SOURCE_ACCT:root"
        },
        "Action": "sts:AssumeRole",
        "Condition": {}
        }
    ]
}
```

- Specify what the other account can do

```bash
TARGET_ROLE=$(aws iam create-role \
  --role-name view-from-other-account \
  --assume-role-policy-document file://multi-account-trust-policy.json \
  --query 'Role.Arn' \
  --output text)

echo TARGET_ROLE=$TARGET_ROLE

aws iam attach-role-policy \
--role-name view-from-other-account \
--policy-arn arn:aws:iam::aws:policy/job-function/ViewOnlyAccess
```

## Source Account

```bash
aws iam create-user --user-name auditor

aws iam create-login-profile --generate-cli-skeleton > create-login-profile.json

cat create-login-profile.json
```

- Edit fields in `create-login-profile.json`

```bash
aws iam create-login-profile \
  --cli-input-json file://create-login-profile.json

aws iam create-access-key \
  --user-name auditor \
  > access-keys.json
```

- In hidden window edit `~/.aws/credentials` and add profile for auditor with the keys in `access-keys.json`

```config
[auditor]
aws_access_key_id = XXXXXXX
aws_secret_access_key = XXXXXXXX
```

- Create policy giving auditor permissions to assume role in target account (substitute TARGET_ROLE):

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "TARGET_ROLE"
        }
    ]
}
```

- with this command and attach it to the user:

```bash
POLICY=$(aws iam create-policy \
--policy-name assume-view-role \
--query 'Policy.Arn' \
--output text \
--policy-document \
'{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Resource": "TARGET_ROLE"
  }
}')

aws iam attach-user-policy \
  --user-name auditor \
  --policy-arn $POLICY
```

### Create cli profile

- Substitute REGION and TARGET_ROLE
- Add to `~/.aws/config`

```config
[profile auditor]
output = json
region = REGION
source_profile = auditor
role_arn = TARGET_ROLE
```

### Demonstrate switching role in console

- Login as auditor to source account
- Show auditor has no permissions in source account
- Switch roles specifying target account and role _view-from-other-account_

### Demonstrate with CLI

```bash
aws sts get-call-identity

aws sts get-call-identity --profile auditor

aws s3 ls

aws s3 ls --profile auditor
```

## Cleanup Source Account

```bash
POLICY=$(aws iam list-policies \
  --query 'Policies[?PolicyName == `assume-view-role`].Arn' \
  --output text)

aws iam delete-login-profile \
  --user-name auditor

aws iam detach-user-policy \
  --user-name auditor \
  --policy-arn $POLICY

KEY=$(aws iam list-access-keys \
  --user-name auditor \
  --query 'AccessKeyMetadata[*].AccessKeyId' \
  --output text)

aws iam delete-access-key --user-name auditor --access-key-id $KEY

aws iam delete-user --user-name auditor

aws iam delete-policy \
  --policy-arn $POLICY
```

## Cleanup Target Account

```bash
aws iam list-attached-role-policies \
  --role-name view-from-other-account \
  --query 'AttachedPolicies[*].PolicyName' \
  --output text

aws iam detach-role-policy \
  --role-name view-from-other-account \
  --policy-arn arn:aws:iam::aws:policy/job-function/ViewOnlyAccess

aws iam delete-role \
  --role-name view-from-other-account
```

## License Summary

This sample code is made available under the MIT-0 license. See the LICENSE file.