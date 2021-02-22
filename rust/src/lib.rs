pub mod address;
pub mod error;
pub mod string;
pub mod data;
mod ptr;
mod panic;

#[no_mangle]
pub unsafe extern "C" fn cardano_initialize() {
    panic::hide_exceptions();
}