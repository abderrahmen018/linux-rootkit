# Hidden Process - Documentation

## Description
A resident application that hides its process and periodically records its PCB (Process Control Block) information to a system file.


### Build
```bash
make all
```
### Install (systemd service)
```bash
sudo make install
```
### Automated Installation
```bash
sudo ./deploy.sh
```
### Manual Execution
```bash
sudo ./build/hiddenprocess
```
### Verification
```bash
sudo cat /root/process.txt
```
### Uninstall
```bash
sudo make uninstall
```

## Features
- 🔒 Hidden Process: Invisible from standard process lists
- 📊 PCB Monitoring: Periodic recording of Process Control Block information
- ⚙️ System Service: Installs as a persistent systemd service
- 📝 Logging: Output file at /root/process.txt
