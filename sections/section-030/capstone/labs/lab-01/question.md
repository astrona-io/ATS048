# Question

Solve this question on: `terminal`

Prometheus in `starfleet` scrapes the application `crowded` (`crowded:8080`) in the job `crowded`. The application exposes one `lab_ticket_info` series per open ticket, with a `ticket_id` label, and the number grows with every ticket. Prometheus runs with the default retention and without any limit on the job.

Make the server safe against this growth:

1. Keep sample data for at most 12 hours and cap the disk space of blocks at 1GB. Keep every flag that is already set.
2. Limit the job `crowded` to 100 samples per scrape. Today the target has 200 series, so with the limit the scrape must fail and store nothing.

Do not change the application or the other jobs. Make sure the new pod runs with the new flags and configuration before you submit.

`kubectl` already points at the cluster as the cluster administrator.
