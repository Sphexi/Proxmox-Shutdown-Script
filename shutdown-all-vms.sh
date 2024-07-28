# Script to try to gracefully shut down all running VMs on a Proxmox host,
# before then force stopping them.

# Running as a sub-script of CyberPower's UPS pwrstatd-powerfail.sh script
# to ensure that VMs are shut down before the host is powered off.

# Get a list of running VMs
vmlist=$(qm list | grep running | awk '{print $1}')

# Loop through the list and force shutdown each VM
for vmid in $vmlist
do
  echo "Shutting down VM $vmid"
  qm shutdown $vmid --forceStop 1 --timeout 30 # Try to force shutdown VMs with a 30 second timeout
done

# Wait for 30 seconds to allow VMs to shut down
sleep 30

# Get a list of running VMs again
vmlist=$(qm list | grep running | awk '{print $1}')

# If there are still running VMs, print a warning
if [ -n "$vmlist" ]; then
  echo "WARNING: The following VMs are still running:"
  echo $vmlist
  echo "Will attempt to kill them now"
    for vmid in $vmlist
    do
      echo "Killing VM $vmid"
      qm stop $vmid --forceStop 1
    done
fi

# Exit with success
exit 0