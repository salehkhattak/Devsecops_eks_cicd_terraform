def sonarScan() {
    withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN')]) {
        sh '''
            docker run --rm \
                --network devsecops-eks-proj_three-tier \
                -e SONAR_HOST_URL=http://sonarqube:9000 \
                -e SONAR_LOGIN=${SONAR_TOKEN} \
                    -v ${WORKSPACE}:/usr/src \
                    sonarsource/sonar-scanner-cli:latest \
                    -Dsonar.projectKey=flask-devsecops \
                    -Dsonar.sources=/usr/src
            '''
        }
}
