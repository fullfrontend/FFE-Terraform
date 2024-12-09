#cloud-config
users:
    - name: deploy
      ssh-authorized-keys:
        - ${pubkey}
      sudo: ['ALL=(ALL) NOPASSWD:ALL']
      groups: sudo
      shell: /bin/bash
mounts:
    - [ /dev/disk/by-id/scsi-0DO_Volume_${volume-name}, /mnt/${volume-name}, "ext4", "defaults,nofail,discard", "0", "0"]
runcmd:
    # Update SSH settings
    - sed -i -e '/PermitRootLogin/c\PermitRootLogin no' /etc/ssh/sshd_config
    - sed -i -e '$aAllowUsers deploy' /etc/ssh/sshd_config
    - systemctl restart sshd
    # Assign permissions
    - chown deploy:deploy /mnt/${volume-name}
