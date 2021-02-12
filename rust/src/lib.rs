use cardano_serialization_lib;

#[no_mangle]
pub extern "C" fn hello_from_rust() -> bool {
  println!("Hello from Rust!");
  return true;
}
