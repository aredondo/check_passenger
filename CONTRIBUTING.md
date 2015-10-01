# Contribution Guidelines

1. Fork this repository (https://github.com/aredondo/check_passenger/fork). The repository follows the [Git Flow branching model](http://nvie.com/posts/a-successful-git-branching-model/) so when forking, please do so from the `develop` branch, as there may be commits that have still not made it to `master`.
2. Create your feature branch: `git checkout -b feature/my-new-feature`
3. Commit your changes
4. Make sure that all the tests pass: `rake test`
5. Run Rubocop to confirm that it does not raise any warnings
6. Make sure to update [CHANGELOG.md](CHANGELOG.md) to list your changes. Also, update [README.md](README.md) if necessary. Please, do not update the gem version.
7. Push to the branch: `git push origin feature/my-new-feature`
8. Create a new Pull Request

Thanks!
