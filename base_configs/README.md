# IAM: 
## Structured list of all key **`pulumi_aws.iam` resources** for the **AutoOpsScaler** platform, based on its architecture:

---

##  **Common Pulumi AWS IAM Resources**

| IAM Resource                   | Pulumi Resource Name           | Purpose in AutoOpsScaler                                                                  |
| ------------------------------ | ------------------------------ | ----------------------------------------------------------------------------------------- |
| **IAM Role**                   | `aws.iam.Role`                 | Assigns permissions to services like EKS nodes, Lambda, Ray pods, Karpenter, GitHub OIDC. |
| **IAM Policy**                 | `aws.iam.Policy`               | Defines granular permission sets (S3 access, ECR push, Qdrant, Pulumi stack ops).         |
| **IAM Role Policy Attachment** | `aws.iam.RolePolicyAttachment` | Binds managed policies (like `AmazonS3ReadOnlyAccess`) to roles.                          |
| **IAM Instance Profile**       | `aws.iam.InstanceProfile`      | Needed for EC2-based services (e.g. self-hosted Ray Head if used).                        |
| **IAM User**                   | `aws.iam.User`                 | For long-term programmatic access (rare; mostly avoid this in GitOps infra).              |
| **IAM Group**                  | `aws.iam.Group`                | Rarely needed unless managing user groups (more common in manual workflows).              |
| **IAM User Policy Attachment** | `aws.iam.UserPolicyAttachment` | Attaches policies to IAM users (skip unless IAM users are required).                      |
| **IAM Policy Document**        | `aws.iam.get_policy_document`  | Generates JSON policies dynamically for `aws.iam.Policy` or trust policies.               |
| **IAM Role Policy**            | `aws.iam.RolePolicy`           | Inline policy embedded directly inside a role (less preferred than managed).              |

---

##  **Which IAM resources do you actually need?**

###  **1. Core Infrastructure**

* **IAM Roles** for:

  * Pulumi to provision infra via OIDC (if using GitHub Actions OIDC)
  * EKS control plane and EKS node groups (standard AWS-managed roles)
  * Karpenter (requires a custom trust policy and SQS/SNS permissions)
  * Ray pods (assuming they run in IRSA mode with fine-grained permissions)

* **IAM Policies** for:

  * Custom permissions for Ray (S3, Qdrant, logging, ECR pulls)
  * FluxCD or GitOps agents if they interact with cloud APIs
  * Limited-scope policies for db seeders, secrets syncers, etc.

###  **2. Data Pipeline**

* **Ray Worker IAM Roles** with IRSA:

  * Allow access to: S3 (raw + processed), Qdrant, CloudWatch, maybe Athena
  * Defined per environment (dev/prod separation)

* **EC2 Instance Profile** (if any compute-heavy parts like embedding use EC2 + GPU outside of EKS)

###  **3. CI/CD**

* **IAM Role** for GitHub OIDC + Pulumi:

  * Trust policy allowing GitHub Actions identity
  * Attached policy allowing full infra provisioning

###  **4. Observability / Logging**

* **IAM Roles** for:

  * CloudWatch logs ingestion (from Ray, EKS, etc.)
  * Optional: OpenTelemetry collector or custom metrics pushers

---

##  Summary: **Must-Have IAM Resources**

| Resource                       | Description                                      |
| ------------------------------ | ------------------------------------------------ |
| `aws.iam.Role`                 | For Pulumi, EKS, Karpenter, Ray, GitHub OIDC     |
| `aws.iam.Policy`               | Custom policies for S3, Qdrant, SecretsManager   |
| `aws.iam.RolePolicyAttachment` | Attach AWS managed + custom policies             |
| `aws.iam.InstanceProfile`      | For EC2-based services (if any)                  |
| `aws.iam.get_policy_document`  | Generate dynamic assume-role and access policies |

---

### **Avoid unless necessary**

* `iam.User`, `iam.Group`, `UserPolicyAttachment`: only for long-term manual access (against GitOps principle)

---

