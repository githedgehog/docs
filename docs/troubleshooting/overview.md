# Troubleshooting

!!! warning ""
    Under construction.

This section provides solutions for common issues encountered when deploying and managing Hedgehog Fabric. The goal is to help you quickly diagnose and resolve problems to minimize downtime and maintain system stability.

---

## **1. Boot and Installation Issues**
- [GRUB rescue mode and missing `normal.mod`](./troubleshooting_grub_rescue.md)
- ONIE installation failures and network discovery issues

---

## **2. Kubernetes and Control Plane Issues**
- Control plane communication failures (Fabric Controller ↔️  Fabric Agent)  
- CRD synchronization issues  
- Kubernetes pod failures or crash loops  

---

## **3. EVPN and BGP Issues**
- BGP session establishment failures  
- Incorrect BGP advertisements or route distribution issues  
- EVPN VXLAN tunnel misconfigurations  

---

## **4. VPC and Overlay Network Issues**
- VPC creation or attachment failures  
- Subnet conflicts and overlapping IP addresses  
- DHCP relay and addressing issues within VPCs  

---

## **5. Redundancy and High Availability**
- MCLAG and ESLAG configuration mismatches  
- Peer link failures and redundancy inconsistencies  
- Traffic blackholing due to loopback or peer link misconfigurations  

---

## **6. Switch and Interface Issues**
- Interface state mismatch (admin vs oper)  
- Port breakout mode misconfiguration  
- ASIC-related packet drops and performance bottlenecks  

---

## **7. External Peering and Border Leaf Issues**
- BGP peer session failures with edge routers  
- Incorrect route advertisements or filtering  
- VLAN tagging issues for external connections  

---

## **8. Performance and Resource Issues**
- High CPU or memory usage on switches  
- Slow convergence times for BGP/EVPN  
- ASIC resource exhaustion (route limits, FDB, etc.)  

---

## **9. Monitoring and Logging**
- Grafana dashboards showing missing or inconsistent data  
- Alloy logs missing or not updating  
- Incorrect log forwarding to external systems  

---

Use the navigation panel to explore each troubleshooting area in detail.
