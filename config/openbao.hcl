# Benutzeroberfläche aktivieren
ui = true

# Speicher-Backend (Integrated Storage / Raft)
storage "raft" {
  path    = "/openbao/file"
  node_id = "node-1"
}

# HTTP / TCP Listener
listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = true # Für Produktion: TLS aktivieren!
}

# Cluster / API Adresse (wichtig für Raft)
api_addr     = "http://127.0.0.1:8200"
cluster_addr = "http://127.0.0.1:8201"

# Maximale Lease-Zeiten
default_lease_ttl = "168h"
max_lease_ttl     = "720h"