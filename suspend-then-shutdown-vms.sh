# Script to try to suspend VMs before shutting them down fully.
# Set a list of VM tags that should be suspended, the script will check
# all VMs for these tags and if found will suspend the VM, otherwise
# it will shut the VM down completely.

# Running as a sub-script of CyberPower's UPS pwrstatd-powerfail.sh script
# to ensure that VMs are shut down before the host is powered off.

# Set the tags below that should be suspended:
# ex:
# declare -a suspend_tags=("windows" "linux")
# This will suspend any VMs with the tags "windows" or "linux"
declare -a suspend_tags=("windows" "linux")

# Get a list of running VMs
vmlist=$(qm list | grep running | awk '{print $1}')

# Loop through the list and suspend or shutdown each VM
for vmid in $vmlist; do
  tags=$(qm config $vmid | grep tags | awk '{print $2}')
  # Check if the VM has any suspend tag
  for tag in "${suspend_tags[@]}"; do
    echo $tag
    echo $tags | grep -q $tag
    if echo $tags | grep -q $tag; then
      echo "Suspending VM $vmid"
      qm suspend $vmid --todisk 1
      continue 2
    fi
  done
done

# Wait for 30 seconds to allow VMs to suspend
sleep 30

# Get a list of running VMs again, then do a full shutdown
vmlist=$(qm list | grep running | awk '{print $1}')
for vmid in $vmlist
do
  echo "Shutting down VM $vmid"
  qm shutdown $vmid --forceStop 1 --timeout 30 # Try to force shutdown VMs with a 30 second timeout
done

# Wait for 30 seconds to allow VMs to shutdown
sleep 30

# Get a list of running VMs again, if so kill them
vmlist=$(qm list | grep running | awk '{print $1}')
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

