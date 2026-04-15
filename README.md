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

This system implements a **multi-hop secure MQTT network** where a **central broker (Sunny)** connects to two **bridge brokers (Cookie and Cake)**, each extending connectivity to downstream client networks.

Each node functions as:

* **Access Point (AP)** using `hostapd`
* **DHCP server** for its subnet
* **Router/NAT gateway** for traffic forwarding

---

## 🧱 Topology Structure

```text
                  [ Network-01 ]            [ Network-02 ]
                         \                      /
                          \                    /
                         [   Sunny (Central Broker)   ]
                          /                    \
                         /                      \
              [ Cookie (Bridge Broker) ]   [ Cake (Bridge Broker) ]
                      |                          |
                 [ Network-A ]              [ Network-B ]
                      |                          |
                  [ Alice ]                  [ Bob ]
```

---

## 🌍 Network Segmentation

### 🔹 Central Layer (Sunny - Ubuntu VM)

* **Network-01 → 192.168.151.0/24**
* **Network-02 → 192.168.152.0/24**

Sunny acts as:

* MQTT **Central Broker**
* **Certificate Authority (CA)**
* **Routing controller**
* Internet gateway

---

### 🔹 Bridge Layer

#### 🟢 Cookie (Raspberry Pi 4)

* **Uplink:** Network-01 or Network-02 (from Sunny)
* **Downlink:** Network-A → `192.168.153.0/24`
* Acts as:

  * MQTT **Bridge Broker**
  * AP for Network-A
  * DHCP server + router

#### 🔵 Cake (Raspberry Pi 4)

* **Uplink:** Network-02 (from Sunny)
* **Downlink:** Network-B → `192.168.154.0/24`
* Acts as:

  * MQTT **Bridge Broker**
  * AP for Network-B
  * DHCP server + router

---

## 📡 Wireless SSIDs (hostapd)

| Node   | SSID       | Interface | Subnet           |
| ------ | ---------- | --------- | ---------------- |
| Sunny  | Network-01 | wlanX     | 192.168.151.0/24 |
| Sunny  | Network-02 | wlanY     | 192.168.152.0/24 |
| Cookie | Network-A  | wlan1     | 192.168.153.0/24 |
| Cake   | Network-B  | wlan1     | 192.168.154.0/24 |

---

## 📦 DHCP Allocation

Each node serves DHCP for its local network:

* **Sunny**

  * 192.168.151.10 – 100
  * 192.168.152.10 – 100

* **Cookie**

  * 192.168.153.10 – 100

* **Cake**

  * 192.168.154.10 – 100

Each DHCP config includes:

* Default gateway = local AP IP
* DNS = 8.8.8.8 / 8.8.4.4

---

## 🔁 Routing & NAT Design

### 🔹 Sunny (Central Router)

* Enables:

  * `net.ipv4.ip_forward=1`
* Performs:

  * NAT via `iptables`
* Handles:

  * Traffic between Network-01 ↔ Network-02
  * Internet access for all downstream networks

---

### 🔹 Cookie & Cake (Intermediate Routers)

* Perform:

  * Packet forwarding between uplink and local subnet
* Use:

  * NAT (`MASQUERADE`) for client internet access

---

## 📜 Routing Automation

Routing is centrally controlled using scripts on **Sunny**:

* `update-routes.sh`
* `update-route-services`

### 🔧 Purpose

* Dynamically update routing tables
* Maintain connectivity across:

  * Network-A ↔ Network-B
  * All nodes ↔ Central Broker
* Ensure stable multi-hop communication

---

## 🔄 End-to-End Data Flow

### Example (Alice → Bob):

```text
Alice → Cookie → Sunny → Cake → Bob
```

### MQTT Communication:

```text
Client → Bridge Broker → Central Broker → Bridge Broker → Client
```

---

## 🔐 Architecture Characteristics

* Multi-hop wireless topology
* Distributed AP-based network expansion
* Centralized MQTT security control (Sunny)
* Bridge-based message forwarding
* Segmented and isolated subnets
* Scalable and modular design

---

## ⚠️ Important Notes

* All nodes must:

  * Enable IP forwarding
  * Apply correct `iptables` rules
* Interface names (`wlan0`, `wlan1`, etc.) may vary per device
* Routing scripts must run at startup on Sunny
* Bridge brokers must maintain stable connection to central broker
