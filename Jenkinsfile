pipeline {
    agent any

    environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        TF_IN_AUTOMATION      = '1'
        FUNCTION_VERSION      = '1.0'  // Initial version
        S3_BUCKET             = 'bimaplan-serverless-code7803'
        LAMBDA_CODE_KEY       = 'lambda_function_code'
    }

    stages {
       stage('Terraform Init') {
    steps {
        script {
            sh '''
            terraform init -upgrade \
                -backend-config="bucket=${S3_BUCKET}" \
                -backend-config="key=terraform.tfstate" \
                -backend-config="region=${AWS_REGION}"
            '''
        }
    }
}

        stage('Terraform Plan') {
            steps {
                script {
                    sh 'terraform plan -var="function_version=${FUNCTION_VERSION}" -out=tfplan'
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                script {
                    sh 'terraform apply -auto-approve tfplan'
                }
            }
        }

        stage('Backup and Update Lambda Code') {
            steps {
                script {
                    // Upload or update the Lambda function code
                    sh "aws s3 cp lambda_function.zip s3://${S3_BUCKET}/${LAMBDA_CODE_KEY}.zip"
                }
            }
        }

        stage('Output Function URL') {
            steps {
                script {
                    sh 'echo "Function URL: $(terraform output -raw function_url)"'
                }
            }
        }
    }
}
