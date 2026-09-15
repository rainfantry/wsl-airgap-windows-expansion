@echo off
echo [%time%] Temporarily lowering profile blocks for updates...
powershell -Command "Set-NetFirewallProfile -Profile Domain,Private,Public -DefaultOutboundAction Allow"
powershell -Command "wsl --shutdown"
echo ----------------------------------------------------
echo SYSTEM IS TEMPORARILY UNLOCKED FOR KALI UPDATES.
echo Run your "sudo apt update && sudo apt install -y kali-win-kex" now.
echo ----------------------------------------------------
pause
