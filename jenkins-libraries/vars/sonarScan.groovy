def sonar_scan() {
    withSonarQubeEnv('SonarQube') {
        sh """
        sonar-scanner \
        -Dsonar.projectKey=three-tier-app \
        -Dsonar.sources=. \
        -Dsonar.host.url=http://sonarqube:9000 \
        -Dsonar.login=admin
        """
    }
}