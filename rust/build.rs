extern crate cbindgen;

use std::env;
use std::fs::File;
use std::io::prelude::*;
use std::path::Path;

fn main() {
  let crate_dir = env::var("CARGO_MANIFEST_DIR").unwrap();

  cbindgen::generate(&crate_dir)
    .expect("Unable to generate bindings")
    .write_to_file("target/include/cardano.h");
}
