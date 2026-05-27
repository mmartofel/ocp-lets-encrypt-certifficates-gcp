# Generate new kubeconfig and check if its working fine 


oc config view --flatten --minify > ./kubeconfig
KUBECONFIG=kubeconfig oc config get-contexts
KUBECONFIG=kubeconfig oc get nodes

