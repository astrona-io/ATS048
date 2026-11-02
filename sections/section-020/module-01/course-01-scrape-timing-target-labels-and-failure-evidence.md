---
draft: true
exam_objectives:
- Configuration and Scraping
---
# Scrape Timing, Target Labels And Failure Evidence

A scrape job describes how Prometheus collects metrics from a selected group of targets. It combines target selection, transport settings, timing and labels. A coherent configuration provides useful identity and bounded collection without assuming that every endpoint uses the same path, protocol or authentication mechanism.

## Defaults And Job-Specific Settings

Global settings provide defaults such as the scrape interval and timeout. A job can override applicable values for its targets. The interval describes how often collection is scheduled, while the timeout bounds how long an attempt may take. A supported timeout must fit the scheduling contract rather than create an indefinitely overlapping collection process.

The rule evaluation interval is separate. Faster scraping does not automatically make every alert evaluate at the same frequency, and faster dashboard refresh does not create more source observations. Explain each timing value according to its owner. Choosing very short intervals increases request and ingestion costs and should serve a meaningful observation requirement.

## Endpoint And Transport Selection

The effective address, scheme and metrics path determine where a scrape request goes. A service exposing business traffic at one path may expose metrics at another port or path. TLS configuration establishes transport protection and peer validation, while authentication settings provide permitted access where required. Avoid weakening certificate checks merely to hide an incorrectly configured endpoint.

A target can be discovered yet unreachable because of network policy, routing or a listener mismatch. It can be reachable yet rejected by authentication. It can return data that fails format parsing. These stages produce different evidence and need different corrections. A generic timeout does not identify which underlying relationship is wrong.

## Labels Establish Sample Identity

The job label groups targets under a collection responsibility. The instance label normally identifies the target address unless configuration changes it. Additional target labels can identify ownership or environment. Because labels form series identity, changing them creates different series rather than rewriting the identity of historical samples.

An exporter can expose labels that conflict with labels assigned by the scraper. The honor_labels setting affects conflict handling. Its choice should preserve the intended authority over identity, especially when collecting data from gateways or federated sources. A producer-controlled label should not silently impersonate another target because the configuration ignored the conflict model.

## Interpret Scrape Health

Prometheus generates scrape-related observations including up and duration or sample counts. An up value of zero indicates a failed scrape for the selected target. It does not prove that the application's user traffic failed. A metrics handler can fail independently, and a network restriction can affect the scraper without affecting customer clients.

An absent current target series can instead reflect discovery removal, changed labels or historical staleness. Do not equate absence with the numerical value zero. Review the effective target list and identity before changing an alert expression to substitute values that obscure missing coverage.

## Diagnose In Pipeline Order

For a failed scrape, identify the selected target and effective address first. Then examine protocol, path, credentials, network access and format validity. Compare the timeout to the endpoint's expected response behavior. If a collector lacks permission to discover the target, adjusting its HTTP timeout will not repair the missing candidate. A correction should restore the intended secure collection path and retain enough identity to distinguish target-specific failures.

## Common pitfalls

> [!WARNING]
> Scrape interval, timeout, rule evaluation and dashboard refresh are different clocks. A failed scrape is a collection-path observation, while absence and application downtime require separate reasoning.
