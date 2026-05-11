@Library("Shared") _

pipeline {

    agent any

    environment {
        APP_NAME           = "myflask-app"
        DOCKER_IMAGE       = "salehktk005/myflask-app"
        DOCKER_CREDENTIALS = "dockerHubCreds"
        IMAGE_TAG          = "${BUILD_NUMBER}"
    }

    stages {

        stage("Code Clone") {
            steps {
                git branch: 'main',
                    url: 'https://github.com/salehkhattak/Devsecops_eks_cicd_terraform.git'
            }
        }

        stage("SonarQube Analysis") {
            steps {
                script { sonarScan() }
            }
        }

        stage("OWASP Dependency Scan") {
            steps {
                script { owaspScan() }
            }
        }


        stage("Docker Build") {
            steps {
                sh "docker build -t ${DOCKER_IMAGE}:${IMAGE_TAG} ."
            }
        }

        
        stage("Docker Push") {
            steps {
                script { dockerPush("${DOCKER_CREDENTIALS}", "${DOCKER_IMAGE}:${IMAGE_TAG}") }
            }
        }

        stage("Deploy on k8s") {
            steps {
                script { k8sDeploy("${DOCKER_IMAGE}:${IMAGE_TAG}") }
            }
        }
    }

    post {
        success {
          
                sh "✅ Build #${BUILD_NUMBER} succeeded — ${APP_NAME}:${IMAGE_TAG}"
            
        }

        failure {
           
            sh "❌ Build #${BUILD_NUMBER} failed — ${APP_NAME}"
            
        }

        always {
            cleanWs()
        }
    }
}