---
name: restore-luks-tpm-autounlock
description: Reapply Charlie's TPM2-based auto-unlock for the LUKS-encrypted root disk (skips the passphrase prompt on the Plymouth "OMARCHY" boot screen) on a fresh install or new machine, or re-bind it after a firmware/BIOS change breaks it.
---

# Restore LUKS TPM2 auto-unlock

This machine's encrypted root partition unlocks itself at boot via the TPM
(`clevis`), instead of prompting for the LUKS passphrase on the Plymouth
"OMARCHY" lock screen every cold boot. The manual passphrase is **never**
removed -- it stays in its own keyslot as a fallback, so a TPM mismatch (see
below) degrades to "type the passphrase like before," never a lockout.

**Always load the repo's `omarchy` skill first** for the general safety
rules (never edit `/usr/share/omarchy/`, prefer `sudo` in a real terminal
over `pkexec`, etc.). This skill only covers the disk-encryption specifics.

**This tool (Claude Code) generally cannot run the privileged steps below
itself** -- there's no interactive TTY for a `sudo` password prompt from
here. Hand each command to the user to run in their own terminal and paste
back the output, the same way this setup was originally built.

## Is this even wanted on the new machine?

This is a real security trade-off, not a pure convenience toggle: full-disk
encryption's main value is protecting data when the device is *powered off*
in someone else's hands. TPM2 auto-unlock defeats exactly that scenario for
a simple "steal it, turn it on" attack -- it only still protects against the
disk being moved to different hardware or the boot chain/firmware being
tampered with. Confirm the user actually wants this trade-off before
reapplying it on a new install; don't assume yes just because this repo has
it.

## Fast path: same machine, TPM enrollment just broke

If auto-unlock stops working (prompts for the passphrase again) after a
firmware/BIOS update or toggling Secure Boot, that's PCR7 (secure boot/
firmware state) changing, not a lost keyslot. Re-bind:

```bash
sudo clevis luks unbind -d /dev/nvme0n1p2 -s 1
sudo clevis luks bind -d /dev/nvme0n1p2 tpm2 '{"pcr_bank":"sha256","pcr_ids":"7"}'
```

No initramfs rebuild needed -- the clevis token lives in the LUKS2 header on
disk, not baked into the boot image. Verify with:

```bash
sudo cryptsetup luksDump /dev/nvme0n1p2 | grep -A3 Tokens
# should show: 0: clevis / Keyslot: 1
```

Then reboot to confirm the Plymouth screen flashes and clears itself instead
of waiting for input.

`/dev/nvme0n1p2` is this machine's device -- on a different machine, find
the real one first: `lsblk -f | grep crypto_LUKS`.

## Slow path: fresh install / new machine, from scratch

1. **Identify the LUKS root partition**: `lsblk -f | grep crypto_LUKS`.

2. **Install clevis and the TPM tools**:
   ```bash
   omarchy pkg add clevis tpm2-tools
   ```
   The official `clevis` package does **not** ship an mkinitcpio hook by
   itself -- without the next step, `mkinitcpio -P` will fail with
   `Hook 'clevis' cannot be found`. Also install the AUR hook package:
   ```bash
   omarchy pkg aur add mkinitcpio-clevis-hook
   # or: yay -S mkinitcpio-clevis-hook
   ```
   This drops `/etc/initcpio/hooks/clevis` and `/etc/initcpio/install/clevis`.

3. **Find where HOOKS is actually defined.** On this Omarchy install it's
   not the base `/etc/mkinitcpio.conf` -- a drop-in overrides it entirely:
   ```bash
   grep -rn "^HOOKS" /etc/mkinitcpio.conf /etc/mkinitcpio.conf.d/*.conf
   ```
   Whichever file does a plain `HOOKS=(...)` assignment (not `+=`) is the
   one that wins; on this machine that's `/etc/mkinitcpio.conf.d/
   omarchy_hooks.conf`. Back it up, then insert `clevis` immediately
   **before** `encrypt` (order matters -- clevis has to unseal the key
   before the encrypt hook tries to prompt for it):
   ```bash
   sudo cp /etc/mkinitcpio.conf.d/omarchy_hooks.conf{,.bak}
   sudo sed -i 's/block encrypt/block clevis encrypt/' /etc/mkinitcpio.conf.d/omarchy_hooks.conf
   ```
   If a future Omarchy version restructures this drop-in, re-derive the
   right insertion point instead of assuming `block encrypt` still appears
   verbatim -- `grep "^HOOKS"` the file first.

4. **Rebind the LUKS device to the TPM**, PCR7 only:
   ```bash
   sudo clevis luks bind -d <device> tpm2 '{"pcr_bank":"sha256","pcr_ids":"7"}'
   ```
   **Do not use PCR11**, even though it looks like the "right" choice for a
   measured-UKI system (`bootctl status` showing `Measured UKI: yes`).
   Binding was tried against PCR11 first and failed after every reboot: on
   systemd 261 (as shipped here), the "TPM PCR Barrier" mechanism extends
   PCR11 further *after* the initramfs stage (userspace `sysinit`/`ready`
   barriers, visible in `journalctl -b | grep -i pcrextend`). Binding from
   an already-booted desktop session seals against that later, more-extended
   PCR11 value -- which never matches the earlier value seen by the `clevis`
   hook during actual early boot, so it always falls through to the manual
   passphrase. PCR7 (secure boot/firmware state) doesn't have this problem
   because nothing extends it after the initramfs stage.

5. **Rebuild the boot image.** This system uses Limine + a measured UKI, not
   plain mkinitcpio presets -- `mkinitcpio -P` alone won't update the boot
   entry:
   ```bash
   sudo mkinitcpio -P
   # ==> WARNING: This does not update Limine boot entries.
   #     Use 'limine-mkinitcpio' or 'limine-update' instead.
   # ==> Would you like to run 'limine-mkinitcpio' now? [Y/n]: Y
   ```
   Confirm the run log shows `Running build hook: [clevis]` with no `ERROR`
   line, and ends with `Copied: ... -> /boot/EFI/Linux/omarchy_linux.efi` /
   `Updated: /boot/limine.conf`. If a HOOKS edit is ever wrong, `mkinitcpio
   -P` fails loudly at build time -- it does not silently produce a broken
   image, so it's safe to iterate on step 3 and re-run this until it's
   clean, all before ever rebooting.

6. **Reboot and verify** -- the Plymouth OMARCHY screen should flash briefly
   and clear itself. If it still prompts, check `journalctl -b | grep -iE
   "clevis|tpm|pcr"` for what the TPM setup/measurement did on that boot
   before assuming the bind itself is wrong.

## Keep this updated

If the bootloader changes (e.g. away from Limine), the mkinitcpio HOOKS
drop-in location changes, or a newer systemd changes how/when it extends
PCR11, update this file with what was re-derived -- same spirit as
`restore-omarchy-setup`'s note about not trusting stale Lua/QML syntax.
