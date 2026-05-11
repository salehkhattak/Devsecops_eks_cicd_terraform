def call(String image) {
    echo "Running Trivy image scan..."
    sh "trivy image --severity HIGH,CRITICAL --format table --exit-code 0 ${image}"
}