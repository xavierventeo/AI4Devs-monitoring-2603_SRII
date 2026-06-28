resource "datadog_dashboard" "ec2_dashboard" {
  title       = "LTI Project - EC2 Monitoring Dashboard"
  description = "Dashboard para monitorizar las instancias EC2 lti-project-backend y lti-project-frontend"
  layout_type = "ordered"

  widget {
    timeseries_definition {
      title = "CPU Utilization"
      request {
        q            = "avg:aws.ec2.cpuutilization{*} by {instance_id}"
        display_type = "line"
      }
    }
  }

  widget {
    timeseries_definition {
      title = "Network In"
      request {
        q            = "avg:aws.ec2.network_in{*} by {instance_id}"
        display_type = "line"
      }
    }
  }

  widget {
    timeseries_definition {
      title = "Network Out"
      request {
        q            = "avg:aws.ec2.network_out{*} by {instance_id}"
        display_type = "line"
      }
    }
  }

  widget {
    timeseries_definition {
      title = "Disk Read Ops"
      request {
        q            = "avg:aws.ec2.disk_read_ops{*} by {instance_id}"
        display_type = "line"
      }
    }
  }

  widget {
    timeseries_definition {
      title = "Disk Write Ops"
      request {
        q            = "avg:aws.ec2.disk_write_ops{*} by {instance_id}"
        display_type = "line"
      }
    }
  }

  widget {
    timeseries_definition {
      title = "Status Check Failed"
      request {
        q            = "avg:aws.ec2.status_check_failed{*} by {instance_id}"
        display_type = "bars"
      }
    }
  }
}
