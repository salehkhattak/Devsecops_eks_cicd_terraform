def call() {
    echo "Running OWASP Dependency Check..."
    dependencyCheck additionalArguments: '--scan . --format HTML --out reports/owasp', odcInstallation: 'OWASP'
    dependencyCheckPublisher pattern: 'reports/owasp/dependency-check-report.xml'
}