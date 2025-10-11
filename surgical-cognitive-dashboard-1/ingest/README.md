# Live Data Ingestion

This directory contains subdirectories for ingesting live biosignal data from external sources (eye-trackers, robot telemetry, physiological monitors, etc.).

## 📂 Directory Structure

```
ingest/
├── hr/           # Heart rate / RR intervals
├── eye/          # Eye-tracking data (pupil, blinks, gaze)
├── robot/        # Robot kinematics and telemetry
├── grip/         # Grip force sensors
└── README.md     # This file
```

## 📊 Accepted Data Formats

### **HRV / Heart Rate** (`ingest/hr/`)

**File:** `rr.csv`

**Schema:**
```csv
timestamp_ms,rr_ms
1234567890,950
1234567891,980
1234567892,1020
```

**Columns:**
- `timestamp_ms`: Unix timestamp in milliseconds
- `rr_ms`: RR interval duration in milliseconds

**Requirements:**
- Append-only (new rows added continuously)
- Sorted by timestamp
- RR intervals between 400-2000ms (physiological range)
- Minimum 10 intervals for HRV computation

**Example Producer:**
```r
# Append RR interval to CSV
rr_data <- data.frame(
  timestamp_ms = as.numeric(Sys.time()) * 1000,
  rr_ms = 980
)
write.table(rr_data, "ingest/hr/rr.csv", 
            append = TRUE, sep = ",", 
            col.names = !file.exists("ingest/hr/rr.csv"),
            row.names = FALSE)
```

---

### **Eye-Tracking - Pupil** (`ingest/eye/`)

**File:** `pupil.csv`

**Schema:**
```csv
timestamp_ms,pupil_diameter_mm,confidence
1234567890,3.5,0.98
1234567891,3.52,0.97
```

**Columns:**
- `timestamp_ms`: Unix timestamp in milliseconds
- `pupil_diameter_mm`: Pupil diameter in millimeters
- `confidence`: Tracking confidence (0-1, optional)

**Requirements:**
- Append-only
- Sorted by timestamp
- Diameter between 2-8mm (physiological range)
- Minimum 30 Hz recommended for TEPR detection
- Confidence > 0.8 recommended

---

### **Eye-Tracking - Blinks** (`ingest/eye/`)

**File:** `blinks.csv`

**Schema:**
```csv
blink_start_ms,blink_end_ms,duration_ms
1234567890,1234567940,50
1234568000,1234568180,180
```

**Columns:**
- `blink_start_ms`: Blink onset timestamp (ms)
- `blink_end_ms`: Blink offset timestamp (ms)
- `duration_ms`: Blink duration in milliseconds

**Requirements:**
- Append-only
- Duration between 50-500ms (physiological range)
- Typical rate: 10-20 blinks/minute

---

### **Robot Kinematics** (`ingest/robot/`)

**File:** `kinematics.csv`

**Schema:**
```csv
timestamp_ms,x_mm,y_mm,z_mm,roll_deg,pitch_deg,yaw_deg,instrument_id
1234567890,120.5,45.2,100.3,5.2,10.1,2.3,forceps_left
1234567891,120.6,45.3,100.2,5.3,10.2,2.4,forceps_left
```

**Columns:**
- `timestamp_ms`: Unix timestamp in milliseconds
- `x_mm`, `y_mm`, `z_mm`: Position in millimeters (robot base frame)
- `roll_deg`, `pitch_deg`, `yaw_deg`: Orientation in degrees (optional)
- `instrument_id`: Instrument identifier (optional)

**Requirements:**
- Append-only
- High-rate (≥100 Hz recommended for tremor analysis)
- Position resolution ≤0.1mm for tremor detection
- Coordinate frame must be consistent

**Tremor Extraction:**
- Bandpass filter 8-12 Hz
- Compute 3D velocity magnitude
- RMS amplitude in μm

---

### **Grip Force** (`ingest/grip/`)

**File:** `force.csv`

**Schema:**
```csv
timestamp_ms,force_N,instrument_id
1234567890,2.5,forceps_left
1234567891,2.6,forceps_left
```

**Columns:**
- `timestamp_ms`: Unix timestamp in milliseconds
- `force_N`: Grip force in Newtons
- `instrument_id`: Instrument identifier (optional)

**Requirements:**
- Append-only
- Minimum 10 Hz sampling
- Force range 0-15N typical
- Resolution ≤0.1N for precision tasks

---

## 🔄 Data Ingestion Pipeline

### **Shiny Integration**

The dashboard uses `reactiveFileReader()` to monitor CSV files:

```r
# In server.R
rr_data <- reactiveFileReader(
  intervalMillis = 1000,  # Check every 1s
  session = session,
  filePath = "ingest/hr/rr.csv",
  readFunc = function(path) {
    if (!file.exists(path)) return(tibble())
    readr::read_csv(path, col_types = "dd", show_col_types = FALSE)
  }
)
```

### **Schema Validation**

Before processing, data is validated:

```r
validate_rr_data <- function(df) {
  # Check required columns
  if (!all(c("timestamp_ms", "rr_ms") %in% names(df))) {
    stop("Missing required columns")
  }
  
  # Check physiological range
  if (any(df$rr_ms < 400 | df$rr_ms > 2000, na.rm = TRUE)) {
    warning("RR intervals outside physiological range (400-2000ms)")
  }
  
  # Check sorted
  if (is.unsorted(df$timestamp_ms)) {
    warning("Timestamps not sorted, sorting now")
    df <- df %>% arrange(timestamp_ms)
  }
  
  return(df)
}
```

### **Real-Time Processing**

Data flows through the pipeline:

1. **File Watcher** → Detects new rows
2. **Validator** → Checks schema and ranges
3. **Buffer** → Accumulates high-rate data
4. **Feature Computer** → Extracts features per window
5. **State Model** → Predicts cognitive state
6. **UI Update** → Displays results

---

## 📝 File Management

### **Creating Directories**

```bash
mkdir -p ingest/hr ingest/eye ingest/robot ingest/grip
```

### **Resetting Data**

```bash
# Clear all ingest data
rm ingest/*/**.csv

# Or selectively
rm ingest/hr/rr.csv
```

### **File Sizes**

Typical growth rates:
- HRV @ 1 Hz: ~50 KB/hour
- Pupil @ 30 Hz: ~1.5 MB/hour
- Robot @ 100 Hz: ~5 MB/hour
- Grip @ 10 Hz: ~500 KB/hour

**Recommendation:** Implement log rotation for long procedures (>2 hours)

---

## 🧪 Test Data Generators

### **Simulate HRV Data**

```r
source("R/hrv_utils.R")

# Generate RR intervals
rr_subscriber <- subscribe_rr("simulate", params = params)
rr_data <- rr_subscriber()

# Write to ingest
write.csv(rr_data, "ingest/hr/rr.csv", row.names = FALSE)
```

### **Simulate Blinks**

```r
source("R/blink_utils.R")

# Generate blink events
blinks <- simulate_blinks(duration_s = 600, baseline_rate_per_min = 15)

# Convert to required format
blink_csv <- blinks %>%
  mutate(
    blink_start_ms = timestamp * 1000,
    blink_end_ms = (timestamp + duration_ms / 1000) * 1000
  ) %>%
  select(blink_start_ms, blink_end_ms, duration_ms)

write.csv(blink_csv, "ingest/eye/blinks.csv", row.names = FALSE)
```

---

## 🔌 Hardware Integration

### **Recommended Devices**

**Eye-Tracking:**
- Tobii Pro Glasses 3 (120 Hz, wireless)
- Pupil Labs Core (200 Hz, open-source)
- SR Research EyeLink Portable Duo (1000 Hz, research-grade)

**Heart Rate:**
- Polar H10 (1 Hz RR export via Bluetooth)
- Garmin HRM-Dual (ANT+ / Bluetooth)
- BioPac MP160 (research-grade ECG)

**Robot Telemetry:**
- da Vinci Xi/Si API (position, force, events)
- Universal Robots (UR5/UR10, 125 Hz)
- KUKA iiwa (1 kHz)

**Grip Force:**
- ATI Nano17 (7000 Hz)
- FlexiForce sensors (custom, 10-100 Hz)
- Custom strain gauge arrays

---

## 🐛 Troubleshooting

### **File Not Updating**

**Symptoms:** Dashboard shows stale data

**Solutions:**
1. Check file permissions (`chmod 666 ingest/hr/rr.csv`)
2. Verify producer is appending (not overwriting)
3. Check `reactiveFileReader` interval (increase if needed)
4. Monitor file size: `watch -n 1 ls -lh ingest/hr/rr.csv`

### **High Latency**

**Symptoms:** >5s delay between data arrival and display

**Solutions:**
1. Reduce `reactiveFileReader` interval (min 100ms)
2. Use binary format (RDS, Parquet) instead of CSV
3. Implement ring buffer for high-rate data
4. Move to WebSocket/streaming protocol

### **Data Validation Errors**

**Symptoms:** Warnings about out-of-range values

**Solutions:**
1. Check sensor calibration
2. Verify units (mm vs cm, N vs mN)
3. Inspect coordinate frames (robot base vs. tool)
4. Filter outliers using MAD or IQR

---

## 📚 Additional Resources

- **HRV Standards:** Task Force (1996). Circulation, 93(5), 1043-1065.
- **Pupillometry:** Beatty & Lucero-Wagoner (2000). Handbook of Psychophysiology.
- **Tremor Analysis:** Riviere et al. (1997). IEEE EMBS.

---

**Last Updated:** 2025-10-11  
**Version:** 1.0.0  
**Status:** Ready for integration

