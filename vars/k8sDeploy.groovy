def call(String image) {
    echo "Deploying to EKS: ${image}"

    sh """
        sed -i 's|image: salehktk005/saleh-thoughts-app.*|image: ${image}|' eks-manifests/three-tier-app-deployment.yml
        kubectl apply -f eks-manifests/
        kubectl rollout status deployment/three-tier-flask-app --timeout=300s
    """
}