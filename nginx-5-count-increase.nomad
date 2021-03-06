job "nginx" {
  datacenters = ["dc1"]
  type = "service"

  group "nginx" {
    count = 100

    vault {
      policies = ["frontend"]
    }

    task "nginx" {
      driver = "docker"

      config {
        image = "nginx"
        port_map {
          http = 80
        }
        volumes = [
          "custom/default.conf:/etc/nginx/conf.d/default.conf"
        ]
      }

      template {
        data = <<EOH
          server {
            location / {
              root /local/data/;
            }
          }
        EOH

        destination = "custom/default.conf"
      }

      template {
        data = <<EOH
          {{ if keyExists "features/motd" }}
            {{ key "features/motd" }}
          {{ else }}
            Good morning.
          {{ end }}
          {{ with secret "secret/motd" }}
          {{ .Data.message }}{{ end }}
        EOH

        destination = "local/data/index.html"
      }

      resources {
        cpu    = 100 # 100 MHz
        memory = 128 # 128 MB
        network {
          mbits = 10
          port "http" {}
        }
      }

      service {
        name = "nginx"
        tags = ["frontend","urlprefix-/nginx strip=/nginx"]
        port = "http"
        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
