def call() {
    echo "Running OWASP Dependency Check..."

    sh """
        docker run --rm \
        -v \$PWD:/src \
        owasp/dependency-check \
        --scan /src \
        --format HTML \
        --out /src/reports
    """

    echo "OWASP scan complete!"
}