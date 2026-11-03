# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-040/module-02/labs/lab-01
```

Submit once before you change anything. All four checks fail, because no rule exists.

## Step 1: Count the series

The unit of storage in Prometheus is the time series: one metric name plus one set of label values. The counter `lab_http_requests_total` has 300 series, because every pair of `path` and `request_id` is different. Count them with a query:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=count(lab_http_requests_total)'
```

The value is 300. Now count by path:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=count%20by%20(path)%20(lab_http_requests_total)'
```

The answer has three series with the value 100. The `%20` sequences are URL-encoded spaces, which the query string needs. This `count by` expression is what the second rule records.

## Step 2: Choose the aggregation

An aggregation operator such as `sum` or `count` combines many series into fewer. `by (path)` keeps the label `path` and drops all other labels, including `job` and `instance`. The opposite form is `without (request_id)`, which keeps all labels except the listed ones. The question asks for the `path` label only, so use `by (path)`.

`sum` adds the sample values. In this application the counters of one path hold the values 1 to 100, so the sum is 5050 for each path. `count` ignores the values and counts the series.

The third rule needs a selector. A selector in braces narrows a metric to the series with matching labels. The operator `=~` matches a regular expression, which is fully anchored, so `/orders|/cart` matches exactly those two values and nothing else. `!=` and `!~` are the negated forms.

## Step 3: Write the rules

Save this as `rules-labels.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-rules
  namespace: starfleet
data:
  rules.yaml: |
    groups:
    - name: lab_labels
      interval: 5s
      rules:
      - record: path:lab_http_requests_total:sum
        expr: sum by (path) (lab_http_requests_total)
      - record: path:lab_http_requests_total:series
        expr: count by (path) (lab_http_requests_total)
      - record: lab:shop_requests:sum
        expr: sum(lab_http_requests_total{path=~"/orders|/cart"})
```

Apply it and restart Prometheus so it loads the rule file:

```sh
kubectl apply -f rules-labels.yaml
kubectl -n starfleet rollout restart deployment/prometheus
kubectl -n starfleet rollout status deployment/prometheus
```

## Step 4: Check the series

Wait about 20 seconds so that Prometheus scrapes and evaluates the group. Then query:

```sh
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=path:lab_http_requests_total:sum'
kubectl -n starfleet exec shuttle -- wget -qO- 'http://prometheus:9090/api/v1/query?query=lab:shop_requests:sum'
```

The first answer has three series, each with the labels `__name__` and `path` and the value 5050. The second has one series with the value 10100, which is 5050 plus 5050.

The recorded series are small. A dashboard that reads `path:lab_http_requests_total:sum` reads 3 series instead of 300. The raw series still exist and still cost memory, because a rule does not remove its input.

## Step 5: Submit

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS048.git -c sections/section-040/module-02/labs/lab-01 --keep
```

Four checks must pass.

## What each check proved

- `path-totals` compared the exact paths and values and required that `request_id`, `job` and `instance` are gone.
- `path-series-count` required the value 100 for each path. A `sum` instead of a `count` gives 5050 and fails.
- `shop-selector` required 10100 and no labels. Selecting with `path!="/search"` also gives 10100, so the question names the matcher type to make the rule explicit.
- `rules-healthy` required all three rules to be loaded and healthy.

## If a check fails

- If a total is wrong, check that the rule does not use `rate`. The counter is constant in this application, and the question asks for sums of the stored values.
- If the `shop` value is 15150, the matcher includes `/search`. A regular expression label matcher is anchored, so list the two values exactly.
