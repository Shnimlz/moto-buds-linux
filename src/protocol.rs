#![allow(dead_code)]

use crc32fast::Hasher;
use serde::{Deserialize, Serialize};

pub const MAGIC_HEAD: &[u8; 4] = b"HEAD";
pub const MAGIC_TAIL: &[u8; 4] = b"TAIL";

// Opcodes reversed from Motorola Moto Buds APK (ks.java)
pub const OP_GET_PROFILE_VERSION: u16 = 0;
pub const OP_GET_SUPPORT_FEATURES: u16 = 1;
pub const OP_GET_SUPPORT_CONFIGS: u16 = 2;
pub const OP_GET_DEVICE_NAME: u16 = 3;
pub const OP_GET_HARDWARE_INFO: u16 = 4;
pub const OP_GET_BATTERY_LEVEL: u16 = 5;
pub const OP_GET_PRIMARY_EARBUD: u16 = 6;
pub const OP_SET_DEVICE_NAME: u16 = 7;
pub const OP_PRIMARY_EARBUD_CHANGED: u16 = 8;
pub const OP_BATTERY_LEVEL_CHANGED: u16 = 9;
pub const OP_GET_EARBUDS_COLOR: u16 = 10;
pub const OP_GET_CHANNEL_ID: u16 = 12;

pub const OP_GET_TOGGLE_CONFIGS: u16 = 256;
pub const OP_GET_TOGGLE_CONFIG: u16 = 257;
pub const OP_SET_TOGGLE_CONFIG: u16 = 258;

pub const OP_GET_CURRENT_ANC_MODE: u16 = 512;
pub const OP_SET_CURRENT_ANC_MODE: u16 = 513;
pub const OP_GET_ADAPTATION_STATUS: u16 = 514;
pub const OP_SET_ADAPTATION_STATUS: u16 = 515;
pub const OP_ANC_MODE_CHANGED: u16 = 516;

pub const OP_GET_EQ_STATE: u16 = 768;
pub const OP_GET_AVAILABLE_EQ_SETS: u16 = 769;
pub const OP_GET_EQ_SET: u16 = 770;
pub const OP_SET_EQ_SET: u16 = 771;
pub const OP_GET_USER_BANDS_COUNT: u16 = 772;
pub const OP_GET_USER_EQ_CONFIG: u16 = 773;
pub const OP_SET_USER_EQ_CONFIG: u16 = 774;
pub const OP_GET_SPATIAL_AUDIO: u16 = 778;
pub const OP_SET_SPATIAL_AUDIO: u16 = 779;
pub const OP_GET_HIRES_MODE: u16 = 780;
pub const OP_SET_HIRES_MODE: u16 = 781;
pub const OP_GET_GAME_MODE: u16 = 782;
pub const OP_SET_GAME_MODE: u16 = 783;
pub const OP_GET_VOLUME_BOOST: u16 = 787;
pub const OP_SET_VOLUME_BOOST: u16 = 788;
pub const OP_GET_BASS_ENHANCEMENT: u16 = 796;
pub const OP_SET_BASS_ENHANCEMENT: u16 = 797;

pub const OP_GET_IN_EAR_DETECTION: u16 = 1026;
pub const OP_SET_IN_EAR_DETECTION: u16 = 1027;
pub const OP_FIND_MY_DEVICE: u16 = 1029;
pub const OP_GET_DUAL_CONNECTION: u16 = 1030;
pub const OP_SET_DUAL_CONNECTION: u16 = 1031;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Packet {
    pub opcode: u16,
    pub pdu_type: u8,
    pub result: u8,
    pub seq: u16,
    pub payload: Vec<u8>,
}

impl Packet {
    pub fn new_command(opcode: u16, seq: u16, payload: Vec<u8>) -> Self {
        Self {
            opcode,
            pdu_type: 0x80, // Command (Request)
            result: 0,
            seq,
            payload,
        }
    }

    /// Encode into Moto Buds SPP wire frame (HEAD + len + body + CRC32 + TAIL)
    pub fn encode_spp(&self) -> Vec<u8> {
        let mut body = Vec::with_capacity(8 + self.payload.len());
        body.extend_from_slice(&self.opcode.to_be_bytes()); // opcode (big-endian)
        body.push(self.pdu_type);                           // type
        body.push(self.result);                             // result
        body.extend_from_slice(&(self.payload.len() as u16).to_le_bytes()); // payload_len (little-endian)
        body.extend_from_slice(&self.seq.to_le_bytes());     // seq (little-endian)
        body.extend_from_slice(&self.payload);

        let mut frame = Vec::with_capacity(4 + 2 + body.len());
        frame.extend_from_slice(MAGIC_HEAD);
        frame.extend_from_slice(&(body.len() as u16).to_le_bytes());
        frame.extend_from_slice(&body);

        let mut hasher = Hasher::new();
        hasher.update(&frame);
        let crc = hasher.finalize();

        let mut full = Vec::with_capacity(frame.len() + 4 + 4);
        full.extend_from_slice(&frame);
        full.extend_from_slice(&crc.to_le_bytes());
        full.extend_from_slice(MAGIC_TAIL);
        full
    }

    /// Parse first complete SPP frame from buffer, returning (Packet, bytes_consumed)
    pub fn decode_spp(buf: &[u8]) -> Option<(Packet, usize)> {
        let head_pos = buf.windows(4).position(|w| w == MAGIC_HEAD)?;
        let tail_pos = buf[head_pos..].windows(4).position(|w| w == MAGIC_TAIL)?;
        let full_tail_pos = head_pos + tail_pos + 4;
        let frame = &buf[head_pos..full_tail_pos];

        if frame.len() < 14 {
            return None;
        }

        let body_len = u16::from_le_bytes([frame[4], frame[5]]) as usize;
        if frame.len() < 6 + body_len + 8 {
            return None; // Wait for full frame
        }

        let body = &frame[6..6 + body_len];
        if body.len() < 8 {
            return None;
        }

        let opcode = u16::from_be_bytes([body[0], body[1]]);
        let pdu_type = body[2];
        let result = body[3];
        let payload_len = u16::from_le_bytes([body[4], body[5]]) as usize;
        let seq = u16::from_le_bytes([body[6], body[7]]);

        let payload = if body.len() >= 8 + payload_len {
            body[8..8 + payload_len].to_vec()
        } else {
            Vec::new()
        };

        Some((
            Packet {
                opcode,
                pdu_type,
                result,
                seq,
                payload,
            },
            full_tail_pos,
        ))
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EarbudBattery {
    pub percentage: Option<u8>,
    pub is_charging: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BatteryReport {
    pub left: EarbudBattery,
    pub right: EarbudBattery,
    pub case: EarbudBattery,
}

impl BatteryReport {
    pub fn parse(payload: &[u8]) -> Option<Self> {
        if payload.len() < 3 {
            return None;
        }

        fn parse_single(b: u8) -> EarbudBattery {
            if b == 0xFF {
                EarbudBattery {
                    percentage: None,
                    is_charging: false,
                }
            } else {
                EarbudBattery {
                    percentage: Some((b & 0x7F).min(100)),
                    is_charging: (b >> 7) != 0,
                }
            }
        }

        Some(Self {
            left: parse_single(payload[0]),
            right: parse_single(payload[1]),
            case: parse_single(payload[2]),
        })
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum AncMode {
    Off,
    NoiseCancellation, // Full
    Adaptive,
    Transparency,
    Unknown(u8, u8),
}

impl AncMode {
    pub fn from_bytes(mode: u8, anc_type: u8) -> Self {
        match (mode, anc_type) {
            (0, _) => AncMode::Off,
            (1, 3) => AncMode::NoiseCancellation,
            (1, 1) => AncMode::Adaptive,
            (2, 0) | (2, _) => AncMode::Transparency,
            _ => AncMode::Unknown(mode, anc_type),
        }
    }

    pub fn to_bytes(&self) -> [u8; 2] {
        match self {
            AncMode::Off => [0, 0],
            AncMode::NoiseCancellation => [1, 3],
            AncMode::Adaptive => [1, 1],
            AncMode::Transparency => [2, 0],
            AncMode::Unknown(m, t) => [*m, *t],
        }
    }

    pub fn as_str(&self) -> &'static str {
        match self {
            AncMode::Off => "Off",
            AncMode::NoiseCancellation => "Noise Cancellation (High)",
            AncMode::Adaptive => "Adaptive Noise Cancellation",
            AncMode::Transparency => "Transparency",
            AncMode::Unknown(_, _) => "Unknown",
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum SpatialAudioMode {
    Off,
    SpatialAudio,
    HeadTracking,
    Unknown(u8, u8),
}

impl SpatialAudioMode {
    pub fn from_bytes(mode: u8, tracking: u8) -> Self {
        match (mode, tracking) {
            (0, _) => SpatialAudioMode::Off,
            (1, 0) => SpatialAudioMode::SpatialAudio,
            (1, 1) => SpatialAudioMode::HeadTracking,
            _ => SpatialAudioMode::Unknown(mode, tracking),
        }
    }

    pub fn to_bytes(&self) -> [u8; 2] {
        match self {
            SpatialAudioMode::Off => [0, 0],
            SpatialAudioMode::SpatialAudio => [1, 0],
            SpatialAudioMode::HeadTracking => [1, 1],
            SpatialAudioMode::Unknown(m, t) => [*m, *t],
        }
    }

    pub fn as_str(&self) -> &'static str {
        match self {
            SpatialAudioMode::Off => "Off",
            SpatialAudioMode::SpatialAudio => "Spatial Audio (Fixed)",
            SpatialAudioMode::HeadTracking => "Spatial Audio + Head Tracking",
            SpatialAudioMode::Unknown(_, _) => "Unknown",
        }
    }
}

pub fn opcode_name(opcode: u16) -> &'static str {
    match opcode {
        OP_GET_PROFILE_VERSION => "get profile version",
        OP_GET_SUPPORT_FEATURES => "get support features",
        OP_GET_SUPPORT_CONFIGS => "get support configs",
        OP_GET_DEVICE_NAME => "get device name",
        OP_GET_HARDWARE_INFO => "get hardware info",
        OP_GET_BATTERY_LEVEL => "get battery level",
        OP_BATTERY_LEVEL_CHANGED => "battery level changed",
        OP_GET_EARBUDS_COLOR => "get earbuds color",
        OP_GET_CHANNEL_ID => "get channel id",
        OP_GET_CURRENT_ANC_MODE => "get anc mode",
        OP_SET_CURRENT_ANC_MODE => "set anc mode",
        OP_ANC_MODE_CHANGED => "anc mode changed",
        OP_GET_EQ_STATE => "get eq state",
        OP_GET_AVAILABLE_EQ_SETS => "get available eq sets",
        OP_GET_EQ_SET => "get eq set",
        OP_SET_EQ_SET => "set eq set",
        OP_GET_SPATIAL_AUDIO => "get spatial audio",
        OP_SET_SPATIAL_AUDIO => "set spatial audio",
        OP_GET_GAME_MODE => "get game mode",
        OP_SET_GAME_MODE => "set game mode",
        OP_GET_VOLUME_BOOST => "get volume boost",
        OP_SET_VOLUME_BOOST => "set volume boost",
        OP_GET_BASS_ENHANCEMENT => "get bass enhancement",
        OP_SET_BASS_ENHANCEMENT => "set bass enhancement",
        OP_GET_IN_EAR_DETECTION => "get in-ear detection",
        OP_SET_IN_EAR_DETECTION => "set in-ear detection",
        OP_FIND_MY_DEVICE => "find my device",
        OP_GET_DUAL_CONNECTION => "get dual connection",
        OP_SET_DUAL_CONNECTION => "set dual connection",
        _ => "unknown opcode",
    }
}
