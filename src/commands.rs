use std::io;
use serde::{Deserialize, Serialize};

use crate::bluetooth::MotoBudsConnection;
use crate::protocol::*;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DeviceStatus {
    pub name: String,
    pub profile_version: String,
    pub hardware_info: String,
    pub battery: BatteryReport,
    pub anc_mode: AncMode,
    pub game_mode: bool,
    pub in_ear_detection: bool,
    pub dual_connection: bool,
    pub eq_state: u8,
}

pub fn get_device_status(conn: &mut MotoBudsConnection) -> io::Result<DeviceStatus> {
    // 1. Profile Version
    let resp = conn.request(OP_GET_PROFILE_VERSION, vec![])?;
    let profile_version = if resp.payload.len() >= 2 {
        format!("{}.{}", resp.payload[0], resp.payload[1])
    } else {
        "Unknown".to_string()
    };

    // 2. Device Name
    let resp = conn.request(OP_GET_DEVICE_NAME, vec![])?;
    let name = String::from_utf8_lossy(&resp.payload)
        .trim_matches(|c: char| c.is_whitespace() || c == '\0')
        .to_string();

    // 3. Hardware info
    let resp = conn.request(OP_GET_HARDWARE_INFO, vec![])?;
    let hardware_info = String::from_utf8_lossy(&resp.payload)
        .replace('\0', " ")
        .split_whitespace()
        .collect::<Vec<_>>()
        .join(" ");

    // 4. Battery
    let resp = conn.request(OP_GET_BATTERY_LEVEL, vec![])?;
    let battery = BatteryReport::parse(&resp.payload).unwrap_or(BatteryReport {
        left: EarbudBattery { percentage: None, is_charging: false },
        right: EarbudBattery { percentage: None, is_charging: false },
        case: EarbudBattery { percentage: None, is_charging: false },
    });

    // 5. ANC
    let resp = conn.request(OP_GET_CURRENT_ANC_MODE, vec![])?;
    let anc_mode = if resp.payload.len() >= 2 {
        AncMode::from_bytes(resp.payload[0], resp.payload[1])
    } else {
        AncMode::Unknown(0, 0)
    };

    // 6. Game Mode
    let resp = conn.request(OP_GET_GAME_MODE, vec![])?;
    let game_mode = resp.payload.first().copied().unwrap_or(0) != 0;

    // 7. In-ear detection
    let resp = conn.request(OP_GET_IN_EAR_DETECTION, vec![])?;
    let in_ear_detection = resp.payload.first().copied().unwrap_or(0) != 0;

    // 8. Dual connection
    let resp = conn.request(OP_GET_DUAL_CONNECTION, vec![])?;
    let dual_connection = resp.payload.first().copied().unwrap_or(0) != 0;

    // 9. EQ state
    let resp = conn.request(OP_GET_EQ_STATE, vec![])?;
    let eq_state = resp.payload.first().copied().unwrap_or(0);

    Ok(DeviceStatus {
        name,
        profile_version,
        hardware_info,
        battery,
        anc_mode,
        game_mode,
        in_ear_detection,
        dual_connection,
        eq_state,
    })
}

pub fn get_battery(conn: &mut MotoBudsConnection) -> io::Result<BatteryReport> {
    let resp = conn.request(OP_GET_BATTERY_LEVEL, vec![])?;
    BatteryReport::parse(&resp.payload).ok_or_else(|| {
        io::Error::new(io::ErrorKind::InvalidData, "Invalid battery payload received")
    })
}

pub fn get_anc_mode(conn: &mut MotoBudsConnection) -> io::Result<AncMode> {
    let resp = conn.request(OP_GET_CURRENT_ANC_MODE, vec![])?;
    if resp.payload.len() >= 2 {
        Ok(AncMode::from_bytes(resp.payload[0], resp.payload[1]))
    } else {
        Ok(AncMode::Unknown(0, 0))
    }
}

pub fn set_anc_mode(conn: &mut MotoBudsConnection, mode: AncMode) -> io::Result<()> {
    let bytes = mode.to_bytes();
    let resp = conn.request(OP_SET_CURRENT_ANC_MODE, bytes.to_vec())?;
    if resp.result != 0 {
        return Err(io::Error::new(
            io::ErrorKind::Other,
            format!("Earbuds rejected ANC change (error code {}). Note: ANC requires earbuds to be worn in ear.", resp.result),
        ));
    }
    Ok(())
}

pub fn get_game_mode(conn: &mut MotoBudsConnection) -> io::Result<bool> {
    let resp = conn.request(OP_GET_GAME_MODE, vec![])?;
    Ok(resp.payload.first().copied().unwrap_or(0) != 0)
}

pub fn set_game_mode(conn: &mut MotoBudsConnection, enabled: bool) -> io::Result<()> {
    let resp = conn.request(OP_SET_GAME_MODE, vec![if enabled { 1 } else { 0 }])?;
    if resp.result != 0 {
        return Err(io::Error::new(
            io::ErrorKind::Other,
            format!("Earbuds rejected Game Mode change (error code {})", resp.result),
        ));
    }
    Ok(())
}

pub fn get_spatial_audio(conn: &mut MotoBudsConnection) -> io::Result<SpatialAudioMode> {
    let resp = conn.request(OP_GET_SPATIAL_AUDIO, vec![])?;
    if resp.payload.len() >= 2 {
        Ok(SpatialAudioMode::from_bytes(resp.payload[0], resp.payload[1]))
    } else {
        Ok(SpatialAudioMode::Unknown(0, 0))
    }
}

pub fn set_spatial_audio(conn: &mut MotoBudsConnection, mode: SpatialAudioMode) -> io::Result<()> {
    let bytes = mode.to_bytes();
    let resp = conn.request(OP_SET_SPATIAL_AUDIO, bytes.to_vec())?;
    if resp.result != 0 {
        return Err(io::Error::new(
            io::ErrorKind::Other,
            format!("Earbuds rejected Spatial Audio change (error code {})", resp.result),
        ));
    }
    Ok(())
}

pub fn set_in_ear_detection(conn: &mut MotoBudsConnection, enabled: bool) -> io::Result<()> {
    let resp = conn.request(OP_SET_IN_EAR_DETECTION, vec![if enabled { 1 } else { 0 }])?;
    if resp.result != 0 {
        return Err(io::Error::new(
            io::ErrorKind::Other,
            format!("Earbuds rejected In-Ear Detection change (error code {})", resp.result),
        ));
    }
    Ok(())
}

pub fn set_dual_connection(conn: &mut MotoBudsConnection, enabled: bool) -> io::Result<()> {
    let resp = conn.request(OP_SET_DUAL_CONNECTION, vec![if enabled { 1 } else { 0 }])?;
    if resp.result != 0 {
        return Err(io::Error::new(
            io::ErrorKind::Other,
            format!("Earbuds rejected Dual Connection change (error code {})", resp.result),
        ));
    }
    Ok(())
}

pub fn find_my_device(conn: &mut MotoBudsConnection, left: bool, right: bool) -> io::Result<()> {
    let payload = vec![if left { 1 } else { 0 }, if right { 1 } else { 0 }];
    let resp = conn.request(OP_FIND_MY_DEVICE, payload)?;
    if resp.result != 0 {
        return Err(io::Error::new(
            io::ErrorKind::Other,
            format!("Earbuds rejected Find My Device command (error code {})", resp.result),
        ));
    }
    Ok(())
}

pub fn get_eq_state(conn: &mut MotoBudsConnection) -> io::Result<u8> {
    let resp = conn.request(OP_GET_EQ_STATE, vec![])?;
    Ok(resp.payload.first().copied().unwrap_or(0))
}

pub fn set_eq_preset(conn: &mut MotoBudsConnection, preset_id: u8) -> io::Result<()> {
    let resp = conn.request(OP_SET_EQ_SET, vec![preset_id])?;
    if resp.result != 0 {
        return Err(io::Error::new(
            io::ErrorKind::Other,
            format!("Earbuds rejected EQ Preset change (error code {})", resp.result),
        ));
    }
    Ok(())
}
