resource "datadog_dashboard" "ec2_dashboard" {
  title       = "LTI Project - EC2 Monitoring Dashboard"
  description = "Dashboard para monitorizar las instancias EC2 lti-project-backend y lti-project-frontend"
  layout_type = "ordered"

  widget {
    timeseries_definition {
      title = "CPU Utilization"
      request {
        q            = "avg:system.cpu.user{project:lti-project} by {host}"
        display_type = "line"
      }
    }
  }

  widget {
    timeseries_definition {
      title = "Network In"
      request {
        q            = "avg:system.net.bytes_rcvd{project:lti-project} by {host}"
        display_type = "line"
      }
    }
  }

  widget {
    timeseries_definition {
      title = "Network Out"
      request {
        q            = "avg:system.net.bytes_sent{project:lti-project} by {host}"
        display_type = "line"
      }
    }
  }

  widget {
    timeseries_definition {
      title = "Disk Read Ops"
      request {
        q            = "avg:system.io.r_s{project:lti-project} by {host}"
        display_type = "line"
      }
    }
  }

  widget {
    timeseries_definition {
      title = "Disk Write Ops"
      request {
        q            = "avg:system.io.w_s{project:lti-project} by {host}"
        display_type = "line"
      }
    }
  }

  widget {
    timeseries_definition {
      title = "Agent Running"
      request {
        q            = "avg:datadog.agent.running{project:lti-project} by {host}"
        display_type = "bars"
      }
    }
  }
}
