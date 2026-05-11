def call() {
    echo "Running Trivy filesystem scan..."
    sh "trivy fs --severity HIGH,CRITICAL --format table --exit-code 0 ."
}