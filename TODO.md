# Release

- Cache parsed data to avoid calling `passenger-status` multiple times in rapid
  succession.
- README page.
- Automatically save the output of `passenger-status` when it cannot be
  processed.
- Handle exceptions to show the corresponding error on the command line.
- Fix versions of gems.


# Other

- Option `all` to monitor all counters for all applications and globally,
  without possibility to raise alerts.
