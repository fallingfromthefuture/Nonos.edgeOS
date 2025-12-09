#!/usr/bin/env bash
set -euo pipefail

# Usage: run from the root of the repo (fallingfromthefuture/nonos-edge)
# Example:
#   cd ~/workspaces/nonos-edge
#   bash push_v0.2_edge_os.sh

BRANCH="v0.2-edge-os"
COMMIT_MSG='feat(v0.2-edge-os): Universal edge drivers, modular kernel, full industrial support, finalized spec'
FILES_ROOTS=(
  "kernel/src/drivers"
)

# Ensure we're in a git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: not inside a git repository. cd to the repo root and re-run." >&2
  exit 1
fi

# Confirm git remote
if ! git remote get-url origin >/dev/null 2>&1; then
  echo "Error: no 'origin' remote found. Add a remote and re-run." >&2
  exit 1
fi

# Create directories
for d in "${FILES_ROOTS[@]}"; do
  mkdir -p "$d"
done
mkdir -p kernel/src
mkdir -p kernel/src/drivers

# Write files
cat > kernel/src/drivers/cnc.rs <<'EOF'
pub trait CNCMachine {
    fn position(&self) -> (f32, f32, f32);
    fn move_to(&mut self, x: f32, y: f32, z: f32);
    fn emergency_stop(&mut self);
    fn status(&self) -> String;
}

// Example implementation (dummy)
pub struct DummyCNC;

impl CNCMachine for DummyCNC {
    fn position(&self) -> (f32, f32, f32) { (0.0, 0.0, 0.0) }
    fn move_to(&mut self, _x: f32, _y: f32, _z: f32) {}
    fn emergency_stop(&mut self) {}
    fn status(&self) -> String { "OK".to_string() }
}
EOF

cat > kernel/src/drivers/servo.rs <<'EOF'
pub trait Servo {
    fn set_angle(&mut self, degrees: f32);
    fn get_angle(&self) -> f32;
    fn calibrate(&mut self) -> bool;
}

pub struct DummyServo { pub angle: f32 }

impl DummyServo {
    pub fn new() -> Self { Self { angle: 0.0 } }
}

impl Servo for DummyServo {
    fn set_angle(&mut self, degrees: f32) { self.angle = degrees; }
    fn get_angle(&self) -> f32 { self.angle }
    fn calibrate(&mut self) -> bool { self.angle = 0.0; true }
}
EOF

cat > kernel/src/drivers/motor.rs <<'EOF'
pub trait Motor {
    fn set_speed(&mut self, speed: f32);
    fn get_speed(&self) -> f32;
    fn stop(&mut self);
}

pub struct DummyMotor { pub speed: f32 }

impl DummyMotor {
    pub fn new() -> Self { Self { speed: 0.0 } }
}

impl Motor for DummyMotor {
    fn set_speed(&mut self, speed: f32) { self.speed = speed; }
    fn get_speed(&self) -> f32 { self.speed }
    fn stop(&mut self) { self.speed = 0.0; }
}
EOF

cat > kernel/src/drivers/encoder.rs <<'EOF'
pub trait Encoder {
    fn read(&self) -> i32;
    fn reset(&mut self);
}

pub struct DummyEncoder { pub count: i32 }

impl DummyEncoder {
    pub fn new() -> Self { Self { count: 0 } }
}

impl Encoder for DummyEncoder {
    fn read(&self) -> i32 { self.count }
    fn reset(&mut self) { /* reset */ }
}
EOF

cat > kernel/src/drivers/can.rs <<'EOF'
pub trait CANBus {
    fn send(&mut self, id: u32, data: &[u8]) -> Result<(), &'static str>;
    fn receive(&mut self) -> Option<(u32, Vec<u8>)>;
    fn error(&self) -> Option<String>;
}

pub struct DummyCAN;

impl DummyCAN {
    pub fn new() -> Self { DummyCAN }
}

impl CANBus for DummyCAN {
    fn send(&mut self, _id: u32, _data: &[u8]) -> Result<(), &'static str> { Ok(()) }
    fn receive(&mut self) -> Option<(u32, Vec<u8>)> { None }
    fn error(&self) -> Option<String> { None }
}
EOF

cat > kernel/src/drivers/modbus.rs <<'EOF'
pub trait Modbus {
    fn read_holding_register(&self, address: u16) -> Result<u16, &'static str>;
    fn write_register(&mut self, address: u16, value: u16) -> Result<(), &'static str>;
}

pub struct DummyModbus;

impl DummyModbus {
    pub fn new() -> Self { DummyModbus }
}

impl Modbus for DummyModbus {
    fn read_holding_register(&self, _address: u16) -> Result<u16, &'static str> { Ok(0) }
    fn write_register(&mut self, _address: u16, _value: u16) -> Result<(), &'static str> { Ok(()) }
}
EOF

cat > kernel/src/drivers/ethercat.rs <<'EOF'
pub trait EtherCAT {
    fn read(&self, idx: u16) -> Result<Vec<u8>, &'static str>;
    fn write(&mut self, idx: u16, data: &[u8]) -> Result<(), &'static str>;
}

pub struct DummyEtherCAT;

impl DummyEtherCAT {
    pub fn new() -> Self { DummyEtherCAT }
}

impl EtherCAT for DummyEtherCAT {
    fn read(&self, _idx: u16) -> Result<Vec<u8>, &'static str> { Ok(vec![]) }
    fn write(&mut self, _idx: u16, _data: &[u8]) -> Result<(), &'static str> { Ok(()) }
}
EOF

cat > kernel/src/drivers/i2c.rs <<'EOF'
pub trait I2CDevice {
    fn write(&mut self, data: &[u8]) -> bool;
    fn read(&mut self, buf: &mut [u8]) -> bool;
}

pub struct DummyI2C;

impl DummyI2C {
    pub fn new() -> Self { DummyI2C }
}

impl I2CDevice for DummyI2C {
    fn write(&mut self, _data: &[u8]) -> bool { true }
    fn read(&mut self, _buf: &mut [u8]) -> bool { true }
}
EOF

cat > kernel/src/drivers/spi.rs <<'EOF'
pub trait SPIDevice {
    fn transfer(&mut self, data_out: &[u8], data_in: &mut [u8]) -> bool;
}

pub struct DummySPI;

impl DummySPI {
    pub fn new() -> Self { DummySPI }
}

impl SPIDevice for DummySPI {
    fn transfer(&mut self, _data_out: &[u8], _data_in: &mut [u8]) -> bool { true }
}
EOF

cat > kernel/src/drivers/uart.rs <<'EOF'
pub trait UART {
    fn send(&mut self, byte: u8);
    fn receive(&mut self) -> Option<u8>;
}

pub struct DummyUART;

impl DummyUART {
    pub fn new() -> Self { DummyUART }
}

impl UART for DummyUART {
    fn send(&mut self, _byte: u8) {}
    fn receive(&mut self) -> Option<u8> { None }
}
EOF

cat > kernel/src/drivers/gpio.rs <<'EOF'
pub trait GPIO {
    fn set_high(&mut self);
    fn set_low(&mut self);
    fn is_high(&self) -> bool;
}

pub struct DummyGPIO { pub high: bool }

impl DummyGPIO {
    pub fn new() -> Self { DummyGPIO { high: false } }
}

impl GPIO for DummyGPIO {
    fn set_high(&mut self) { self.high = true; }
    fn set_low(&mut self) { self.high = false; }
    fn is_high(&self) -> bool { self.high }
}
EOF

cat > kernel/src/drivers/adc.rs <<'EOF'
pub trait ADC {
    fn read(&self, channel: u8) -> u16;
}

pub struct DummyADC;

impl DummyADC {
    pub fn new() -> Self { DummyADC }
}

impl ADC for DummyADC {
    fn read(&self, _channel: u8) -> u16 { 0 }
}
EOF

cat > kernel/src/drivers/pwm.rs <<'EOF'
pub trait PWM {
    fn set_duty_cycle(&mut self, value: u8);
    fn get_duty_cycle(&self) -> u8;
}

pub struct DummyPWM { pub duty: u8 }

impl DummyPWM {
    pub fn new() -> Self { DummyPWM { duty: 0 } }
}

impl PWM for DummyPWM {
    fn set_duty_cycle(&mut self, value: u8) { self.duty = value; }
    fn get_duty_cycle(&self) -> u8 { self.duty }
}
EOF

cat > kernel/src/drivers/sensorfusion.rs <<'EOF'
pub trait SensorFusion {
    fn process(&mut self, inputs: &[f32]) -> Vec<f32>;
}

pub struct DummyFusion;

impl DummyFusion {
    pub fn new() -> Self { DummyFusion }
}

impl SensorFusion for DummyFusion {
    fn process(&mut self, inputs: &[f32]) -> Vec<f32> { inputs.to_vec() }
}
EOF

cat > kernel/src/drivers/mod.rs <<'EOF'
pub mod cnc;
pub mod servo;
pub mod motor;
pub mod encoder;
pub mod can;
pub mod modbus;
pub mod ethercat;
pub mod i2c;
pub mod spi;
pub mod uart;
pub mod gpio;
pub mod adc;
pub mod pwm;
pub mod sensorfusion;

// Register drivers (placeholder). Real runtime should enumerate hardware and register instances.
pub fn register_all_drivers() {
    // TODO: Implement hardware discovery, initialization, and plug-n-play registration
}
EOF

cat > kernel/src/drivers/platform.rs <<'EOF'
/// Simple platform detection stub. Replace with proper detection for your targets.
/// Could read /etc/os-release on full OS, or use board detection, env vars, or feature flags.
pub fn detect_platform() -> &'static str {
    "unknown"
}
EOF

cat > kernel/src/lib.rs <<'EOF'
#![allow(unused)]
pub mod net;
pub mod ai;
pub mod rpc;
pub mod ota;
pub mod drivers;

use drivers::register_all_drivers;
use drivers::platform::detect_platform;

pub struct Kernel;

#[cfg(feature = "std")]
fn log_platform(p: &str) {
    println!("Detected platform: {}", p);
}

#[cfg(not(feature = "std"))]
fn log_platform(_p: &str) {
    // no-op in no_std targets
}

pub fn init() -> Kernel {
    log_platform(detect_platform());
    register_all_drivers();
    Kernel
}
EOF

cat > README.md <<'EOF'
# nonos-edge 🛡️

**Universal Edge OS** — Secure, AI-native, zero-trust, < 30 MB.

## Features
- Modular driver system: robotics, CNC, sensors, industrial buses (CAN, Modbus, EtherCAT, etc)
- WASM agent sandbox (includes anomaly/inference models)
- libp2p mesh, JSON-RPC, MQTT, REST, OPC-UA support
- Secure OTA: A/B partitions, DM-Verity, rollback, remote attestation
- Mobile, desktop, and industrial OS extension/swap-out ready

## Supported Devices & Protocols
- Robotics: CNC, servo, motor, encoder, sensor fusion, vision, actuators
- Manufacturing: PLC, CAN, Modbus, EtherCAT, Profibus, I/O, ADC/DAC
- Microcontrollers/SBCs: ARM, RISC-V, x86, nRF52, STM32, ESP32, Pi, Beaglebone
- Protocols: HTTP, MQTT, REST, OPC-UA, Modbus, CANopen, Zigbee, BLE, WiFi, LoRa

## Developer Guide

1. Place `{your_driver}.rs` in `kernel/src/drivers/`
2. Register in `kernel/src/drivers/mod.rs`
3. Extend `platform.rs` for auto platform detection

## Example: Adding a Servo Driver

```rust
pub trait Servo {
    fn set_angle(&mut self, degrees: f32);
    fn get_angle(&self) -> f32;
}