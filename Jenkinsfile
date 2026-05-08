@Library("Shared") _

pipeline {

    agent any

    environment {
        APP_NAME = "myflask-app"
        DOCKER_IMAGE = "salehktk005/myflask-app"
        DOCKER_CREDENTIALS = "dockerHubCreds"
        IMAGE_TAG = "${BUILD_NUMBER}"
    }

        stages {

        stage("Code Clone") {
            steps {
                git branch: 'main',
                    url: 'https://github.com/salehkhattak/Devsecops_eks_cicd_terraform.git'
            }
        }

        stage("Docker Check") {
            steps {
                sh "docker --version"
            }
        }
        stage("Shared Library Test") {
            steps {
                script {
                    call()
                }
            }
        }

        stage("OWASP Dependency Check") {
            steps {
                script {
                    owaspScan()
                }
            }
        }

        stage("SonarQube Analysis") {
            steps {
                script {
                    sonarScan()
                }
            }
        }

        stage("Trivy FS Scan") {
            steps {
                script {
                    trivyScan()
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
            echo "SUCCESS"
        }

        failure {
            echo "FAILED"
        }
    }
}
    // post {
    //     success {
    //         emailext(
    //             to: 'salehktk005@gmail.com',
    //             subject: "SUCCESS: Build ${BUILD_NUMBER}",
    //             body: "Deployment SUCCESSFUL for ${APP_NAME}:${BUILD_NUMBER}"
    //         )
    //     }

    //     failure {
    //         emailext(
    //             to: 'salehktk005@gmail.com',
    //             subject: "FAILED: Build ${BUILD_NUMBER}",
    //             body: "Pipeline FAILED for ${APP_NAME}:${BUILD_NUMBER}"
    //         )
    //     }
    // }
