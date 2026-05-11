def call() {
    echo "Running SonarQube analysis..."

    sh """
        docker run --rm \
        -e SONAR_HOST_URL="http://sonarqube:9000" \
        -e SONAR_LOGIN="YOUR_SONAR_TOKEN" \
        -v \$PWD:/usr/src \
        sonarsource/sonar-scanner-cli
    """

    echo "SonarQube analysis complete!"
}