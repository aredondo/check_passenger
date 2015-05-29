# Release

- Add summary to command help.
- Raise CRIT alert instead of UNKNOWN when the requested application cannot be
  found.


# Fix

- Handle error:

```
It appears that multiple Passenger instances are running. Please select a
specific one by running:

  passenger-status <PID>

The following Passenger instances are running:
  PID: 1394
  PID: 1413
```

- "1 live processes" should be "1 live process"


# Other

- Option `all` to monitor all counters for all applications and globally,
  without possibility to raise alerts.
- PerfDatum class.
- Option to set TTL used to estimate live processes.
- Option to set TTL of cached data.
