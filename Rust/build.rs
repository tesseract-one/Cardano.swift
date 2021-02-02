extern crate cbindgen;

use std::env;
use std::fs::File;
use std::io::prelude::*;
use std::path::Path;

fn main() {
  let crate_dir = env::var("CARGO_MANIFEST_DIR").unwrap();

  cbindgen::generate(&crate_dir)
    .expect("Unable to generate bindings")
    .write_to_file("include/cardano.h");

  // let mut file = File::create(&Path::new("include/keychain_build_config.h")).unwrap();
  // file.write_all(b"/* Library built with these features: */\n\n").unwrap();
  // #[cfg(feature = "cardano")]
  // {
  //   file.write_all(b"#define WITH_FEATURE_CARDANO\t1\n").unwrap();
  // }
  // #[cfg(feature = "ethereum")]
  // {
  //   file.write_all(b"#define WITH_FEATURE_ETHEREUM\t1\n").unwrap();
  // }
  // #[cfg(feature = "bitcoin")]
  // {
  //   file.write_all(b"#define WITH_FEATURE_BITCOIN\t1\n").unwrap();
  // }
  // #[cfg(feature = "backup")]
  // {
  //   file.write_all(b"#define WITH_FEATURE_BACKUP\t\t1\n").unwrap();
  // }
}
