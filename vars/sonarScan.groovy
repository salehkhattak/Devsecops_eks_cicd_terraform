def call() {
    echo "Running SonarQube analysis..."

    // Pull the scanner image first to give clear feedback if pull fails
    sh "docker pull sonarsource/sonar-scanner-cli"

    // Run the scanner on the same Docker network as the SonarQube server
    // so the hostname 'sonarqube' resolves correctly.
    sh """
        docker run --rm \
        --network devsecops-eks-proj_three-tier \
        -e SONAR_HOST_URL="http://sonarqube:9000" \
        -e SONAR_LOGIN="sqa_3424188e008857466d964e870cfa90e7d19fd959" \
        -v \$PWD:/usr/src \
        sonarsource/sonar-scanner-cli \
        -Dsonar.projectKey=flask-devsecops \
        -Dsonar.sources=/usr/src
    """

    echo "SonarQube analysis complete!"
}