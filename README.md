## About

### Design

I have chosen the clone pattern (minimal proxies) for efficient deployment. That makes sense because creating multiple instances of similar contracts can save gas. The use of upgradeable contracts via Initializable and OwnableUpgradeable suggests they wanted the ability to update the factory or curation logic without redeploying, which is a common practice for managing upgrades.

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
make test
```

### Run Coverage

```shell
make coverage
```

### Generate Coverage Report

```shell
make report
```

### Help

```shell
❯ make help
Usage: make [target]

Targets:
  test      Run tests with verbose output
  coverage  Show coverage summary
  report    Generate and open coverage report
  audit     Run security analysis
  clean     Remove build files
  snapshot  Create gas snapshot
```
