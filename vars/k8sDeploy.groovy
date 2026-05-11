def call(String image) {
    echo "Deploying to EKS: ${image}"

    sh """
        sed -i 's|image: salehktk005/myflask-app.*|image: ${image}|' myk8s/app-deployment.yml
        kubectl apply -f myk8s/
        kubectl rollout status deployment/myflask-app --timeout=300s
    """
}