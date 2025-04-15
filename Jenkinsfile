pipeline {
    agent any

    environment {
        ACR_NAME        = 'kubernetesacr04082003' // Must match Terraform
        ACR_LOGIN_SERVER = "${ACR_NAME}.azurecr.io"
        IMAGE_NAME      = 'kubernetes04082003'
        RESOURCE_GROUP  = 'rg-aks-acr'
        AKS_CLUSTER     = 'mycluster040820035'
        AZ_SUBSCRIPTION = '0f9d69f5-ad20-4bba-b635-f1f6dc2c1744'
        AZ_TENANT       = '71f242b3-647c-4666-8969-0cff7437c32c'
    }

    stages {
        stage('Terraform Init & Apply') {
            steps {
                dir('terraform') {
                    sh 'terraform init'
                    sh 'terraform apply -auto-approve'
                }
            }
        }

        stage('Azure CLI Login') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'AZURE_CREDENTIALS',
                    usernameVariable: 'ARM_CLIENT_ID',
                    passwordVariable: 'ARM_CLIENT_SECRET'
                )]) {
                    sh '''
                        az login --service-principal \
                            -u $ARM_CLIENT_ID \
                            -p $ARM_CLIENT_SECRET \
                            --tenant $AZ_TENANT
                        az account set --subscription $AZ_SUBSCRIPTION
                    '''
                }
            }
        }

        stage('Login to ACR') {
            steps {
                sh 'az acr login --name $ACR_NAME'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def imageTag = "${ACR_LOGIN_SERVER}/${IMAGE_NAME}:${BUILD_NUMBER}"
                    sh "docker build -t ${imageTag} ."
                }
            }
        }

        stage('Push Image to ACR') {
            steps {
                script {
                    def imageTag = "${ACR_LOGIN_SERVER}/${IMAGE_NAME}:${BUILD_NUMBER}"
                    sh "docker push ${imageTag}"
                }
            }
        }

        stage('Get AKS Credentials') {
            steps {
                sh 'az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER --overwrite-existing'
            }
        }

        stage('Deploy to AKS') {
            steps {
                script {
                    def imageTag = "${ACR_LOGIN_SERVER}/${IMAGE_NAME}:${BUILD_NUMBER}"
                    // Replace the image tag in deployment.yml before applying
                    sh """
                        sed -i 's|image:.*|image: ${imageTag}|' deployment.yml
                        kubectl apply -f deployment.yml
                    """
                }
            }
        }
    }
}
