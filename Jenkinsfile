@Library("Shared") _

pipeline {

    agent any

    environment {
        APP_NAME = "myflask-app"
        DOCKER_IMAGE = "salehktk005/myflask-app"
        DOCKER_CREDENTIALS = "dockerHubCreds"
        SONAR_SERVER = "SonarQube"
        IMAGE_TAG = "${BUILD_NUMBER}"
    }

    stages {

        stage("Code Clone") {
            steps {
                script {
                    clone("https://github.com/salehktk005/flask-sql-app.git", "main")
                }
            }
        }

        stage("Docker Check") {
            steps {
                sh "docker --version"
            }
        }

        stage("OWASP Dependency Check") {
            steps {
                script {
                       call() 
                }
            }
        }

        stage("SonarQube Analysis") {
            steps {
                script {
                    sonar_scan()
                }
            }
        }

        stage("OWASP Dependency Check") {
            steps {
                script {
                    owasp_scan()
                }
            }
        }

        stage("Trivy FS Scan") {
            steps {
                script {
                    trivy_fs()
                }
            }
        }

        stage("Build Docker Image") {
            steps {
                sh "docker build -t ${DOCKER_IMAGE}:${IMAGE_TAG} ."
            }
        }

        stage("Trivy Image Scan") {
            steps {
                sh "trivy image ${DOCKER_IMAGE}:${IMAGE_TAG}"
            }
        }

        stage("Push to DockerHub") {
            steps {
                script {
                    docker_push("${DOCKER_CREDENTIALS}", "${DOCKER_IMAGE}:${IMAGE_TAG}")
                }
            }
        }

        stage("Deploy to Kubernetes") {
            steps {
                script {
                    k8s_deploy("${DOCKER_IMAGE}:${IMAGE_TAG}")
                }
            }
        }
    }

    post {
        success {
            emailext(
                to: 'salehktk005@gmail.com',
                subject: "SUCCESS: Build ${BUILD_NUMBER}",
                body: "Deployment SUCCESSFUL for ${APP_NAME}:${BUILD_NUMBER}"
            )
        }

        failure {
            emailext(
                to: 'salehktk005@gmail.com',
                subject: "FAILED: Build ${BUILD_NUMBER}",
                body: "Pipeline FAILED for ${APP_NAME}:${BUILD_NUMBER}"
            )
        }
    }
}