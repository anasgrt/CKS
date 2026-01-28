# CKS Exam Simulator 2026

A comprehensive practice lab for the **Certified Kubernetes Security Specialist (CKS)** exam, featuring 14 real-world security scenarios.

## 🎯 Overview

This simulator provides hands-on practice questions covering all CKS exam domains:

| Domain | Weight | Questions |
|--------|--------|-----------|
| Cluster Setup | 15% | Q02, Q03, Q05, Q07 |
| Cluster Hardening | 15% | Q02, Q08, Q13 |
| System Hardening | 15% | Q06 |
| Minimize Microservice Vulnerabilities | 20% | Q11 |
| Supply Chain Security | 20% | Q04, Q10, Q12 |
| Monitoring, Logging & Runtime Security | 20% | Q01, Q09, Q14 |

## 🚀 Getting Started

### Prerequisites

- A Kubernetes cluster (kind, minikube, or real cluster) - **Kubernetes v1.30+**
- `kubectl` configured and working
- Root/sudo access for some questions
- Tools (for specific questions):
  - `falco` - Runtime security monitoring
  - `bom` or `syft` - SBOM generation
  - `trivy` - Image scanning
  - `kube-bench` - CIS benchmarks

### Quick Start

```bash
# Make scripts executable
chmod +x scripts/run-question.sh
find . -name '*.sh' -exec chmod +x {} \;

# List all questions
./scripts/run-question.sh list

# Setup a specific question
./scripts/run-question.sh 1

# Work on the question...

# Verify your solution
./scripts/run-question.sh 1 verify

# Need help? Show the solution
./scripts/run-question.sh 1 solution

# Reset and try again
./scripts/run-question.sh 1 reset
```

## 📋 Commands

| Command | Description |
|---------|-------------|
| `list` | List all available questions |
| `setup <N>` | Setup environment for question N (default) |
| `verify <N>` | Verify your solution |
| `solution <N>` | Display the solution |
| `reset <N>` | Reset the environment |
| `question <N>` | Display question text only |
| `exam` | Start full exam simulation (2 hours) |

## 📚 Questions

### Question 01 - Falco Runtime Security (7%)
Identify and stop a pod accessing `/dev/mem` using Falco runtime detection.

### Question 02 - Worker Node Upgrade (5%)
Upgrade a worker node from Kubernetes 1.34.0 to 1.34.1.

### Question 03 - Ingress with TLS (5%)
Configure an Ingress with TLS termination and HTTP to HTTPS redirect.

### Question 04 - SBOM Generation (4%)
Generate a Software Bill of Materials in SPDX format.

### Question 05 - TLS Secret (2%)
Create a TLS secret from certificate and key files.

### Question 06 - Docker Daemon Hardening (5%)
Secure Docker daemon configuration on a cluster node.

### Question 07 - Network Policy (7%)
Create NetworkPolicies to deny all ingress and allow specific traffic.

### Question 08 - ServiceAccount Token (5%)
Configure projected volume for ServiceAccount token mounting.

### Question 09 - Kubernetes Auditing (7%)
Configure kube-apiserver audit logging with custom policy.

### Question 10 - ImagePolicyWebhook (7%)
Setup ImagePolicyWebhook admission controller.

### Question 11 - Pod Security Admission (7%)
Identify and delete pods violating PSA restricted policy.

### Question 12 - Dockerfile Security (7%)
Fix security issues in Dockerfile and Deployment manifest.

### Question 13 - Kubelet Security (5%)
Harden kubelet configuration on a worker node.

### Question 14 - Container Immutability (7%)
Configure read-only root filesystem with emptyDir for writable paths.

## 📁 Directory Structure

```
cks-real-exam-questions/
├── scripts/
│   └── run-question.sh       # Main runner script
├── Question-01-Falco/
│   ├── question.txt          # Question description
│   ├── setup.sh              # Environment setup
│   ├── verify.sh             # Solution verification
│   ├── solution.sh           # Step-by-step solution
│   └── reset.sh              # Cleanup
├── Question-02-Upgrade/
│   └── ...
├── Question-03-IngressTLS/
│   └── ...
├── ... (14 questions total)
└── README.md
```

## 💡 Tips for the CKS Exam

### Time Management
- 2 hours for ~15-20 questions
- Average 6-8 minutes per question
- Don't get stuck - flag and move on

### Key Resources
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- Use `kubectl explain` for quick reference
- Bookmark important pages

### Common Patterns
```bash
# Quick pod with curl for testing
kubectl run test --image=curlimages/curl --rm -it -- curl <service>

# Export resource to YAML
kubectl get deployment <name> -o yaml > deployment.yaml

# Check API server logs
kubectl logs -n kube-system kube-apiserver-<node>

# Verify cluster health
kubectl get nodes
kubectl get pods -A
```

### Security Contexts Cheat Sheet
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop: ["ALL"]
```

## 🔧 Troubleshooting

### API Server Won't Start
```bash
# Check static pod logs
sudo cat /var/log/pods/kube-system_kube-apiserver-*/kube-apiserver/*.log

# Restore from backup
sudo cp /etc/kubernetes/manifests/kube-apiserver.yaml.bak /etc/kubernetes/manifests/kube-apiserver.yaml
```

### Kubelet Issues
```bash
# Check kubelet status
sudo systemctl status kubelet

# View kubelet logs
sudo journalctl -u kubelet -f
```

### Reset Everything
```bash
# Reset all questions
for dir in Question-*/; do
    bash "$dir/reset.sh" 2>/dev/null || true
done
```

## 📝 License

This project is for educational purposes. Good luck with your CKS exam! 🎉

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

---

**Author:** CKS Exam Preparation
**Version:** 2026
**Last Updated:** January 2026
