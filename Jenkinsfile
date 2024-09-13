pipeline {
    agent any

    environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        TF_IN_AUTOMATION      = '1'
        FUNCTION_VERSION      = '1.0.0'
    }

    stages {
        stage('Terraform Init') {
            steps {
                sh 'terraform init -backend-config="bucket=bimaplan-serverless-code7803" -backend-config="key=terraform.tfstate" -backend-config="region=ap-south-1"'
            }
        }

        stage('Terraform Plan') {
            steps {
                sh 'terraform plan -var="function_version=${FUNCTION_VERSION}" -out=tfplan'
            }
        }

        stage('Terraform Apply') {
            steps {
                sh 'terraform apply -auto-approve tfplan'
            }
        }

        stage('Update Version') {
            steps {
                script {
                    def newVersion = (FUNCTION_VERSION.toFloat() + 0.1).toString()
                    env.FUNCTION_VERSION = newVersion
                }
            }
        }

        stage('Backup Previous Version') {
            steps {
                sh 'aws s3 cp lambda_function.zip s3://bimaplan-serverless-code7803/lambda_function_${FUNCTION_VERSION}.zip'
            }
        }

        stage('Output Function URL') {
            steps {
                sh 'echo "Function URL: $(terraform output -raw function_url)"'
            }
        }
    }
}