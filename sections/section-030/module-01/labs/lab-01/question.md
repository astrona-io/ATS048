# Question

Solve this question on: `terminal`

Prometheus runs as the Deployment `prometheus` in `starfleet`, with its data on an `emptyDir` volume. It uses the default retention and the default query limits. The platform team wants bounded storage and bounded queries.

Change the `prometheus` container of the Deployment so that the server starts with these additional flags. Keep every flag that is already there.

1. Keep sample data for at most 6 hours.
2. Also cap the disk space used by blocks at 500MB.
3. Stop queries that run longer than 30 seconds.
4. Reject queries that would load more than 10000000 samples into memory.

Prometheus reads flags only at start, so the new pod must be running before you submit. Do not change the scrape configuration.

`kubectl` already points at the cluster as the cluster administrator.
