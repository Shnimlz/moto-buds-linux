use std::io;
use std::os::unix::io::RawFd;
use std::process::Command;
use std::time::Duration;

use crate::protocol::{opcode_name, Packet};

pub const BTPROTO_RFCOMM: libc::c_int = 3;
pub const DEFAULT_RFCOMM_CHANNEL: u8 = 16;

#[repr(C)]
struct SockAddrRc {
    rc_family: libc::sa_family_t,
    rc_bdaddr: [u8; 6],
    rc_channel: u8,
}

pub struct MotoBudsConnection {
    fd: RawFd,
    buf: Vec<u8>,
    seq: u16,
}

impl MotoBudsConnection {
    /// Auto-detect paired Moto Buds address or use specified address
    pub fn auto_detect_address() -> io::Result<String> {
        let output = Command::new("bluetoothctl")
            .arg("devices")
            .output()
            .map_err(|e| io::Error::new(io::ErrorKind::NotFound, format!("bluetoothctl failed: {}", e)))?;

        let text = String::from_utf8_lossy(&output.stdout);
        for line in text.lines() {
            let lower = line.to_lowercase();
            if lower.contains("moto buds") || lower.contains("moto-buds") {
                // Format: "Device A0:90:B5:CD:BC:3C moto buds bass"
                let parts: Vec<&str> = line.split_whitespace().collect();
                if parts.len() >= 2 && parts[0] == "Device" {
                    return Ok(parts[1].to_string());
                }
            }
        }

        Err(io::Error::new(
            io::ErrorKind::NotFound,
            "No paired Moto Buds found in bluetoothctl. Please pair your earbuds first or specify --device MAC",
        ))
    }

    /// Parse MAC string "AA:BB:CC:DD:EE:FF" to 6-byte little-endian array
    fn parse_mac(mac: &str) -> io::Result<[u8; 6]> {
        let clean = mac.trim().replace('-', ":");
        let parts: Vec<&str> = clean.split(':').collect();
        if parts.len() != 6 {
            return Err(io::Error::new(
                io::ErrorKind::InvalidInput,
                format!("Invalid Bluetooth MAC address: {}", mac),
            ));
        }

        let mut addr = [0u8; 6];
        for (i, part) in parts.iter().enumerate() {
            let val = u8::from_str_radix(part, 16).map_err(|_| {
                io::Error::new(io::ErrorKind::InvalidInput, format!("Invalid MAC byte: {}", part))
            })?;
            // Bluetooth addresses in sockaddr_rc are reversed (little-endian)
            addr[5 - i] = val;
        }
        Ok(addr)
    }

    /// Connect to Moto Buds on given MAC address and RFCOMM channel (default 16)
    pub fn connect(mac: &str, channel: Option<u8>) -> io::Result<Self> {
        let ch = channel.unwrap_or(DEFAULT_RFCOMM_CHANNEL);
        let bdaddr = Self::parse_mac(mac)?;

        let mut last_err = io::Error::new(io::ErrorKind::Other, "Unknown connection error");

        for attempt in 0..5 {
            if attempt > 0 {
                std::thread::sleep(Duration::from_millis(300));
            }

            let fd = unsafe { libc::socket(libc::AF_BLUETOOTH, libc::SOCK_STREAM, BTPROTO_RFCOMM) };
            if fd < 0 {
                return Err(io::Error::last_os_error());
            }

            // Set socket receive timeout (3 seconds)
            let timeout = libc::timeval {
                tv_sec: 3,
                tv_usec: 0,
            };
            unsafe {
                libc::setsockopt(
                    fd,
                    libc::SOL_SOCKET,
                    libc::SO_RCVTIMEO,
                    &timeout as *const _ as *const libc::c_void,
                    std::mem::size_of::<libc::timeval>() as libc::socklen_t,
                );
            }

            let addr = SockAddrRc {
                rc_family: libc::AF_BLUETOOTH as libc::sa_family_t,
                rc_bdaddr: bdaddr,
                rc_channel: ch,
            };

            let res = unsafe {
                libc::connect(
                    fd,
                    &addr as *const _ as *const libc::sockaddr,
                    std::mem::size_of::<SockAddrRc>() as libc::socklen_t,
                )
            };

            if res == 0 {
                return Ok(Self {
                    fd,
                    buf: Vec::with_capacity(2048),
                    seq: 0,
                });
            }

            let err = io::Error::last_os_error();
            unsafe { libc::close(fd) };

            if err.raw_os_error() == Some(libc::EBUSY) {
                last_err = err;
                continue;
            } else {
                return Err(io::Error::new(
                    err.kind(),
                    format!(
                        "Failed to connect to Moto Buds ({}) on RFCOMM channel {}: {}. Make sure the earbuds are connected in Bluetooth settings.",
                        mac, ch, err
                    ),
                ));
            }
        }

        Err(io::Error::new(
            last_err.kind(),
            format!(
                "Failed to connect to Moto Buds ({}) on RFCOMM channel {}: Device was busy after multiple retries.",
                mac, ch
            ),
        ))
    }

    /// Send a command packet and wait for matching response packet
    pub fn request(&mut self, opcode: u16, payload: Vec<u8>) -> io::Result<Packet> {
        self.seq = self.seq.wrapping_add(1);
        let cmd = Packet::new_command(opcode, self.seq, payload);
        let encoded = cmd.encode_spp();

        let written = unsafe {
            libc::write(
                self.fd,
                encoded.as_ptr() as *const libc::c_void,
                encoded.len(),
            )
        };
        if written < 0 {
            return Err(io::Error::last_os_error());
        }

        let mut read_buf = [0u8; 1024];
        let start = std::time::Instant::now();

        loop {
            // Check if buffer already has a packet
            if let Some((pkt, consumed)) = Packet::decode_spp(&self.buf) {
                self.buf.drain(..consumed);
                if pkt.opcode == opcode {
                    return Ok(pkt);
                }
            }

            if start.elapsed() > Duration::from_secs(3) {
                return Err(io::Error::new(
                    io::ErrorKind::TimedOut,
                    format!("Timed out waiting for response to opcode {} ({})", opcode, opcode_name(opcode)),
                ));
            }

            let n = unsafe {
                libc::read(
                    self.fd,
                    read_buf.as_mut_ptr() as *mut libc::c_void,
                    read_buf.len(),
                )
            };

            if n < 0 {
                return Err(io::Error::last_os_error());
            } else if n == 0 {
                return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "Connection closed by earbuds"));
            }

            self.buf.extend_from_slice(&read_buf[..n as usize]);
        }
    }

    /// Read any incoming packet (blocking or until timeout)
    pub fn read_packet(&mut self) -> io::Result<Packet> {
        let mut read_buf = [0u8; 1024];
        loop {
            if let Some((pkt, consumed)) = Packet::decode_spp(&self.buf) {
                self.buf.drain(..consumed);
                return Ok(pkt);
            }

            let n = unsafe {
                libc::read(
                    self.fd,
                    read_buf.as_mut_ptr() as *mut libc::c_void,
                    read_buf.len(),
                )
            };

            if n < 0 {
                return Err(io::Error::last_os_error());
            } else if n == 0 {
                return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "Connection closed by earbuds"));
            }

            self.buf.extend_from_slice(&read_buf[..n as usize]);
        }
    }
}

impl Drop for MotoBudsConnection {
    fn drop(&mut self) {
        unsafe {
            libc::close(self.fd);
        }
    }
}
