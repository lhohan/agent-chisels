default:
  @just --list

test:
  cd cli-tests && cargo test
