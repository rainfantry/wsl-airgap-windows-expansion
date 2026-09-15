@echo off
echo [%time%] Restoring Strict Host Security Rules...
:: 1. Force the global Windows firewall back to maximum lockdown
powershell -Command "Set-NetFirewallProfile -Profile Domain,Private,Public -DefaultOutboundAction Block"

:: 2. Terminate the WSL subsystem instance completely
powershell -Command "wsl --shutdown"

echo ----------------------------------------------------
echo SYSTEM IS LOCKED DOWN.
echo Global outbound blocks are active and WSL is isolated.
echo ----------------------------------------------------
pause
