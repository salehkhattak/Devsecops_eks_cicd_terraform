def call() {
    echo "Running SonarQube analysis..."

    sh """
        docker run --rm \
        -e SONAR_HOST_URL="http://sonarqube:9000" \
        -e SONAR_LOGIN="sqa_3424188e008857466d964e870cfa90e7d19fd959" \
        -v \$PWD:/usr/src \
        sonarsource/sonar-scanner-cli
    """

    echo "SonarQube analysis complete!"
}