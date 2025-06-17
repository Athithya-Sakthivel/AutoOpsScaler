# **AutoOpsScaler — Quick Start**

### **Prerequisite:**

A full Linux setup is required (do **not** use Docker Desktop, WSL,devcontainers).

---

## **One-time installation prerequisites**

| Windows                                                                                                              | macOS/Linux                                                        |
| -------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------ |
| [Visual Studio Code](https://code.visualstudio.com/) *(required)*                                                    | [Visual Studio Code](https://code.visualstudio.com/) *(required)*  |
| [Visual C++ Redistributable](https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist?view=msvc-170) | *(not required)*                                                   |
| [Git](https://git-scm.com/downloads)                                                                                 | [Git](https://git-scm.com/downloads)                               |
| [Vagrant 2.4.3](https://developer.hashicorp.com/vagrant/downloads)                                                   | [Vagrant 2.4.3](https://developer.hashicorp.com/vagrant/downloads) |
| [VirtualBox](https://www.virtualbox.org/wiki/Downloads)                                                              | [VirtualBox](https://www.virtualbox.org/wiki/Downloads)            |

> **Note:** If the latest VirtualBox version has compatibility issues with Vagrant 2.4.3, use [VirtualBox 7.0.14](https://download.virtualbox.org/virtualbox/7.0.14/).

---

## **Restart your system and get started**

> Open a **Git Bash** terminal and run the following command.The first run may take longer as the Ubuntu Jammy VM box will be downloaded.

```bash
cd $HOME && git config --global core.autocrlf false && git clone https://github.com/Athithya-Sakthivel/AutoOpsScaler.git && cd AutoOpsScaler && vagrant up && bash ssh.sh
```

---

## **Connecting via Visual Studio Code (Alternative method)**

1. Run `vagrant up` (if the VM is not already running).
2. Open Visual Studio Code on your local machine.
3. Install the **Remote - SSH** extension (if not already installed).
4. Click the green icon in the lower-left corner, or press `Ctrl+Shift+P` and select **Remote-SSH: Connect to Host**.
5. Choose **`AutoOpsScaler`** from the list.
6. When prompted for the platform, select **Linux** (the VM runs Linux).

To open the project in VS Code, run:

```bash
cd /vagrant/ && code .
```

---

## **Important: VM Lifecycle**

 ### **After a system reboot**, the VM will be shut down. Always start it manually before connecting from VS Code:

  * Open VirtualBox → Right-click the VM → **Start → Headless Start**

  ![Start the VM](.vscode/Start_the_VM.png)

### **Optionally, you can save the VM state before shutting down your system for faster resumption:**

  * Open VirtualBox → Right-click the VM → **Close → Save State**

  ![Save VM state](.vscode/Save_VM_state.png)
