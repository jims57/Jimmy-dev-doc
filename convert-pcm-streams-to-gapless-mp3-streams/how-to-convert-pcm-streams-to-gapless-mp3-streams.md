# How to Convert PCM Streams to Gapless MP3 Streams

This document explains how to convert PCM audio streams into truly gapless MP3 streams for seamless playback.

## The Problem

When converting PCM audio to MP3 in chunks (e.g., for streaming TTS), you typically get glitches between chunks because:

1. **Per-chunk encoder spawning** - Each chunk gets a new encoder instance, resetting internal state
2. **Frame boundary misalignment** - PCM data doesn't align to MP3 frame boundaries (1152 samples)
3. **Metadata injection** - ID3 tags, Xing headers, LAME encoder tags get added to each chunk
4. **Padding bytes** - Encoder adds padding (0xAA, 0x55) to fill incomplete frames

## The Solution

### Key Principles

1. **Single persistent encoder** - Keep one FFmpeg/LAME process alive for the entire session
2. **PCM buffer for frame alignment** - Carry over remaining samples to next chunk (1152-sample boundary)
3. **Extract pure audio frames** - Remove all metadata, only output raw MP3 audio frames

### Implementation

#### 1. GaplessMP3Encoder Class

```python
class GaplessMP3Encoder:
    MP3_FRAME_SAMPLES = 1152  # MPEG-1 Layer III samples per frame
    
    def __init__(self, sample_rate=24000, bitrate='128k'):
        self.sample_rate = sample_rate
        self.bitrate = bitrate
        self.process = None
        self.pcm_buffer = np.array([], dtype=np.float32)  # PCM buffer for carryover
    
    def start(self):
        # Start persistent FFmpeg process
        self.process = subprocess.Popen([
            'ffmpeg',
            '-f', 's16le',
            '-ar', str(self.sample_rate),
            '-ac', '1',
            '-i', 'pipe:0',
            '-c:a', 'libmp3lame',
            '-b:a', self.bitrate,
            '-write_id3v1', '0',
            '-write_id3v2', '0',
            '-id3v2_version', '0',
            '-write_xing', '0',
            '-fflags', '+bitexact',
            '-f', 'mp3',
            'pipe:1'
        ], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    
    def feed_pcm(self, pcm_float, volume_multiplier=1.0):
        # Apply volume and clip
        audio = np.clip(pcm_float * volume_multiplier, -1.0, 1.0)
        
        # Add to PCM buffer
        self.pcm_buffer = np.concatenate([self.pcm_buffer, audio])
        
        # Only encode complete frames (1152 samples each)
        complete_frames = len(self.pcm_buffer) // self.MP3_FRAME_SAMPLES
        if complete_frames == 0:
            return b''  # Buffer not enough for one frame
        
        # Extract complete frames, keep remainder
        samples_to_encode = complete_frames * self.MP3_FRAME_SAMPLES
        pcm_to_encode = self.pcm_buffer[:samples_to_encode]
        self.pcm_buffer = self.pcm_buffer[samples_to_encode:]  # Carryover
        
        # Convert to 16-bit PCM and write to encoder
        pcm_int16 = (pcm_to_encode * 32767).astype(np.int16)
        self.process.stdin.write(pcm_int16.tobytes())
        self.process.stdin.flush()
        
        # Read MP3 output (non-blocking)
        mp3_output = self._read_available_output()
        
        # Extract pure audio frames (skip Xing/LAME metadata)
        return self._extract_audio_frames(mp3_output)
    
    def flush(self):
        # Pad remaining buffer to complete frame
        if len(self.pcm_buffer) > 0:
            padding = self.MP3_FRAME_SAMPLES - (len(self.pcm_buffer) % self.MP3_FRAME_SAMPLES)
            self.pcm_buffer = np.concatenate([self.pcm_buffer, np.zeros(padding)])
            # Encode and write
            pcm_int16 = (self.pcm_buffer * 32767).astype(np.int16)
            self.process.stdin.write(pcm_int16.tobytes())
        
        # Close stdin to trigger encoder flush
        self.process.stdin.close()
        mp3_output = self.process.stdout.read()
        
        # Skip last frame (may contain LAME tag)
        return self._extract_audio_frames(mp3_output, skip_last=True)
```

#### 2. MP3 Frame Extraction

```python
def _extract_audio_frames(self, mp3_data, skip_last=False):
    frames = []
    pos = 0
    
    # Skip ID3v2 header if present
    if mp3_data[:3] == b'ID3':
        id3_size = ((mp3_data[6] & 0x7F) << 21) | ((mp3_data[7] & 0x7F) << 14) | \
                   ((mp3_data[8] & 0x7F) << 7) | (mp3_data[9] & 0x7F)
        pos = 10 + id3_size
    
    while pos < len(mp3_data) - 4:
        # Find frame sync (0xFF 0xFx or 0xFF 0xEx)
        if mp3_data[pos] == 0xFF and (mp3_data[pos + 1] & 0xE0) == 0xE0:
            # Parse frame header
            header = (mp3_data[pos] << 24) | (mp3_data[pos + 1] << 16) | \
                     (mp3_data[pos + 2] << 8) | mp3_data[pos + 3]
            
            frame_length = calculate_frame_length(header)
            
            # Skip Xing/Info/LAME metadata frames
            frame_content = mp3_data[pos:pos+200]
            if b'Xing' in frame_content or b'Info' in frame_content or b'LAME' in frame_content:
                pos += frame_length
                continue
            
            frames.append((pos, frame_length))
            pos += frame_length
        else:
            pos += 1
    
    # Skip last frame if requested
    if skip_last and frames:
        frames = frames[:-1]
    
    # Assemble pure frames
    return b''.join(mp3_data[p:p+l] for p, l in frames)
```

#### 3. MP3 Frame Length Calculation

```python
def calculate_frame_length(header):
    version = (header >> 19) & 0x03      # MPEG version
    layer = (header >> 17) & 0x03        # Layer
    bitrate_index = (header >> 12) & 0x0F
    sample_rate_index = (header >> 10) & 0x03
    padding = (header >> 9) & 0x01
    
    # Bitrate tables (kbps)
    bitrate_table_v1_l3 = [0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 0]
    bitrate_table_v2_l3 = [0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160, 0]
    
    # Sample rate tables (Hz)
    sample_rate_table = {
        0: [11025, 12000, 8000, 0],   # MPEG 2.5
        2: [22050, 24000, 16000, 0],  # MPEG 2
        3: [44100, 48000, 32000, 0]   # MPEG 1
    }
    
    bitrate = bitrate_table_v1_l3[bitrate_index] if version == 3 else bitrate_table_v2_l3[bitrate_index]
    sample_rate = sample_rate_table[version][sample_rate_index]
    
    # Frame length formula
    if version == 3:  # MPEG-1
        return (144 * bitrate * 1000) // sample_rate + padding
    else:  # MPEG-2/2.5
        return (72 * bitrate * 1000) // sample_rate + padding
```

### Usage Flow

```
TTS Session Start
    |
    v
Create GaplessMP3Encoder (single FFmpeg process)
    |
    v
For each audio chunk from TTS:
    |
    +---> feed_pcm(chunk)
    |         |
    |         +---> Add to PCM buffer
    |         +---> Encode only complete 1152-sample frames
    |         +---> Keep remainder in buffer for next chunk
    |         +---> Return pure MP3 audio frames
    |
    v
TTS Session End
    |
    v
flush() - encode remaining buffer + close encoder
```

### FFmpeg Parameters Explained

| Parameter | Purpose |
|-----------|---------|
| `-write_id3v1 0` | Disable ID3v1 tag at end |
| `-write_id3v2 0` | Disable ID3v2 tag at start |
| `-id3v2_version 0` | No ID3v2 version |
| `-write_xing 0` | Disable Xing/LAME VBR header |
| `-fflags +bitexact` | Deterministic output |

### Result

- **Pure MP3 audio frames** - No metadata, no padding artifacts
- **Perfect frame boundaries** - PCM carryover ensures 1152-sample alignment
- **Consistent encoder state** - Single encoder maintains internal state
- **Gapless playback** - Chunks concatenate seamlessly

## Date

December 24, 2025