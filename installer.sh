# Define disk
DISK="/dev/sda"
DISK_BOOT_PARTITION="/dev/sda1"
DISK_NIX_PARTITION="/dev/sda2"

clear

# Undo previous stuff
set +e
umount -R /mnt
# cryptsetup close cryptroot
set -e

# Partitioning disk
echo -e "\n\033[1mPartitioning disk...\033[0m"
parted $DISK -- mklabel gpt
parted $DISK -- mkpart ESP fat32 1MiB 512MiB
parted $DISK -- set 1 boot on
parted $DISK -- mkpart Nix 512MiB 100%
echo -e "\033[32mDisk partitioned successfully.\033[0m"

# Setting up encryption
# echo -e "\n\033[1mSetting up encryption...\033[0m"
# cryptsetup -q -v luksFormat $DISK_NIX_PARTITION
# cryptsetup -q -v open $DISK_NIX_PARTITION cryptroot
# echo -e "\033[32mEncryption setup completed.\033[0m"

# Creating filesystems
echo -e "\n\033[1mCreating filesystems...\033[0m"
mkfs.fat -F32 -n boot $DISK_BOOT_PARTITION
# mkfs.ext4 -F -L nix -m 0 /dev/mapper/cryptroot
# Let mkfs catch its breath
sleep 3
echo -e "\033[32mFilesystems created successfully.\033[0m"

# Mounting filesystems
echo -e "\n\033[1mMounting filesystems...\033[0m"
mount -t tmpfs none /mnt
mkdir -pv /mnt/{boot,nix,etc/ssh,var/{lib,log}}
mount /dev/disk/by-label/boot /mnt/boot
# mount /dev/disk/by-label/nix /mnt/nix
mkdir -pv /mnt/nix/{secret/initrd,persist/{etc/ssh,var/{lib,log}}}
chmod 0700 /mnt/nix/secret
mount -o bind /mnt/nix/persist/var/log /mnt/var/log
echo -e "\033[32mFilesystems mounted successfully.\033[0m"

# Generating initrd SSH host key
echo -e "\n\033[1mGenerating initrd SSH host key...\033[0m"
ssh-keygen -t ed25519 -N "" -C "" -f /mnt/nix/secret/initrd/ssh_host_ed25519_key
echo -e "\033[32mSSH host key generated successfully.\033[0m"

# Creating public age key for sops-nix
echo -e "\n\033[1mConverting initrd public SSH host key into public age key for sops-nix...\033[0m"
sudo nix-shell --extra-experimental-features flakes -p ssh-to-age --run 'cat /mnt/nix/secret/initrd/ssh_host_ed25519_key.pub | ssh-to-age'
echo -e "\033[32mAge public key generated successfully.\033[0m"

# Completed
echo -e "\n\033[1;32mAll steps completed successfully. NixOS is now ready to be installed.\033[0m\n"
echo -e "Remember to add the server's host public key to sops-nix before installing!"
