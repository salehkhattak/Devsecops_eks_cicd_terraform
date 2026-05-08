def call() {
    withSonarQubeEnv('SonarQube') {
        sh """
        sonar-scanner \\
        -Dsonar.projectKey=three-tier-app \\
        -Dsonar.sources=.
        """
    }
}