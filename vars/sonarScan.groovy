def call() {
    echo "Running SonarQube analysis..."
    withSonarQubeEnv('SonarQube') {
        sh """
            sonar-scanner \
                -Dsonar.projectKey=three-tier-flask-app \
                -Dsonar.sources=. \
                -Dsonar.exclusions=**/mysql-data/**,**/.git/**,**/node_modules/** \
                -Dsonar.python.version=3.9 \
                -Dsonar.sourceEncoding=UTF-8
        """
    }
    echo "SonarQube analysis complete!"
}