## **Course Details**

[Check Course Curriculum](https://systemdrd.com/courses/architecting-enterprise-local-system-design/).

### **Why This Course?**

Look, anyone can build a platform with an unlimited cloud budget and a 100-node cluster. That doesn't teach you engineering; that teaches you spending. True mastery comes from constraints.

I’ve interviewed hundreds of "Senior" engineers who can run a Terraform script but have no idea why their pods are getting OOMKilled or how the Linux kernel handles memory pressure. In this course, we simulate the friction, resource contention, and architectural trade-offs of a massive enterprise environment, but we do it entirely on your local 8GB laptop. By forcing a production-grade Internal Developer Platform (IDP) into a constrained memory budget, you will learn optimization strategies that most "cloud-native" engineers never encounter until they take down production. We aren't just running scripts; we are engineering a substrate.

### **What You’ll Build**

You will engineer **The Nano-IDP**, a fully functional, multi-tenant platform capability of supporting hypothetical feature teams. It includes:

* **Substrate:** A tuned K3d cluster running Cilium eBPF networking (stripped of heavy sidecars).  
* **Control Plane:** An ArgoCD-driven GitOps engine optimized for low-memory footprints.  
* **Infrastructure Engine:** A Crossplane implementation delivering "Infrastructure as Data" using Python logic.  
* **Tenancy Model:** Hard isolation using vCluster to spin up ephemeral virtual clusters that "sleep" when idle.  
* **The Portal:** A bespoke **Python (FastAPI) and React** Developer Portal that replaces heavy off-the-shelf tools like Backstage.  
* **Resilience:** Self-healing capabilities tested against real chaos (network latency, pod failure).

### **Who Should Take This Course?**

* **Platform Engineers** who need to move beyond "installing tools" to "architecting systems."  
* **Python/React Developers** who want to break into Platform Engineering but feel intimidated by the "Java/Go" heavy ecosystem.  
* **SREs** who need to understand the internal mechanics of the platforms they operate.  
* **Software Architects** designing systems where cost and efficiency are first-class citizens.  
* **Students & Fresh Grads** who want to build a portfolio project that actually proves they understand system internals.

### **What Makes This Course Different?**

* **The 8GB Constraint:** We don't handwave resource usage. We optimize JVM heaps, tune control plane memory, and strip unused CRDs to make it fit. This mimics the "Cost Awareness" required in real FinOps environments.  
* **Everyday Code:** No slides. Every lesson ends with a commit. If it doesn't run on your laptop, it doesn't count.  
* **No "Black Box" Magic:** We don't use managed services. We build the "glue" ourselves using Python and eBPF.  
* **Failure-Driven:** We will intentionally break things—induce split-brain scenarios, fill disks, and cause sync loops—so you know how to fix them when it matters.

### **Key Topics Covered**

* **Advanced Kubernetes:** K3d internals, API server tuning, and eBPF networking on low resources.  
* **GitOps Patterns:** Sync waves, app-of-apps, and resolving dependency hell without heavy UIs.  
* **Infrastructure as Data:** Crossplane provider families, Composition Functions in Python, and XRDs.  
* **Multi-Tenancy:** Virtual Clusters (vCluster) vs. Namespace isolation and "Scale-to-Zero" architectures.  
* **Progressive Delivery:** Blue/Green and Canary deployments using Argo Rollouts.  
* **Portal Engineering:** Building a custom IDP interface with FastAPI and React.

### **Prerequisites**

* **Hardware:** A computer with exactly **8GB RAM** (Strictly enforced. 4GB Swap required).  
* **Software:** Docker Desktop (or Rancher Desktop), VS Code.  
* **Knowledge:** Comfortable with terminal/CLI, basic Python, and understanding of JSON/YAML.


**Course Structure**

The course flows logically from the bottom up—starting with the raw compute substrate and layering abstractions until we reach the developer interface.

* **Module 1: The Substrate (Lessons 1-12)** - Designing a memory-efficient Kubernetes foundation using K3d and Cilium.  
* **Module 2: The Control Plane (Lessons 13-25)** - Establishing the GitOps engine with ArgoCD to manage the platform itself.  
* **Module 3: Infrastructure as Code (Lessons 26-45)** - Building the provisioning engine with Crossplane and Python logic.  
* **Module 4: The Tenancy Model (Lessons 46-60)** - Implementing hard isolation using vClusters for tenant environments.  
* **Module 5: Progressive Delivery (Lessons 61-72)** - Managing safe deployments with Argo Rollouts.  
* **Module 6: The Interface (Lessons 73-82)** - Creating the "Golden Path" with a custom Python/React Portal.  
* **Module 7: Day 2 Operations (Lessons 83-90)** - Chaos engineering, cost monitoring, and the final Capstone integration.
