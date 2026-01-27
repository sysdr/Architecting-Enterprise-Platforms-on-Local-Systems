# Nano-IDP Lesson 2: OS Memory Tuning

## Quick Start

### 1. Configure Host System

**Linux:**
```bash
# Create 4GB swap
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Tune swappiness
sudo sysctl vm.swappiness=10
sudo sysctl vm.vfs_cache_pressure=50
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
echo "vm.vfs_cache_pressure=50" | sudo tee -a /etc/sysctl.conf
```

**Windows (PowerShell as Admin):**
```powershell
# Set pagefile to 4GB fixed
$ComputerSystem = Get-WmiObject Win32_ComputerSystem -EnableAllPrivileges
$ComputerSystem.AutomaticManagedPagefile = $false
$ComputerSystem.Put()

$PageFile = Get-WmiObject -Query "SELECT * FROM Win32_PageFileSetting WHERE Name='C:\\pagefile.sys'"
$PageFile.InitialSize = 4096
$PageFile.MaximumSize = 4096
$PageFile.Put()

# Enable memory compression
Enable-MMAgent -MemoryCompression
```

### 2. Deploy Monitor
```bash
./scripts/build_and_deploy.sh
```

### 3. Verify
```bash
./scripts/verify.sh
```

### 4. Access Dashboard

Open: http://localhost:30080

### 5. Test Memory Pressure
```bash
kubectl apply -f test/memory-pressure-pod.yaml
```

Watch the dashboard respond to memory pressure.

## Cleanup
```bash
./scripts/cleanup.sh
```

## Resource Footprint

| Component | Memory | CPU |
|-----------|--------|-----|
| Backend | 64Mi | 50m |
| Frontend | 32Mi | 25m |
| **Total** | **96Mi** | **75m** |

## Key Learnings

1. **Swappiness = 10** prevents thrashing on 8GB systems
2. Direct `/proc` parsing beats heavy libraries
3. 3-second polling balances UX and efficiency
