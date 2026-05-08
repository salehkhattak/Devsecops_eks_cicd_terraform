def call(String imageName) {

    echo "Starting Security Scans..."

    sonarScan()
    owaspScan()
    trivyScan(imageName)

    echo "All security scans completed."
}