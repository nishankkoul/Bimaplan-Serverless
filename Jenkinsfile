pipeline {
    agent any

    environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        TF_IN_AUTOMATION      = '1'
        VERSION_FILE          = 'version.txt'  // File to track the current version
        CURRENT_VERSION       = ''  // Initialize as empty, will be set dynamically
    }

    stages {
        stage('Initialize Version') {
            steps {
                script {
                    try {
                        // Attempt to read the current version from the version file
                        def versionOutput = sh(script: 'aws s3 cp s3://bimaplan-serverless-code7803/${VERSION_FILE} -', returnStdout: true).trim()
                        if (versionOutput) {
                            env.CURRENT_VERSION = versionOutput
                        } else {
                            env.CURRENT_VERSION = '1.0'
                        }
                    } catch (Exception e) {
                        // If the file is not found, initialize with a default version
                        env.CURRENT_VERSION = '1.0'
                    }
                }
            }
        }

        stage('Terraform Init') {
            steps {
                sh '''
                terraform init -upgrade \\
                  -backend-config=bucket=bimaplan-serverless-code7803 \\
                  -backend-config=key=terraform.tfstate \\
                  -backend-config=region=ap-south-1
                '''
            }
        }

        stage('Terraform Plan') {
            steps {
                sh 'terraform plan -var="function_version=${CURRENT_VERSION}" -out=tfplan'
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
                    // Increment the version by 0.1
                    def newVersion = (CURRENT_VERSION.toFloat() + 0.1).toString()
                    def formattedVersion = String.format("%.1f", newVersion.toFloat())
                    
                    // Update the version file with the new version
                    writeFile file: VERSION_FILE, text: formattedVersion
                    
                    // Upload the Lambda function zip with the new version name
                    sh "aws s3 cp lambda_function.zip s3://bimaplan-serverless-code7803/lambda_function.zip"
                    
                    // Upload the new version file to S3
                    sh "aws s3 cp ${VERSION_FILE} s3://bimaplan-serverless-code7803/${VERSION_FILE}"
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
