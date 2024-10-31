# GUYNOTE: 
# var.azure_public_ip_1 =  azurerm_public_ip.azure_vpn_gateway_public_ip_1.ip_address
# var.azure_public_ip_2 = azurerm_public_ip.azure_vpn_gateway_public_ip_2.ip_address

# GCP existing network
data "google_compute_network" "gcp_vpn_network" {
  name = var.gcp_vpc_name
}

resource "google_compute_router" "vpn_router" {
  name    = "vpn-router"
  network = var.gcp_vpc_name

  bgp {
    asn               = var.gcp_bgp_asn
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]
  }
}

# GCP HA VPN gateway
resource "google_compute_ha_vpn_gateway" "target_gateway" {
  name    = "vpn-gcp-azure"
  network = var.gcp_vpc_name
}

resource "google_compute_external_vpn_gateway" "azure_gateway" {
  name            = "azure-gateway"
  redundancy_type = "TWO_IPS_REDUNDANCY"
  description     = "VPN gateway on Azure side"

  interface {
    id         = 0
    # ip_address = azurerm_public_ip.azure_vpn_gateway_public_ip_1.ip_address
    ip_address = var.azure_public_ip_1

  }

  interface {
    id         = 1
    # ip_address = azurerm_public_ip.azure_vpn_gateway_public_ip_2.ip_address
    ip_address = var.azure_public_ip_2
  }
}

# GCP HA VPN Tunnels
resource "google_compute_vpn_tunnel" "tunnel_1" {
  name                            = "ha-azure-vpn-tunnel-1"
  vpn_gateway                     = google_compute_ha_vpn_gateway.target_gateway.self_link
  shared_secret                   = var.shared_secret
  peer_external_gateway           = google_compute_external_vpn_gateway.azure_gateway.self_link
  peer_external_gateway_interface = 0
  router                          = google_compute_router.vpn_router.name
  ike_version                     = 2
  vpn_gateway_interface           = 0
}

resource "google_compute_vpn_tunnel" "tunnel_2" {
  name                            = "ha-azure-vpn-tunnel-2"
  vpn_gateway                     = google_compute_ha_vpn_gateway.target_gateway.self_link
  shared_secret                   = var.shared_secret
  peer_external_gateway           = google_compute_external_vpn_gateway.azure_gateway.self_link
  peer_external_gateway_interface = 1
  router                          = google_compute_router.vpn_router.name
  ike_version                     = 2
  vpn_gateway_interface           = 1
}

resource "google_compute_router_interface" "router1_interface1" {
  name       = "interface-1"
  router     = google_compute_router.vpn_router.name
  ip_range   = "169.254.21.2/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel_1.name
}

resource "google_compute_router_peer" "router1_peer1" {
  name                      = "peer-1"
  router                    = google_compute_router.vpn_router.name
  peer_ip_address           = "169.254.21.1"
  peer_asn                  = "65515"
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.router1_interface1.name
}

resource "google_compute_router_interface" "router1_interface2" {
  name       = "interface-2"
  router     = google_compute_router.vpn_router.name
  ip_range   = "169.254.22.2/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel_2.name
}

resource "google_compute_router_peer" "router1_peer2" {
  name                      = "peer-2"
  router                    = google_compute_router.vpn_router.name
  peer_ip_address           = "169.254.22.1"
  peer_asn                  = "65515"
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.router1_interface2.name
}