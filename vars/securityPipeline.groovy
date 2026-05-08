def call() {

    echo "Starting Security Scans..."

    sonarScan()
    owaspScan()
    trivyScan()

    echo "All security scans completed."
}