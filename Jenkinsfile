pipeline {
    agent any

    environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        TF_IN_AUTOMATION      = '1'
        FUNCTION_VERSION_FILE = 'version.txt'
        S3_BUCKET             = credentials('S3_BUCKET')
        LAMBDA_CODE_KEY       = 'lambda_function_code'
        AWS_REGION            = 'ap-south-1'
    }

    stages {
        stage('Retrieve Version') {
            steps {
                script {
                    // Retrieve the version from S3
                    def result = sh(script: "aws s3 cp s3://${S3_BUCKET}/${FUNCTION_VERSION_FILE} version.txt --region ${AWS_REGION}", returnStatus: true)
                    
                    if (result == 0) {
                        // Read the version from file
                        env.FUNCTION_VERSION = readFile('version.txt').trim()
                    } else {
                        // Set default version if file does not exist
                        env.FUNCTION_VERSION = '1.0'
                    }
                }
            }
        }

        stage('Terraform Init') {
            steps {
                script {
                    sh '''
                    terraform init -upgrade \
                        -reconfigure \
                        -backend-config="bucket=${S3_BUCKET}" \
                        -backend-config="key=terraform.tfstate" \
                        -backend-config="region=${AWS_REGION}" \
                        -force-copy
                    '''
                }
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
                    def result = sh(script: "aws s3 ls s3://${S3_BUCKET}/${LAMBDA_CODE_KEY}.zip", returnStatus: true)
                    
                    if (result == 0) {
                        echo "Updating existing object for version ${currentVersion}"
                        def newVersion = (currentVersion.toFloat() + 0.1).toString()
                        sh "aws s3 cp lambda_function.zip s3://${S3_BUCKET}/${LAMBDA_CODE_KEY}.zip"
                        writeFile(file: 'version.txt', text: newVersion)
                        sh "aws s3 cp version.txt s3://${S3_BUCKET}/${FUNCTION_VERSION_FILE} --region ${AWS_REGION}"
                    } else {
                        echo "Uploading new object for version ${currentVersion}"
                        sh "aws s3 cp lambda_function.zip s3://${S3_BUCKET}/${LAMBDA_CODE_KEY}.zip"
                        def newVersion = (currentVersion.toFloat() + 0.1).toString()
                        writeFile(file: 'version.txt', text: newVersion)
                        sh "aws s3 cp version.txt s3://${S3_BUCKET}/${FUNCTION_VERSION_FILE} --region ${AWS_REGION}"
                    }
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
