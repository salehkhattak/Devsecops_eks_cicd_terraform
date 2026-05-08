def owasp_scan() {
    sh """
    dependency-check.sh \
    --project "three-tier-app" \
    --scan . \
    --format HTML \
    --out reports
    """
}