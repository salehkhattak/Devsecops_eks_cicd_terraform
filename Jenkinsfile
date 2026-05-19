pipeline {
    agent any

    environment {
        APP_NAME           = "myflask-app"
        DOCKER_IMAGE       = "salehktk005/myflask-app"
        DOCKER_CREDENTIALS = "dockerHubCreds"
        IMAGE_TAG          = "${BUILD_NUMBER}"
        AWS_REGION         = "us-east-1"
        EKS_CLUSTER_NAME   = "flask-app-cluster"
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
                withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN')]) {
                    sh '''
                        docker run --rm \
                            --network host \
                            -e SONAR_HOST_URL=http://localhost:9000 \
                            -v ${WORKSPACE}:/usr/src \
                            sonarsource/sonar-scanner-cli:latest \
                            -Dsonar.projectKey=flask-devsecops \
                            -Dsonar.sources=/usr/src \
                            -Dsonar.token=${SONAR_TOKEN}
                    '''
                }
            }
        }

        stage("OWASP Dependency Scan") {
            steps {
                sh '''
                    mkdir -p reports
                    docker run --rm \
                        -v ${WORKSPACE}:/src \
                        owasp/dependency-check \
                        --scan /src \
                        --format HTML \
                        --out /src/reports
                '''
            }
        }

        stage("Docker Build") {
            steps {
                sh "docker build -t ${DOCKER_IMAGE}:${IMAGE_TAG} ."
            }
        }

        stage("Trivy Vulnerability Scan") {
            steps {
                sh "trivy image --severity HIGH,CRITICAL --format table ${DOCKER_IMAGE}:${IMAGE_TAG}"
            }
        }

        stage("Docker Push") {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: "${DOCKER_CREDENTIALS}",
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                        echo "${DOCKER_PASS}" | docker login -u "${DOCKER_USER}" --password-stdin
                        docker push ${DOCKER_IMAGE}:${IMAGE_TAG}
                        docker logout
                    '''
                }
            }
        }

        stage("Deploy on K8s") {
            steps {
                sh """
                    aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER_NAME}
                    sed -i "s|image: .*|image: ${DOCKER_IMAGE}:${IMAGE_TAG}|" myk8s/app-deployment.yml
                    kubectl apply -f myk8s/
                    kubectl rollout status deployment/myflask-app -n flask-sql-namespace --timeout=300s
                """
            }
        }
    }

    post {
        success {
            echo "✅ Build #${BUILD_NUMBER} succeeded — ${APP_NAME}:${IMAGE_TAG}"
        }
        failure {
            echo "❌ Build #${BUILD_NUMBER} failed — ${APP_NAME}"
        }
        always {
            cleanWs()
        }
    }
}