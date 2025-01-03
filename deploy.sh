#!/bin/bash
set -aeuo pipefail

# Parse command line arguments
if [ ! -f "config/config.yaml" ]; then
    echo "config/config.yaml does not exist, creating it from default-config.yaml"
    cp config/default-config.yaml config/config.yaml
fi

if [ ! -f ".env" ]; then
    echo "Error: .env file missing. Creating it from .env.template"
    cp .env.template .env
fi

aws_region=$(aws configure get region)
echo $aws_region

SKIP_BUILD=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--skip-build]"
            exit 1
            ;;
    esac
done

APP_NAME=litellm
MIDDLEWARE_APP_NAME=middleware
STACK_NAME="LitellmCdkStack"
LOG_BUCKET_STACK_NAME="LogBucketCdkStack"

# Load environment variables from .env file
source .env

if [[ (-z "$LITELLM_VERSION") || ("$LITELLM_VERSION" == "placeholder") ]]; then
    echo "LITELLM_VERSION must be set in .env file"
    exit 1
fi

if [ -z "$CERTIFICATE_ARN" ] || [ -z "$DOMAIN_NAME" ]; then
    echo "Error: CERTIFICATE_ARN and DOMAIN_NAME must be set in .env file"
    exit 1
fi

echo "Certificate Arn: " $CERTIFICATE_ARN
echo "Domain Name: " $DOMAIN_NAME
echo "OKTA_ISSUER: $OKTA_ISSUER"
echo "OKTA_AUDIENCE: $OKTA_AUDIENCE"
echo "LiteLLM Version: " $LITELLM_VERSION
echo "Skipping container build: " $SKIP_BUILD
echo "Build from source: " $BUILD_FROM_SOURCE

echo "OPENAI_API_KEY: $OPENAI_API_KEY"
echo "AZURE_OPENAI_API_KEY: $AZURE_OPENAI_API_KEY"
echo "AZURE_API_KEY: $AZURE_API_KEY"
echo "ANTHROPIC_API_KEY: $ANTHROPIC_API_KEY"
echo "GROQ_API_KEY: $GROQ_API_KEY"
echo "COHERE_API_KEY: $COHERE_API_KEY"
echo "CO_API_KEY: $CO_API_KEY"
echo "HF_TOKEN: $HF_TOKEN"
echo "HUGGINGFACE_API_KEY: $HUGGINGFACE_API_KEY"
echo "DATABRICKS_API_KEY: $DATABRICKS_API_KEY"
echo "GEMINI_API_KEY: $GEMINI_API_KEY"
echo "CODESTRAL_API_KEY: $CODESTRAL_API_KEY"
echo "MISTRAL_API_KEY: $MISTRAL_API_KEY"
echo "AZURE_AI_API_KEY: $AZURE_AI_API_KEY"
echo "NVIDIA_NIM_API_KEY: $NVIDIA_NIM_API_KEY"
echo "XAI_API_KEY: $XAI_API_KEY"
echo "PERPLEXITYAI_API_KEY: $PERPLEXITYAI_API_KEY"
echo "GITHUB_API_KEY: $GITHUB_API_KEY"
echo "DEEPSEEK_API_KEY: $DEEPSEEK_API_KEY"

if [ "$SKIP_BUILD" = false ]; then
    echo "Building and pushing docker image..."
    ./docker-build-and-deploy.sh $APP_NAME $BUILD_FROM_SOURCE
else
    echo "Skipping docker build and deploy step..."
fi

cd middleware
./docker-build-and-deploy.sh $MIDDLEWARE_APP_NAME
cd ..

ARCH=$(uname -m)
case $ARCH in
    x86_64)
        ARCH="x86"
        ;;
    arm64)
        ARCH="arm"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

echo $ARCH

cd litellm-s3-log-bucket-cdk
echo "Installing log bucket dependencies..."
npm install
npm run build
echo "Deploying the log bucket CDK stack..."

cdk deploy "$LOG_BUCKET_STACK_NAME" \
--outputs-file ./outputs.json

if [ $? -eq 0 ]; then
    echo "Log Bucket Deployment successful. Extracting outputs..."
    LOG_BUCKET_NAME=$(jq -r ".\"${LOG_BUCKET_STACK_NAME}\".LogBucketName" ./outputs.json)
    LOG_BUCKET_ARN=$(jq -r ".\"${LOG_BUCKET_STACK_NAME}\".LogBucketArn" ./outputs.json)

    CONFIG_PATH="../config/config.yaml"

    # Check if yq is installed
    if ! command -v yq &> /dev/null; then
        echo "Error: yq is not installed. Please install it first."
        exit 1
    fi

    # Preliminary check to ensure config/config.yaml is valid YAML
    if ! yq e '.' "$CONFIG_PATH" >/dev/null 2>&1; then
        echo "Error: config/config.yaml is not valid YAML."
        exit 1
    fi
    
    # Check if s3_callback_params section exists and is not commented out
    if yq e '.litellm_settings.s3_callback_params' "$CONFIG_PATH" | grep -q "^[^#]"; then
        echo "Found s3_callback_params section. Updating values..."
        
        # Update both values using yq
        yq e ".litellm_settings.s3_callback_params.s3_bucket_name = \"$LOG_BUCKET_NAME\" | 
            .litellm_settings.s3_callback_params.s3_region_name = \"$aws_region\"" -i "$CONFIG_PATH"
        
        echo "Updated config.yaml with bucket name: $LOG_BUCKET_NAME and region: $aws_region"
    else
        echo "s3_callback_params section not found or is commented out in $CONFIG_PATH"
    fi

else
    echo "Log bucket Deployment failed"
fi

cd ..

cd litellm-cdk
echo "Installing dependencies..."
npm install
echo "Deploying the CDK stack..."

cdk deploy "$STACK_NAME" \
--context architecture=$ARCH \
--context liteLLMVersion=$LITELLM_VERSION \
--context ecrLitellmRepository=$APP_NAME \
--context ecrMiddlewareRepository=$MIDDLEWARE_APP_NAME \
--context certificateArn=$CERTIFICATE_ARN \
--context domainName=$DOMAIN_NAME \
--context oktaIssuer=$OKTA_ISSUER \
--context oktaAudience=$OKTA_AUDIENCE \
--context logBucketArn=$LOG_BUCKET_ARN \
--context openaiApiKey=$OPENAI_API_KEY \
--context azureOpenAiApiKey=$AZURE_OPENAI_API_KEY \
--context azureApiKey=$AZURE_API_KEY \
--context anthropicApiKey=$ANTHROPIC_API_KEY \
--context groqApiKey=$GROQ_API_KEY \
--context cohereApiKey=$COHERE_API_KEY \
--context coApiKey=$CO_API_KEY \
--context hfToken=$HF_TOKEN \
--context huggingfaceApiKey=$HUGGINGFACE_API_KEY \
--context databricksApiKey=$DATABRICKS_API_KEY \
--context geminiApiKey=$GEMINI_API_KEY \
--context codestralApiKey=$CODESTRAL_API_KEY \
--context mistralApiKey=$MISTRAL_API_KEY \
--context azureAiApiKey=$AZURE_AI_API_KEY \
--context nvidiaNimApiKey=$NVIDIA_NIM_API_KEY \
--context xaiApiKey=$XAI_API_KEY \
--context perplexityaiApiKey=$PERPLEXITYAI_API_KEY \
--context githubApiKey=$GITHUB_API_KEY \
--context deepseekApiKey=$DEEPSEEK_API_KEY \
--outputs-file ./outputs.json

if [ $? -eq 0 ]; then
    echo "Deployment successful. Extracting outputs..."
    LITELLM_ECS_CLUSTER=$(jq -r ".\"${STACK_NAME}\".LitellmEcsCluster" ./outputs.json)
    LITELLM_ECS_TASK=$(jq -r ".\"${STACK_NAME}\".LitellmEcsTask" ./outputs.json)
    SERVICE_URL=$(jq -r ".\"${STACK_NAME}\".ServiceURL" ./outputs.json)
    
    echo "ServiceURL=$SERVICE_URL" > resources.txt

    aws ecs update-service \
        --cluster $LITELLM_ECS_CLUSTER \
        --service $LITELLM_ECS_TASK \
        --force-new-deployment \
        --desired-count 1 \
        --no-cli-pager
else
    echo "Deployment failed"
fi