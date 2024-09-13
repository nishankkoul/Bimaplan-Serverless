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
        stage('Check Current Version') {
            steps {
                script {
                    def result = sh(script: 'aws s3 ls s3://${S3_BUCKET}/${LAMBDA_CODE_KEY}_${FUNCTION_VERSION}.zip', returnStatus: true)
                    if (result == 0) {
                        echo "Object for version ${FUNCTION_VERSION} already exists."
                    } else {
                        echo "Object for version ${FUNCTION_VERSION} does not exist."
                        // Initialize version to 1.0 if this is the first run
                        sh 'echo "1.0" > version.txt'
                        sh "aws s3 cp version.txt s3://${S3_BUCKET}/version.txt"
                    }
                }
            }
        }

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
                    def currentVersion = env.FUNCTION_VERSION
                    // Check if the object already exists
                    def result = sh(script: 'aws s3 ls s3://${S3_BUCKET}/${LAMBDA_CODE_KEY}_${currentVersion}.zip', returnStatus: true)
                    if (result == 0) {
                        echo "Updating existing object for version ${currentVersion}"
                    } else {
                        echo "Uploading new object for version ${currentVersion}"
                    }
                    // Backup current version
                    sh "aws s3 cp lambda_function.zip s3://${S3_BUCKET}/${LAMBDA_CODE_KEY}_${currentVersion}.zip"
                }
            }
        }

        stage('Update Version') {
            steps {
                script {
                    // Increment the version by 0.1
                    def newVersion = (FUNCTION_VERSION.toFloat() + 0.1).toString()
                    // Set the new version in the environment
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
