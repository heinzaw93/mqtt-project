# mqtt-project
# 🔐 Secure Multi-Broker MQTT Architecture

## 📌 Overview

This project presents a **secure multi-broker MQTT architecture** designed to enhance communication security, scalability, and device authentication in distributed IoT environments.

The system introduces a **central broker** and **bridge brokers** with integrated cryptographic mechanisms to address common security weaknesses in traditional MQTT deployments.

---

## 🧱 System Architecture

The architecture consists of:

* **Central Broker (Sunny)**

  * Acts as the main message hub
  * Handles authentication and security enforcement

* **Bridge Brokers (Cookie & Cake)**

  * Connect distributed MQTT networks
  * Enable secure inter-broker communication

* **Clients (Alice & Bob)**

  * Publish and subscribe to MQTT topics securely

---

## 🔐 Key Features

* ✅ Secure device authentication using certificates
* ✅ Encrypted communication (TLS-based)
* ✅ Multi-broker architecture for scalability
* ✅ Automated key and certificate management
* ✅ Database synchronization across nodes
* ✅ Role-based device management

---

## ⚠️ Problem Statement

Traditional MQTT architectures suffer from:

* ❌ Lack of built-in strong authentication
* ❌ Vulnerability to unauthorized access
* ❌ Weak encryption configurations
* ❌ Poor scalability in distributed environments

This project addresses these limitations by introducing **centralized security control with distributed communication support**.

---

## ⚙️ Technologies Used

* **MQTT Protocol**
* **Node-RED**
* **TLS/SSL Encryption**
* **Ubuntu Server**
* **Mosquitto MQTT Broker**
* **Database (for synchronization)**

---

## 🚀 Installation & Setup

# 🌐 Network Topology Setup

## 📌 Overview

This project implements a **multi-hop wireless network topology** for a secure multi-broker MQTT system. The topology consists of:

* **Central Broker (Sunny – Ubuntu VM)**
* **Bridge Brokers (Cookie & Cake – Raspberry Pi 4)**
* **Client Devices (Alice & Bob)**

Each node operates as:

* Wireless Access Point (via `hostapd`)
* DHCP Server (via ISC DHCP)
* Router/NAT Gateway (via `iptables`)

This topology enables **end-to-end connectivity** across multiple subnets and supports secure workflows such as:

* Device registration
* Mutual authentication
* Secure data transfer

---

## 🧱 Topology Structure

```text id="g2zqk9"
              Network-01            Network-02
                  \                    /
                   \                  /
                    [ Sunny (Central Broker) ]
                     /                    \
                    /                      \
        [ Cookie (Bridge Broker) ]   [ Cake (Bridge Broker) ]
                  |                          |
             Network-A                  Network-B
                  |                          |
               Alice                        Bob
```

---

## 🌍 IP Addressing Scheme

| Node   | Interface | Role   | IP Address    | Network         |
| ------ | --------- | ------ | ------------- | --------------- |
| Sunny  | wlanX     | AP     | 192.168.151.1 | Network-01      |
| Sunny  | wlanY     | AP     | 192.168.152.1 | Network-02      |
| Cookie | wlan0     | Uplink | DHCP          | Network-01 / 02 |
| Cookie | wlan1     | AP     | 192.168.153.1 | Network-A       |
| Cake   | wlan0     | Uplink | DHCP          | Network-01 / 02 |
| Cake   | wlan1     | AP     | 192.168.154.1 | Network-B       |

---

## 📡 1. Central Broker (Sunny)

### 🔹 Static IP Configuration

Configured in:

```bash id="a1k9sd"
/etc/network/interfaces
```

* Network-01 → `192.168.151.1`
* Network-02 → `192.168.152.1`

---

### 🔹 Hostapd Configuration

* `/etc/hostapd/hostapd.conf` → Network-01
* `/etc/hostapd/hostapd-wlanY.conf` → Network-02

Features:

* WPA2-PSK authentication
* 802.11g mode
* Channel configuration

---

### 🔹 DHCP Configuration

```bash id="x7sd2p"
/etc/dhcp/dhcpd.conf
```

* Network-01: `192.168.151.10 – 100`
* Network-02: `192.168.152.10 – 100`

---

### 🔹 Routing & NAT (rc.local)

```bash id="u1q9we"
sysctl -w net.ipv4.ip_forward=1
iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE
```

✔️ Enables:

* Internet access for all subnets
* Inter-network communication

---

### 🔹 Dynamic Routing (Core Feature)

Service:

```bash id="n8sk1p"
/etc/systemd/system/update-routes.service
```

Script:

```bash id="o2ps9x"
/usr/local/bin/update_routes.sh
```

### 🔧 Function:

* Scans networks using `nmap`
* Identifies Cookie & Cake via MAC address
* Automatically updates routes:

```bash id="k3z9rm"
ip route add 192.168.153.0/24 via <cookie_ip>
ip route add 192.168.154.0/24 via <cake_ip>
```

✔️ Ensures:

* Automatic recovery after DHCP changes
* No manual routing required

---

## 🔁 2. Bridge Broker (Cookie)

### 🔹 Interfaces

* `wlan0` → Uplink (DHCP from Sunny)
* `wlan1` → AP (Network-A)

### 🔹 Static IP

```text id="s0q1pl"
192.168.153.1/24
```

---

### 🔹 Hostapd

* SSID: **Network-A**
* WPA2-PSK secured

---

### 🔹 DHCP

* Range: `192.168.153.10 – 100`

---

### 🔹 NAT & Forwarding

```bash id="p9xw2m"
iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
iptables -A FORWARD -i wlan1 -o wlan0 -j ACCEPT
```

✔️ Allows:

* Clients → Sunny → Internet
* Bidirectional traffic

---

## 🔁 3. Bridge Broker (Cake)

### 🔹 Interfaces

* `wlan0` → Uplink
* `wlan1` → AP (Network-B)

### 🔹 Static IP

```text id="k4r8wd"
192.168.154.1/24
```

---

### 🔹 Hostapd

* SSID: **Network-B**

---

### 🔹 DHCP

* Range: `192.168.154.10 – 100`

---

### 🔹 NAT & Forwarding

```bash id="x9l3ds"
iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
iptables -A FORWARD -i wlan1 -o wlan0 -j ACCEPT
```

---

## 🔄 End-to-End Connectivity

### 🔹 Example Flow (Alice → Bob)

```text id="l2m9vp"
Alice → Cookie → Sunny → Cake → Bob
```

### 🔹 MQTT Flow

```text id="y8s2df"
Client → Bridge Broker → Central Broker → Bridge Broker → Client
```

---

## 🔐 Key Features

* Multi-hop wireless architecture
* Segmented subnet design
* Distributed DHCP services
* Centralized routing (Sunny)
* Dynamic route discovery (script-based)
* NAT-enabled internet access
* Mobility support (Cookie/Cake can switch networks)

---

## ⚠️ Important Notes

* Enable IP forwarding on all nodes:

```bash id="z8c1vn"
sysctl -w net.ipv4.ip_forward=1
```

* Ensure:

  * Correct interface names (`wlan0`, `wlan1`, etc.)
  * Hostapd services enabled at boot
  * Routing service active on Sunny

---

## 🧠 Summary

This topology provides:

* Reliable multi-subnet communication
* Automatic routing adaptation
* Scalable MQTT deployment
* Strong foundation for secure IoT communication

# 🔐 Step-CA Setup (Central Broker – Sunny)

## 📌 Overview

The central broker (**Sunny**) acts as the **Certificate Authority (CA)** using **Step-CA**. It is responsible for:

* Issuing MQTTS certificates
* Managing certificate renewal
* Handling certificate revocation
* Establishing trust across all brokers and clients

This enables **mutual TLS (mTLS)** for secure MQTT communication.

---

## 🧱 1. Create Step-CA User & Directories

```bash
sudo useradd --system --create-home --home-dir /home/step --shell /usr/sbin/nologin step

sudo -u step mkdir -p /home/step/.step
sudo mkdir -p /etc/step-ca/secrets

sudo chown -R step:step /home/step/.step
sudo chown -R step:step /etc/step-ca
sudo chmod 700 /etc/step-ca/secrets
```

---

## 🔑 2. Create and Secure Secrets

```bash
# Create passwords (CHANGE THESE)
echo 'change-this-INTERMEDIATE-password' | sudo tee /etc/step-ca/secrets/intermediate_password >/dev/null
echo 'change-this-PROVISIONER-password'  | sudo tee /etc/step-ca/secrets/provisioner_password  >/dev/null

# Secure permissions
sudo chown step:step /etc/step-ca/secrets/*
sudo chmod 600 /etc/step-ca/secrets/*
```

---

## ⚙️ 3. Initialize Step-CA

```bash
sudo -u step step ca init \
  --name "Sunny CA" \
  --dns sunny-ca.local \
  --dns 192.168.151.1 \
  --address :8443 \
  --provisioner "Admin JWK" \
  --password-file /etc/step-ca/secrets/intermediate_password \
  --provisioner-password-file /etc/step-ca/secrets/provisioner_password \
  --acme \
  --remote-management
```

### ✔️ What this does:

* Creates **root + intermediate certificates**
* Configures CA endpoint (`:8443`)
* Enables **ACME (automated issuance)**
* Enables **centralized certificate management**

---

## 🔄 4. Configure Step-CA Service

Create service file:

```bash
sudo nano /etc/systemd/system/step-ca.service
```

```ini
[Unit]
Description=Step-CA Service
After=network.target

[Service]
Type=simple
User=step
ExecStart=/usr/bin/step-ca /home/step/.step/config/ca.json
Restart=always

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable step-ca
sudo systemctl start step-ca
```

---

## 📄 5. CA Configuration (ca.json)

Location:

```
/home/step/.step/config/ca.json
```

Key configurations:

* **Root & Intermediate certificates**
* **Listening address:** `:8443`
* **DNS:** `sunny-ca.local`, `192.168.151.1`
* **Database:** BadgerDB (certificate storage)
* **Certificate lifetime:**

  * Default: 48 hours
  * Min: 24 hours
  * Max: 72 hours

---

## 🔗 6. Bootstrap Trust (All Devices)

### On Sunny:

```bash
ROOT=$(step path)/certs/root_ca.crt
install -D -m 0644 "$ROOT" /etc/mosquitto/certs/MQTTS.pem

step certificate fingerprint $(step path)/certs/root_ca.crt
```

### On Cookie, Cake, Alice:

```bash
step ca bootstrap \
  --ca-url https://192.168.151.1:8443 \
  --fingerprint <ROOT_FINGERPRINT> \
  --install
```

---

## 📜 7. Generate Certificates (Example: Cookie)

```bash
step ca certificate Cookie \
  /etc/mosquitto/certs/Cookie.pem \
  /etc/mosquitto/certs/Cookie-key.pem \
  --san Cookie \
  --san 192.168.153.1 \
  --provisioner "Admin JWK" \
  --provisioner-password-file /etc/step-ca/secrets/provisioner_password \
  --force
```

---

## 🔁 8. Certificate Renewal (Systemd Service)

```ini
[Unit]
Description=Renew Mosquitto TLS cert
After=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/step ca renew \
  /etc/mosquitto/certs/sunny.pem \
  /etc/mosquitto/certs/sunny-key.pem \
  --daemon \
  --root /etc/mosquitto/certs/MQTTS.pem \
  --exec /usr/local/bin/reload-mosquitto.sh

Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

✔️ Automatically:

* Renews certificates before expiry
* Reloads Mosquitto without downtime

---

## 🚫 9. Certificate Revocation

A script is used to safely query issued certificates:

### Key Process:

1. Create DB snapshot using `rsync`
2. Query certificates using `step-badger`
3. Filter:

   * Remove revoked/expired certs
   * Keep latest per device (CN)
4. Output clean JSON for dashboard use

### Output Example:

```json
[
  {
    "cn": "Cookie",
    "serial_hex": "abc123",
    "issued": "2026-01-01",
    "expire": "2026-01-03"
  }
]
```

✔️ Used for:

* Dashboard-based revocation
* Automation workflows

---

## 🔐 Security Summary

* Dedicated non-login **step user**
* Encrypted **CA private keys**
* Strict file permissions (600/700)
* Centralized certificate lifecycle management
* Automated renewal + controlled revocation

---

## 🧠 Notes

* Step-CA runs only on **Sunny**
* All nodes trust Sunny as the **root CA**
* Bob (Android) uses **Node-RED** for renewal instead of systemd
# 🗄️ Database Setup (SQLCipher – Encrypted Storage)

## 📌 Overview

To enforce **application-layer security**, each device in the system uses a **local encrypted database** powered by **SQLCipher** (SQLite + AES-256 encryption).

The database securely stores:

* Device identity information
* ECC cryptographic key pairs
* Topic-level encryption keys

This ensures that even if a device is compromised physically, sensitive data remains **encrypted at rest**.

---

## 🔐 Key Features

* AES-256 encryption (SQLCipher)
* Local database per device
* Secure storage of private keys
* Structured schema for security operations
* Supports:

  * Device registration
  * Mutual authentication
  * Secure topic communication

---

## ⚙️ 1. Create Encrypted Database

```bash id="zj3xg9"
sqlcipher /etc/mosquitto/certs/update_database.db
```

Inside SQLCipher shell:

```sql id="p2sx9v"
PRAGMA key = 'your-secure-password';
```

✔️ This:

* Creates an encrypted database
* Protects all stored data with a password

---

## 🧱 2. Database Schema Overview

The database consists of **three core tables**:

1. **DeviceProfile** → Device identity
2. **Keys** → ECC cryptographic keys
3. **Topic_Keys** → AES-256 topic encryption keys

---

## 📋 3. DeviceProfile Table (Device Identity)

### 🔹 Purpose

Stores unique identity and authentication details for each device.

```sql id="3l7r0x"
CREATE TABLE DeviceProfile (
    device_id TEXT PRIMARY KEY,
    device_name TEXT NOT NULL,
    mac_address_1 TEXT NOT NULL,
    mac_address_2 TEXT NOT NULL,
    jwt_token TEXT,
    is_broker INTEGER DEFAULT 0 CHECK(is_broker IN (0,1)),
    authentication_status TEXT,
    registered_at INTEGER NOT NULL
);
```

### 🔑 Key Fields

* `device_id` → Unique device identifier
* `device_name` → Human-readable name
* `mac_address_1 / mac_address_2` → Interface MACs
* `jwt_token` → Authentication token
* `is_broker` → Role (broker/client)
* `authentication_status` → Auth result tracking
* `registered_at` → Registration timestamp

---

## 🔑 4. Keys Table (ECC Cryptographic Keys)

### 🔹 Purpose

Stores ECC key pairs and session keys for secure communication.

```sql id="q1y8pk"
CREATE TABLE Keys (
    device_id TEXT PRIMARY KEY,
    private_key TEXT,
    public_key TEXT NOT NULL,
    registration_key BLOB,
    FOREIGN KEY (device_id) REFERENCES DeviceProfile(device_id)
);
```

### 🔑 Key Fields

* `private_key` → Device private key (confidential)
* `public_key` → Shared public key
* `registration_key` → AES-256 session key (ECDH derived)

✔️ One key record per device

---

## 🔐 5. Topic_Keys Table (Secure Topic Communication)

### 🔹 Purpose

Manages AES-256 keys for **topic-level encryption**

```sql id="zzx9c3"
CREATE TABLE IF NOT EXISTS topic_keys (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic_name TEXT NOT NULL UNIQUE,
    key BLOB NOT NULL UNIQUE,
    created_key INTEGER NOT NULL
);
```

### 🔑 Key Fields

* `topic_name` → Unique MQTT topic
* `key` → AES-256 encryption key
* `created_key` → Timestamp (for expiry/rotation)

✔️ One encryption key per topic

---

## 🔄 How It Works in the System

### 🔹 Device Registration

* Device identity stored in `DeviceProfile`
* ECC keys stored in `Keys`

### 🔹 Authentication

* JWT stored and verified via `DeviceProfile`
* Status updated in `authentication_status`

### 🔹 Secure Communication

* Topic keys stored in `topic_keys`
* Messages encrypted using AES-256

---

## 🔐 Security Design

* Full database encryption (AES-256)
* Private keys never leave device
* Foreign key constraints enforce integrity
* Unique constraints prevent duplication
* Timestamp tracking supports key lifecycle

---

## ⚠️ Important Notes

* Always protect the **PRAGMA key password**
* Backup encrypted database securely
* Do NOT store plaintext keys outside SQLCipher
* Ensure correct permissions on database file

---

## 🧠 Summary

The SQLCipher database provides:

* Secure storage of device identities
* Protection of cryptographic materials
* Foundation for authentication and encryption
* Strong application-layer security across all devices


---

# Node-RED Setup and Configuration

This section describes how Node-RED is deployed and configured across all brokers and client devices to implement the secure multi-broker MQTT framework. It covers the installation of required libraries, secure runtime configuration, HTTPS enablement, environment variable management, and encrypted context storage. These configurations provide the foundation for implementing secure workflows such as device registration, mutual authentication, database synchronization, and encrypted data transfer.

## Node-RED Installation and Service Setup

Node-RED is installed on each device using the official installation script. After installation, it is configured to run as a systemd service to ensure continuous operation and automatic startup after system reboot.

```bash
bash <(curl -sL https://raw.githubusercontent.com/node-red/linux-installers/master/deb/update-nodejs-and-nodered)
sudo systemctl enable nodered
sudo systemctl start nodered

This setup ensures that Node-RED remains available for executing security workflows without manual intervention.

Libraries and Module Configuration

To support cryptographic operations, file handling, and system-level interactions, Node-RED relies on both built-in and external Node.js libraries. The built-in modules include crypto, fs, and os, which provide functionality for encryption, file system access, and system information retrieval, respectively.

In addition, the external library jsonwebtoken is installed on all devices to support JSON Web Token (JWT) generation and verification.

cd ~/.node-red
npm install jsonwebtoken

These libraries are later exposed to Node-RED function nodes through global configuration, enabling secure processing within flows.

Environment Variable Configuration

Sensitive configuration parameters are managed using environment variables defined in the settings.js file. This approach prevents hardcoding secrets directly into Node-RED flows and improves overall security and flexibility.

process.env.DB_PASSWORD    = "your-secure-password";
process.env.CA_URL         = "https://192.168.151.1:8443";
process.env.ROOT_CRT       = "/home/step/.step/certs/root_ca.crt";
process.env.PROV_NAME      = "Admin JWK";
process.env.PROV_PASS_FILE = "/etc/step-ca/secrets/provisioner_password";

These variables are used for database encryption, certificate authority communication, and secure certificate operations.

Secure Access Configuration

To protect access to the Node-RED editor and dashboard, authentication is enabled using credential-based login. User credentials are stored as bcrypt hashes to prevent exposure of plaintext passwords.

adminAuth: {
    type: "credentials",
    users: [{
        username: "admin",
        password: "<bcrypt-hash>",
        permissions: "*"
    }]
},

This ensures that only authorized users can modify flows or access system controls.

HTTPS Configuration

Node-RED is configured to operate over HTTPS to secure all communications between users and the Node-RED interface. TLS certificates and keys are loaded from the filesystem.

https: {
  key: require("fs").readFileSync('/root/.node-red/certs/server.key'),
  cert: require("fs").readFileSync('/root/.node-red/certs/server.crt'),
  ca: require("fs").readFileSync('/root/.node-red/certs/ca.crt')
},
requireHttps: true,

By enforcing HTTPS, all interactions with Node-RED are encrypted, preventing interception or tampering.

Secure Context Storage

Node-RED context storage is configured to use encrypted local filesystem storage. This ensures that sensitive runtime data such as session keys and temporary secrets are protected at rest.

contextStorage: {
  default: {
      module: "localfilesystem",
      config: {
          encrypt: true,
          key: "StrongContextKey123!"
      }
  }
},

This configuration prevents unauthorized access to sensitive data even if the storage files are accessed directly.

Global Library Access

To enable the use of required libraries within Node-RED function nodes, they are exposed through the global context configuration.

functionGlobalContext: {
    crypto: require('crypto'),
    fs: require('fs'),
    os: require('os'),
    jwt: require('jsonwebtoken')
},

This allows flows to perform cryptographic operations, file handling, and token processing directly within function nodes.

Dashboard and Visualization Modules

To support monitoring and management, additional Node-RED modules are installed to provide dashboard functionality and data visualization.

cd ~/.node-red
npm install node-red-dashboard
npm install node-red-node-ui-table

These modules enable the creation of interactive dashboards, including tables for device management, authentication status tracking, and system monitoring.

Service Reliability and Restart

After applying configuration changes, Node-RED is restarted to ensure all settings take effect.

sudo systemctl restart nodered

The systemd service ensures that Node-RED automatically recovers from failures and continues running reliably.

Summary

With these configurations, Node-RED operates as a secure orchestration layer within the system. It provides encrypted communication, protected access control, secure storage of runtime data, and integration with cryptographic and certificate management components. This setup enables the implementation of all higher-level security workflows in the proposed secure MQTT framework.
## Node-RED Flow Folder Structure

This repository organizes Node-RED flows by device role to ensure modular deployment, easy testing, and clear separation of responsibilities. Each device has its own folder containing individual flow files grouped by functionality.

📁 Project Structure
node-red-flows/
│
├── sunny-central-broker/
│   ├── 01-system-setup.json
│   ├── 02-device-registration-handler.json
│   ├── 03-mutual-authentication.json
│   ├── 04-database-sync.json
│   ├── 05-topic-registration-key-handler.json
│   ├── 06-rotation-revocation.json
│   └── 07-dashboard.json
│
├── cookie-bridge-broker/
│   ├── 01-device-registration.json
│   ├── 02-mutual-authentication.json
│   ├── 03-database-sync.json
│   ├── 04-rotation-revocation.json
│   └── 05-mitm-simulation.json
│
├── cake-bridge-broker/
│   ├── 01-device-registration.json
│   ├── 02-mutual-authentication.json
│   ├── 03-database-sync.json
│   └── 04-rotation-revocation.json
│
├── alice-client/
│   ├── 01-device-registration.json
│   ├── 02-mutual-authentication.json
│   ├── 03-database-sync.json
│   ├── 04-rotation-revocation.json
│   ├── 05-baseline-data-transfer.json
│   └── 06-secure-data-transfer-dashboard.json
│
└── bob-mobile-client/
    ├── 01-device-registration.json
    ├── 02-mutual-authentication.json
    ├── 03-database-sync.json
    ├── 04-rotation-revocation.json
    ├── 05-baseline-data-transfer.json
    └── 06-secure-data-transfer-dashboard.json
Flow Description by Device
Central Broker (Sunny)

Handles system-wide coordination and security operations:

Certificate Authority (Step-CA) integration
Device registration handler
Mutual authentication
Database synchronization
Topic key management
Key/token rotation and revocation
Monitoring dashboard
Bridge Broker (Cookie)

Extends network and evaluates security:

Device registration
Mutual authentication
Database synchronization
Rotation and revocation
MITM attack simulation
Bridge Broker (Cake)

Provides standard bridging functionality:

Device registration
Mutual authentication
Database synchronization
Rotation and revocation
Client Device (Alice)

Performs publishing and secure communication:

Device registration
Mutual authentication
Database synchronization
Rotation and revocation
Baseline data transfer
Secure data transfer with dashboard
Mobile Client (Bob)

Similar to Alice with mobile-based operation:

Device registration
Mutual authentication
Database synchronization
Rotation and revocation
Baseline data transfer
Secure data transfer
How to Import Flows

Each .json file represents a Node-RED flow and can be imported individually.

Open Node-RED editor
Click Menu → Import
Select the corresponding .json file
Deploy the flow

Flows should be imported in order (01 → 06/07) to ensure dependencies are satisfied.

Notes for Reviewers
Each folder represents one physical device in the architecture
Flows are modular and can be tested independently
Numbering reflects execution order and dependency
Central broker flows must be deployed first
Bridge and client flows connect dynamically via MQTT
Summary

This folder structure ensures:

Clear separation of device responsibilities
Modular testing and debugging
Easy deployment and reproducibility
Reviewer-friendly navigation of system workflows
