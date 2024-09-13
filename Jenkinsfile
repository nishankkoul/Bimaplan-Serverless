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
                sh '''
                terraform init -upgrade -backend-config=bucket=${S3_BUCKET} -backend-config=key=terraform.tfstate -backend-config=region=ap-south-1
                '''
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

        stage('Backup and Update Lambda Code') {
            steps {
                script {
                    // Upload new code to S3 with the same name
                    def result = sh(script: "aws s3 ls s3://${S3_BUCKET}/${LAMBDA_CODE_KEY}.zip", returnStatus: true)
                    
                    if (result == 0) {
                        echo "Updating existing object"
                    } else {
                        echo "Uploading new object"
                    }

                    sh "aws s3 cp lambda_function.zip s3://${S3_BUCKET}/${LAMBDA_CODE_KEY}.zip"
                    
                    // Increment the version number internally
                    def newVersion = (env.FUNCTION_VERSION.toFloat() + 0.1).toString()
                    env.FUNCTION_VERSION = newVersion
                }
            }
        }

        stage('Output Function URL') {
            steps {
                sh 'echo "Function URL: $(terraform output -raw function_url)"'
            }
        }
    }
}
