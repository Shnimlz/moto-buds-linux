mod bluetooth;
mod commands;
mod protocol;

use clap::{Parser, Subcommand, ValueEnum};
use colored::*;
use std::io;

use bluetooth::MotoBudsConnection;
use protocol::{AncMode, SpatialAudioMode};

#[derive(Parser)]
#[command(
    name = "moto-buds",
    author = "shnimlz",
    version = "0.1.0",
    about = "Control and monitor Motorola Moto Buds on Linux (CachyOS)",
    long_about = "A reverse-engineered companion tool for Motorola Moto Buds earbuds on Linux, supporting ANC, Game Mode, Battery reporting, Spatial Audio, and more."
)]
struct Cli {
    /// Bluetooth MAC address (e.g. A0:90:B5:CD:BC:3C). Auto-detected if omitted.
    #[arg(short, long, env = "MOTO_BUDS_MAC")]
    device: Option<String>,

    /// RFCOMM channel (default: 16)
    #[arg(short, long)]
    channel: Option<u8>,

    /// Output results in JSON format (ideal for Waybar, Polybar, or scripts)
    #[arg(short, long)]
    json: bool,

    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Display full status of the earbuds
    Status,

    /// Show battery levels for left, right, and charging case
    Battery,

    /// Get or set Active Noise Cancellation mode
    Anc {
        #[arg(value_enum)]
        mode: Option<AncArg>,
    },

    /// Get or toggle low-latency Game Mode
    GameMode {
        #[arg(value_enum)]
        action: Option<ToggleArg>,
    },

    /// Get or set Spatial Audio mode
    Spatial {
        #[arg(value_enum)]
        mode: Option<SpatialArg>,
    },

    /// Toggle or set In-Ear detection
    InEar {
        #[arg(value_enum)]
        state: Option<StateArg>,
    },

    /// Toggle or set Multipoint Dual Connection
    DualConn {
        #[arg(value_enum)]
        state: Option<StateArg>,
    },

    /// Get or set Equalizer preset
    Eq {
        /// Preset ID (e.g. 0, 1, 2)
        #[arg(short, long)]
        set: Option<u8>,
    },

    /// Locate misplaced earbuds by playing an alert tone
    Find {
        #[arg(value_enum)]
        target: FindTarget,
    },

    /// Continuously listen and display live earbud events and battery updates
    Monitor,
}

#[derive(Copy, Clone, PartialEq, Eq, PartialOrd, Ord, ValueEnum)]
enum AncArg {
    Off,
    High,
    NoiseCancelling,
    Adaptive,
    Transparency,
}

#[derive(Copy, Clone, PartialEq, Eq, PartialOrd, Ord, ValueEnum)]
enum ToggleArg {
    On,
    Off,
    Toggle,
}

#[derive(Copy, Clone, PartialEq, Eq, PartialOrd, Ord, ValueEnum)]
enum SpatialArg {
    Off,
    Fixed,
    HeadTracking,
}

#[derive(Copy, Clone, PartialEq, Eq, PartialOrd, Ord, ValueEnum)]
enum StateArg {
    On,
    Off,
}

#[derive(Copy, Clone, PartialEq, Eq, PartialOrd, Ord, ValueEnum)]
enum FindTarget {
    Left,
    Right,
    Both,
    Stop,
}

fn format_battery(opt: Option<u8>, charging: bool) -> ColoredString {
    match opt {
        Some(pct) => {
            let s = if charging {
                format!("{}% ⚡", pct)
            } else {
                format!("{}%", pct)
            };
            if pct > 60 {
                s.green().bold()
            } else if pct > 20 {
                s.yellow().bold()
            } else {
                s.red().bold()
            }
        }
        None => "N/A".dimmed(),
    }
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let cli = Cli::parse();

    let mac = match cli.device {
        Some(m) => m,
        None => MotoBudsConnection::auto_detect_address()?,
    };

    let mut conn = MotoBudsConnection::connect(&mac, cli.channel)?;

    match cli.command {
        Commands::Status => {
            let status = commands::get_device_status(&mut conn)?;
            if cli.json {
                println!("{}", serde_json::to_string_pretty(&status)?);
            } else {
                println!("{}", "╭───────────────────────────────────────────────╮".cyan());
                println!("│ {:<45} │", format!("{} ({})", status.name.bold(), mac).cyan());
                println!("{}", "├───────────────────────────────────────────────┤".cyan());
                println!("│ {:<18}: {:<26} │", "Profile Version", status.profile_version);
                println!("│ {:<18}: {:<26} │", "Hardware Info", status.hardware_info);
                println!("{}", "├───────────────────────────────────────────────┤".cyan());
                println!(
                    "│ {:<8}: {:<6}  {:<9}: {:<6}  {:<6}: {:<5} │",
                    "Left",
                    format_battery(status.battery.left.percentage, status.battery.left.is_charging),
                    "Right",
                    format_battery(status.battery.right.percentage, status.battery.right.is_charging),
                    "Case",
                    format_battery(status.battery.case.percentage, status.battery.case.is_charging)
                );
                println!("{}", "├───────────────────────────────────────────────┤".cyan());
                println!("│ {:<18}: {:<26} │", "ANC Mode", status.anc_mode.as_str().magenta().bold());
                println!(
                    "│ {:<18}: {:<26} │",
                    "Game Mode",
                    if status.game_mode { "ON (Low Latency)".green().bold() } else { "OFF".dimmed() }
                );
                println!(
                    "│ {:<18}: {:<26} │",
                    "In-Ear Detection",
                    if status.in_ear_detection { "Enabled".green() } else { "Disabled".dimmed() }
                );
                println!(
                    "│ {:<18}: {:<26} │",
                    "Dual Connection",
                    if status.dual_connection { "Enabled (Multipoint)".green() } else { "Disabled".dimmed() }
                );
                println!("│ {:<18}: {:<26} │", "EQ Preset", format!("Preset #{}", status.eq_state).yellow());
                println!("{}", "╰───────────────────────────────────────────────╯".cyan());
            }
        }
        Commands::Battery => {
            let battery = commands::get_battery(&mut conn)?;
            if cli.json {
                println!("{}", serde_json::to_string(&battery)?);
            } else {
                println!(
                    "Left: {} | Right: {} | Case: {}",
                    format_battery(battery.left.percentage, battery.left.is_charging),
                    format_battery(battery.right.percentage, battery.right.is_charging),
                    format_battery(battery.case.percentage, battery.case.is_charging)
                );
            }
        }
        Commands::Anc { mode } => match mode {
            None => {
                let current = commands::get_anc_mode(&mut conn)?;
                if cli.json {
                    println!("{}", serde_json::to_string(&current)?);
                } else {
                    println!("Current ANC mode: {}", current.as_str().cyan().bold());
                }
            }
            Some(target) => {
                let anc_mode = match target {
                    AncArg::Off => AncMode::Off,
                    AncArg::High | AncArg::NoiseCancelling => AncMode::NoiseCancellation,
                    AncArg::Adaptive => AncMode::Adaptive,
                    AncArg::Transparency => AncMode::Transparency,
                };
                commands::set_anc_mode(&mut conn, anc_mode)?;
                println!("ANC mode set to: {}", anc_mode.as_str().green().bold());
            }
        },
        Commands::GameMode { action } => match action {
            None => {
                let enabled = commands::get_game_mode(&mut conn)?;
                if cli.json {
                    println!("{{\"game_mode\": {}}}", enabled);
                } else {
                    println!("Game Mode: {}", if enabled { "ON".green().bold() } else { "OFF".dimmed() });
                }
            }
            Some(ToggleArg::On) => {
                commands::set_game_mode(&mut conn, true)?;
                println!("Game Mode {}", "ENABLED".green().bold());
            }
            Some(ToggleArg::Off) => {
                commands::set_game_mode(&mut conn, false)?;
                println!("Game Mode {}", "DISABLED".yellow().bold());
            }
            Some(ToggleArg::Toggle) => {
                let current = commands::get_game_mode(&mut conn)?;
                let next = !current;
                commands::set_game_mode(&mut conn, next)?;
                println!("Game Mode toggled to: {}", if next { "ON".green().bold() } else { "OFF".yellow().bold() });
            }
        },
        Commands::Spatial { mode } => match mode {
            None => {
                let current = commands::get_spatial_audio(&mut conn)?;
                if cli.json {
                    println!("{}", serde_json::to_string(&current)?);
                } else {
                    println!("Spatial Audio: {}", current.as_str().cyan().bold());
                }
            }
            Some(SpatialArg::Off) => {
                commands::set_spatial_audio(&mut conn, SpatialAudioMode::Off)?;
                println!("Spatial Audio set to: {}", "Off".yellow().bold());
            }
            Some(SpatialArg::Fixed) => {
                commands::set_spatial_audio(&mut conn, SpatialAudioMode::SpatialAudio)?;
                println!("Spatial Audio set to: {}", "Spatial Audio (Fixed)".green().bold());
            }
            Some(SpatialArg::HeadTracking) => {
                commands::set_spatial_audio(&mut conn, SpatialAudioMode::HeadTracking)?;
                println!("Spatial Audio set to: {}", "Spatial Audio + Head Tracking".green().bold());
            }
        },
        Commands::InEar { state } => match state {
            None => {
                let status = commands::get_device_status(&mut conn)?;
                println!("In-Ear Detection: {}", if status.in_ear_detection { "ON".green() } else { "OFF".dimmed() });
            }
            Some(StateArg::On) => {
                commands::set_in_ear_detection(&mut conn, true)?;
                println!("In-Ear Detection {}", "ENABLED".green().bold());
            }
            Some(StateArg::Off) => {
                commands::set_in_ear_detection(&mut conn, false)?;
                println!("In-Ear Detection {}", "DISABLED".yellow().bold());
            }
        },
        Commands::DualConn { state } => match state {
            None => {
                let status = commands::get_device_status(&mut conn)?;
                println!("Dual Connection: {}", if status.dual_connection { "ON".green() } else { "OFF".dimmed() });
            }
            Some(StateArg::On) => {
                commands::set_dual_connection(&mut conn, true)?;
                println!("Dual Connection {}", "ENABLED".green().bold());
            }
            Some(StateArg::Off) => {
                commands::set_dual_connection(&mut conn, false)?;
                println!("Dual Connection {}", "DISABLED".yellow().bold());
            }
        },
        Commands::Eq { set } => match set {
            None => {
                let current = commands::get_eq_state(&mut conn)?;
                println!("Current EQ Preset: {}", format!("#{}", current).cyan().bold());
            }
            Some(preset_id) => {
                commands::set_eq_preset(&mut conn, preset_id)?;
                println!("EQ preset set to: {}", format!("#{}", preset_id).green().bold());
            }
        },
        Commands::Find { target } => match target {
            FindTarget::Left => {
                commands::find_my_device(&mut conn, true, false)?;
                println!("Ringing {} earbud...", "LEFT".yellow().bold());
            }
            FindTarget::Right => {
                commands::find_my_device(&mut conn, false, true)?;
                println!("Ringing {} earbud...", "RIGHT".yellow().bold());
            }
            FindTarget::Both => {
                commands::find_my_device(&mut conn, true, true)?;
                println!("Ringing {} earbuds...", "BOTH".yellow().bold());
            }
            FindTarget::Stop => {
                commands::find_my_device(&mut conn, false, false)?;
                println!("Stopped ringing earbuds.");
            }
        },
        Commands::Monitor => {
            println!("{}", "Listening for live Moto Buds events (Ctrl+C to stop)...".cyan());
            loop {
                match conn.read_packet() {
                    Ok(pkt) => {
                        match pkt.opcode {
                            protocol::OP_BATTERY_LEVEL_CHANGED | protocol::OP_GET_BATTERY_LEVEL => {
                                if let Some(bat) = protocol::BatteryReport::parse(&pkt.payload) {
                                    println!(
                                        "[Battery Update] Left: {} | Right: {} | Case: {}",
                                        format_battery(bat.left.percentage, bat.left.is_charging),
                                        format_battery(bat.right.percentage, bat.right.is_charging),
                                        format_battery(bat.case.percentage, bat.case.is_charging),
                                    );
                                }
                            }
                            protocol::OP_ANC_MODE_CHANGED | protocol::OP_GET_CURRENT_ANC_MODE => {
                                if pkt.payload.len() >= 2 {
                                    let mode = AncMode::from_bytes(pkt.payload[0], pkt.payload[1]);
                                    println!("[ANC Update] Mode changed to: {}", mode.as_str().magenta().bold());
                                }
                            }
                            other => {
                                println!(
                                    "[Event 0x{:04x} ({})] Payload: {}",
                                    other,
                                    protocol::opcode_name(other),
                                    pkt.payload.iter().map(|b| format!("{:02x}", b)).collect::<Vec<_>>().join(" ")
                                );
                            }
                        }
                    }
                    Err(e) if e.kind() == io::ErrorKind::TimedOut => {
                        // Periodic heartbeat: query battery to keep stream alive
                        let _ = conn.request(protocol::OP_GET_BATTERY_LEVEL, vec![]);
                    }
                    Err(e) => {
                        eprintln!("Error reading event: {}", e);
                        break;
                    }
                }
            }
        }
    }

    Ok(())
}
