output "subnets" {
  value       = google_compute_subnetwork.subnetwork
  description = "The created subnet resources"
}

output "subnets_self_links" {
  value = [for network in google_compute_subnetwork.subnetwork : network.self_link]
}