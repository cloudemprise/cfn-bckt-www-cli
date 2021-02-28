#!/bin/bash -e
# debug options include -v -x
# cfn-www-cicd-cli.sh 
# S3 Static Website with Cloudfront.
# Prerequists: s3 buckets, domain name with hosted zone.


#!! COMMENT Construct Begins Here:
: <<'END'
#!! COMMENT BEGIN

#!! COMMENT END
END
#!! COMMENT Construct Ends Here:


#-----------------------------
# Record Script Start Execution Time
TIME_START_PROJ=$(date +%s)
TIME_STAMP_PROJ=$(date "+%Y-%m-%d %Hh%Mm%Ss")
echo "The Time Stamp ................................: $TIME_STAMP_PROJ"
#.............................


#-----------------------------
# Request Named Profile
AWS_PROFILE="default"
while true
do
  # -e : stdin from terminal
  # -r : backslash not an escape character
  # -p : prompt on stderr
  # -i : use default buffer val
  read -er -i "$AWS_PROFILE" -p "Enter Project AWS CLI Named Profile ...........: " USER_INPUT
  if aws configure list-profiles 2>/dev/null | fgrep -qw "$USER_INPUT"
  then
    echo "Project AWS CLI Named Profile is valid ........: $USER_INPUT"
    AWS_PROFILE=$USER_INPUT
    break
  else
    echo "Error! Project AWS CLI Named Profile invalid ..: $USER_INPUT"
  fi
done
#.............................


#-----------------------------
# Request Region
AWS_REGION=$(aws configure get region --profile "$AWS_PROFILE")
while true
do
  # -e : stdin from terminal
  # -r : backslash not an escape character
  # -p : prompt on stderr
  # -i : use default buffer val
  read -er -i "$AWS_REGION" -p "Enter Project AWS CLI Region ..................: " USER_INPUT
  if aws ec2 describe-regions --profile "$AWS_PROFILE" --query 'Regions[].RegionName' --output text 2>/dev/null | fgrep -qw "$USER_INPUT"
  then
    echo "Project AWS CLI Region is valid ...............: $USER_INPUT"
    AWS_REGION=$USER_INPUT
    break
  else
    echo "Error! Project AWS CLI Region is invalid ......: $USER_INPUT"
  fi
done
#.............................


#-----------------------------
# Request Project Name
PROJECT_NAME="cfn-www-cicd-cli"
while true
do
  # -e : stdin from terminal
  # -r : backslash not an escape character
  # -p : prompt on stderr
  # -i : use default buffer val
  read -er -i "$PROJECT_NAME" -p "Enter the Name of this Project ................: " USER_INPUT
  if [[ "${USER_INPUT:=$PROJECT_NAME}" =~ (^[a-z0-9]([a-z0-9-]*(\.[a-z0-9])?)*$) ]]
  then
    echo "Project Name is valid .........................: $USER_INPUT"
    PROJECT_NAME=$USER_INPUT
    # Doc Store for this project
    PROJECT_BUCKET="proj-${PROJECT_NAME}"
    break
  else
    echo "Error! Project Name must be S3 Compatible .....: $USER_INPUT"
  fi
done
#.............................


#-----------------------------
# Request Email Address
USER_EMAIL="dh.info@posteo.net"
while true
do
  # -e : stdin from terminal
  # -r : backslash not an escape character
  # -p : prompt on stderr
  # -i : use default buffer val
  read -er -i "$USER_EMAIL" -p "Enter Email Address for SNS Notification ......: " USER_INPUT
  if [[ "${USER_INPUT:=$USER_EMAIL}" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$ ]]
  then
    echo "Email address is valid ........................: $USER_INPUT"
    USER_EMAIL=$USER_INPUT
    break
  else
    echo "Error! Entered Email address is invalid .......: $USER_INPUT"
  fi
done
#.............................


#-----------------------------
# Request Domain Name
AWS_DOMAIN_NAME="cloudemprise.org"
while true
do
  # -e : stdin from terminal
  # -r : backslash not an escape character
  # -p : prompt on stderr
  # -i : use default buffer val
  read -er -i "$AWS_DOMAIN_NAME" -p "Enter Domain Name Static Website ..............: " USER_INPUT
  if [[ "${USER_INPUT:=$AWS_DOMAIN_NAME}" =~ (^[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,6}$) ]]
  then
    echo "Domain Name Static Website is valid ...........: $USER_INPUT"
    AWS_DOMAIN_NAME=$USER_INPUT
    break
  else
    echo "Error! Domain Name must be S3 Compatible ......: $USER_INPUT"
  fi
done
#.............................


#-----------------------------
# Validate CodeCommit Website Artifact Repo
AWS_WWW_REPO_NAME="www-cloudemprise-html"
AWS_WWW_REPO_ID=""
while true
do
  # -e : stdin from terminal
  # -r : backslash not an escape character
  # -p : prompt on stderr
  # -i : use default buffer val
  read -er -i "$AWS_WWW_REPO_NAME" -p "Enter Name CodeCommit Repo Website Artifacts ..: " USER_INPUT
  if aws codecommit list-repositories --profile "$AWS_PROFILE" --region "$AWS_REGION" --query 'repositories[].repositoryName' --output text 2>/dev/null | fgrep -qw "$USER_INPUT"
  then
    echo "CodeCommit Repository Name is valid ...........: $USER_INPUT"
    AWS_WWW_REPO_NAME=$USER_INPUT
    break
  else
    echo "Error! CodeCommit Repo Name is NOT valid ......: $USER_INPUT"
  fi
done
#.............................


#-----------------------------
# Get Route 53 Domain hosted zone ID
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name "$AWS_DOMAIN_NAME" \
    --profile "$AWS_PROFILE" --region "$AWS_REGION" \
    --query "HostedZones[].Id" --output text | awk -F "/" '{print $3}')
[[ -z "$HOSTED_ZONE_ID" ]] \
    && { echo "Invalid Hosted Zone!"; exit 1; } \
    || { echo "Route53 Hosted Zone ID ........................: $HOSTED_ZONE_ID"; }
#.............................


#-----------------------------
# Variable Creation
#-----------------------------
# Name given to Cloudformation Stack
STACK_NAME="cfnstack-$PROJECT_NAME"
echo "The Stack Name ................................: $STACK_NAME"
# Get Account(ROOT) ID
AWS_ACC_ID=$(aws sts get-caller-identity --query Account --output text --profile "$AWS_PROFILE" --region "$AWS_REGION")
echo "The Root Account ID ...........................: $AWS_ACC_ID"
# Console Admin profile userid
#AWS_USER_ADMIN="user.admin.console"
AWS_USER_ADMIN="usr.console.admin"
AWS_USERID_ADMIN=$(aws iam get-user --user-name "$AWS_USER_ADMIN" --query User.UserId --output text --profile "$AWS_PROFILE" --region "$AWS_REGION")
echo "The Console Admin userid ......................: $AWS_USERID_ADMIN"
# CLI profile userid
AWS_USERID_CLI=$(aws sts get-caller-identity --query UserId --output text --profile "$AWS_PROFILE" --region "$AWS_REGION")
echo "The Script Caller userid ......................: $AWS_USERID_CLI"
#.............................


#----------------------------------------------
# Create S3 Bucket Policies from local templates
find -L ./policies/s3-buckets/template-proj* -type f -print0 |
  while IFS= read -r -d '' TEMPLATE
  do
    if [[ ! -s "$TEMPLATE" ]]; then
      echo "Invalid Template Stack Policy .................: $TEMPLATE"
      exit 1
    else
      # Copy/Rename template via parameter expansion
      cp "$TEMPLATE" "${TEMPLATE//template/$PROJECT_NAME}"
      # Replace appropriate variables
      sed -i "s/ProjectBucket/$PROJECT_BUCKET/" "$_"
      sed -i "s/RootAccount/$AWS_ACC_ID/" "$_"
      sed -i "s/ConsoleAdmin/$AWS_USERID_ADMIN/" "$_"
      sed -i "s/ScriptCallerUserId/$AWS_USERID_CLI/" "$_"
      echo "Creating S3 Bucket Policy .....................: $_"
    fi
  done
#.............................


#-----------------------------
# Create S3 Project Bucket with Encryption & Policy
if (aws s3 mb "s3://$PROJECT_BUCKET" --profile "$AWS_PROFILE" --region "$AWS_REGION" > /dev/null)
then 
  aws s3api put-bucket-encryption --bucket "$PROJECT_BUCKET"  \
      --server-side-encryption-configuration                \
      '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}' \
      --profile "$AWS_PROFILE" --region "$AWS_REGION"
      #.............................
  aws s3api put-bucket-policy --bucket "$PROJECT_BUCKET"  \
      --profile "$AWS_PROFILE" --region "$AWS_REGION"   \
      --policy "file://policies/s3-buckets/${PROJECT_NAME}-proj-s3-policy.json" \
      #.............................
  echo "S3 Project Bucket Created .....................: s3://$PROJECT_BUCKET"
else
  echo "Failed to Create S3 Project Bucket !!!!!!!!!!!!: s3://$PROJECT_BUCKET"
  exit 1
fi
#.............................


#----------------------------------------------
# Upload all created policy docs to S3
find ./policies -type f -name "${PROJECT_NAME}*.json" ! -path "*/scratch/*" -print0 |
  while IFS= read -r -d '' FILE
  do
    if [[ ! -s "$FILE" ]]; then
      echo "Error! Invalid Template Policy Document .......: $FILE"
      exit 1
    elif (aws s3 mv "$FILE" "s3://$PROJECT_BUCKET${FILE#.}" --profile "$AWS_PROFILE" --region "$AWS_REGION" > /dev/null); then
      echo "Uploading Policy Document to S3 Location ......: s3://$PROJECT_BUCKET${FILE#.}"
    else continue
    fi
  done
#.............................

#----------------------------------------------
# Upload Cloudformation Templates to S3
find -L ./cfn-templates -type f -name "*.yaml" ! -path "*/scratch/*" -print0 |
  while IFS= read -r -d '' FILE
  do
    if [[ ! -s "$FILE" ]]; then
      echo "Invalid Cloudformation Template Document ......: $FILE"
      exit 1
    elif (aws s3 cp "$FILE" "s3://$PROJECT_BUCKET${FILE#.}" --profile "$AWS_PROFILE" --region "$AWS_REGION" > /dev/null); then
      echo "Uploading Cloudformation Template to S3 .......: s3://$PROJECT_BUCKET${FILE#.}"
    else continue
    fi
  done
#.............................


#----------------------------------------------
# Upload html files to S3
find -L ./www -type f -name "*.html" ! -path "*/scratch/*" -print0 |
  while IFS= read -r -d '' FILE
  do
    if [[ ! -s "$FILE" ]]; then
      echo "Invalid HTML Template Document ................: $FILE"
      exit 1
    elif (aws s3 cp "$FILE" "s3://$PROJECT_BUCKET${FILE#.}" --profile "$AWS_PROFILE" --region "$AWS_REGION" > /dev/null); then
      echo "Uploading HTML Templates to Project Bucket ....: s3://$PROJECT_BUCKET${FILE#.}"
    else continue
    fi
  done
#.............................


#-----------------------------
# Get ARN Domain Certificate for TLS CDN
QUERY_STR="CertificateSummaryList[?DomainName == '${AWS_DOMAIN_NAME}'].CertificateArn"
# --- Initialize
AWS_DOMAIN_CERT_ARN=""
AWS_DOMAIN_CERT_ARN=$(aws acm list-certificates --region us-east-1 --certificate-statuses ISSUED \
    --profile "$AWS_PROFILE" --query "$QUERY_STR" --output text)
[[ -z "$AWS_DOMAIN_CERT_ARN" ]] && { echo "Invalid Domain Certificate ARN!"; exit 1; } \
    || { echo "The Domain Certificate ARN ....................: $AWS_DOMAIN_CERT_ARN"; }
#.............................


#-----------------------------
#-----------------------------
# Stage1 Stack Creation Code Block
BUILD_COUNTER="stage1"
TEMPLATE_URL="https://${PROJECT_BUCKET}.s3.${AWS_REGION}.amazonaws.com/cfn-templates/cfn-www-cicd-cli.yaml"
echo "Cloudformation Stack Creation Initiated .......: $TEMPLATE_URL"

TIME_START_STACK=$(date +%s)
#-----------------------------
STACK_ID=$(aws cloudformation create-stack --stack-name "$STACK_NAME" --parameters          \
                ParameterKey=ProjectName,ParameterValue="$PROJECT_NAME"                     \
                ParameterKey=DomainBaseURL,ParameterValue="$AWS_DOMAIN_NAME"                \
                ParameterKey=DomainHostedZoneId,ParameterValue="$HOSTED_ZONE_ID"            \
                ParameterKey=DomainCertARN,ParameterValue="$AWS_DOMAIN_CERT_ARN"            \
                ParameterKey=CodeCommitRepoName,ParameterValue="$AWS_WWW_REPO_NAME"         \
                ParameterKey=EmailAddrSNS,ParameterValue="$USER_EMAIL"                      \
                --tags Key=Name,Value="$PROJECT_NAME" --template-url "$TEMPLATE_URL"        \
                --profile "$AWS_PROFILE" --region "$AWS_REGION"                             \
                --on-failure DO_NOTHING --capabilities CAPABILITY_NAMED_IAM --output text)
#-----------------------------
if [[ $? -eq 0 ]]; then
  # Wait for stack creation to complete
  echo "Cloudformation Stack Creation Process Wait.....: $STACK_ID"
  CREATE_STACK_STATUS=$(aws cloudformation describe-stacks --stack-name "$STACK_ID" --query 'Stacks[0].StackStatus' --output text --profile "$AWS_PROFILE" --region "$AWS_REGION")
  while [[ $CREATE_STACK_STATUS == "REVIEW_IN_PROGRESS" ]] || [[ $CREATE_STACK_STATUS == "CREATE_IN_PROGRESS" ]]
  do
      # Wait 1 seconds and then check stack status again
      sleep 1
      printf '.'
      CREATE_STACK_STATUS=$(aws cloudformation describe-stacks --stack-name "$STACK_ID" --query 'Stacks[0].StackStatus' --output text --profile "$AWS_PROFILE" --region "$AWS_REGION")
  done
  printf '\n'
fi
#-----------------------------
# Validate stack creation has not failed
if (aws cloudformation wait stack-create-complete --stack-name "$STACK_ID" --profile "$AWS_PROFILE" --region "$AWS_REGION")
then 
  echo "Cloudformation Stack Create Process Complete ..: $BUILD_COUNTER"
else 
  echo "Error: Stack Create Failed!"
  printf 'Stack ID: \n%s\n' "$STACK_ID"
  exit 1
fi
#-----------------------------
# Calculate Stack Creation Execution Time
TIME_END_STACK=$(date +%s)
TIME_DIFF_STACK=$((TIME_END_STACK - TIME_START_STACK))
echo "$BUILD_COUNTER Finished Execution Time ................: \
$(( TIME_DIFF_STACK / 3600 ))h $(( (TIME_DIFF_STACK / 60) % 60 ))m $(( TIME_DIFF_STACK % 60 ))s"
#.............................
#.............................


#-----------------------------
# Calculate Script Total Execution Time
TIME_END_PROJ=$(date +%s)
TIME_DIFF=$((TIME_END_PROJ - TIME_START_PROJ))
echo "Total Finished Execution Time .................: \
$(( TIME_DIFF / 3600 ))h $(( (TIME_DIFF / 60) % 60 ))m $(( TIME_DIFF % 60 ))s"
#.............................
