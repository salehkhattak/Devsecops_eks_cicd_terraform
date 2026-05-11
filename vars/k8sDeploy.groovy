def call(String image) {

    echo "Deploying to Kubernetes: ${image}"

    sh """
        sed -i 's|image: .*|image: ${image}|' myk8s/app-deployment.yml
        kubectl apply -f myk8s/
        kubectl rollout status deployment/myflask-app --timeout=300s
    """

    echo "Deployment completed!"
}