## Important Announcement ⚠️

**Xcode 13** provides test repetitions out of the box. For more details check out [WWDC21](https://developer.apple.com/videos/play/wwdc2021/10296).

---

# try_scan plugin

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-try_scan)

## About try_scan

The easiest way to rerun tests of your iOS and Mac app 🚀

Under the hood `try_scan` uses official [`fastlane scan action`](https://docs.fastlane.tools/actions/scan/), it means that you are able to provide any `scan` options and use `Scanfile` as before — everything will work like a charm, `try_scan` just brings couple of new amazing options:

| Option | Description | Default |
| ------- |------------ | ------- |
| try_count | Number of times to try to get your tests green | 1 |
| try_parallel | Should first run be executed in parallel? Equivalent to `-parallel-testing-enabled` | true |
| retry_parallel | Should subsequent runs be executed in parallel? Required `try_parallel: true` | true |
| parallel_workers | Specify the exact number of test runners that will be spawned during parallel testing. Equivalent to `-parallel-testing-worker-count` and `concurrent_workers` |  |
| retry_build | Should building be retried after failure? | false |
| retry_strategy | What would you like to retry after failure: test, class or suite? | test |
| backup | Back up an output of each execution to a separate folder | false |

## Requirements

* Xcode 11.x or greater. Download it at the [Apple Developer - Downloads](https://developer.apple.com/downloads) or the [Mac App Store](https://apps.apple.com/us/app/xcode/id497799835?mt=12).

## Getting Started

To get started with `try_scan`, add it to your project by running:

```bash
$ fastlane add_plugin try_scan
```

## Usage

```ruby
try_scan(
  workspace: "Example.xcworkspace",
  device: "iPhone 11 Pro Max",
  try_count: 3,
  parallel_workers: 2,
  try_parallel: true,
  retry_parallel: false
)
```
