# Question

Solve this question on: `terminal`

The application `crowded` exposes the counter `lab_http_requests_total` with two labels: `path` (three values: `/orders`, `/cart`, `/search`) and `request_id` (100 values per path, so 300 series). Prometheus already scrapes it in the job `crowded`. Nobody queries a single `request_id`, and the label makes dashboards slow.

Add one rule group to the ConfigMap `prometheus-rules` (key `rules.yaml`, empty now) with three recording rules. Do not change the scrape configuration.

1. `path:lab_http_requests_total:sum`: the sum of the counter for each `path`, with no other label.
2. `path:lab_http_requests_total:series`: the number of series that exist for each `path`, with no other label.
3. `lab:shop_requests:sum`: one value with no labels: the sum of the counter for the paths `/orders` and `/cart` only, selected with one regular expression label matcher.

Make Prometheus read the changed file before you submit.

`kubectl` already points at the cluster as the cluster administrator.
