@Library("Shared") _

pipeline {

    agent { label "dev" }

    environment {
        IMAGE_NAME = "three-tier-flask-app"
        DOCKER_CREDENTIALS = "dockerHubCreds"
        SONAR_SERVER = "SonarQube"
    }

    stages {

        stage("Code Clone") {
            steps {
                script {
                    clone("https://github.com/salehktk005/flask-sql-app.git", "main")
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

        stage("Trivy File System Scan") {
            steps {
                script {
                    trivy_fs()
                    trivy_image()
                }
            }
        }

        stage("Build Docker Image") {
            steps {
                sh "docker build -t ${IMAGE_NAME} ."
            }
        }

        stage("Trivy Image Scan") {
            steps {
                script {
                    trivy_image("${IMAGE_NAME}")
                }
            }
        }

        stage("Test") {
            steps {
                echo "Developer / Tester tests likh ke dega..."
            }
        }

        stage("Push to Docker Hub") {
            steps {
                script {
                    docker_push("${DOCKER_CREDENTIALS}", "${IMAGE_NAME}")
                }
            }
        }

        stage("Deploy") {
            steps {
                sh "docker compose up -d --build flask-app"
            }
        }
    }

    post {

        success {
            script {
                emailext(
                    from: 'salehktk9@gmail.com',
                    to: 'salehktk005@gmail.com',
                    subject: "SUCCESS: CI/CD Pipeline",
                    body: "Build SUCCESS for ${env.JOB_NAME} #${env.BUILD_NUMBER}"
                )
            }
        }

        failure {
            script {
                emailext(
                    from: 'salehktk9@gmail.com',
                    to: 'salehktk005@gmail.com',
                    subject: "FAILED: CI/CD Pipeline",
                    body: "Build FAILED for ${env.JOB_NAME} #${env.BUILD_NUMBER}"
                )
            }
        }
    }
}