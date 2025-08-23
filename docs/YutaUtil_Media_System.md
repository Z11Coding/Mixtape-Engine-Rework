# YutaUtil Media System

This document describes the camera and microphone access system implemented in YutaUtil for the Mixtape Engine Rework.

## Overview

The media system provides three main components:

1. **MediaCamera** - For capturing video input and transmitting it to Flixel objects
2. **MediaMicrophone** - For capturing audio input with visual feedback
3. **MediaCombo** - For synchronized camera and microphone functionality with combined effects

## Components

### MediaCamera (`yutautil.media.MediaCamera`)

The MediaCamera class provides video capture functionality with the following features:

- **Video Capture**: Captures video from the default camera
- **Frame Transmission**: Transmits video frames to FlxSprite objects in real-time
- **Quality Control**: Adjustable video quality (0-100%)
- **Resolution Control**: Configurable resolution and frame rate
- **Multiple Targets**: Can transmit to multiple FlxSprite objects simultaneously

#### Basic Usage:

```haxe
var camera = new MediaCamera(640, 480, 30); // width, height, fps
camera.start();
camera.enableFrameCapture();

var videoSprite = camera.createCameraSprite();
add(videoSprite);
```

#### Methods:

- `start()`: Start camera capture
- `stop()`: Stop camera capture
- `enableFrameCapture()`: Enable frame capture for transmission
- `addTransmissionTarget(sprite)`: Add a FlxSprite to receive camera data
- `setQuality(quality)`: Set camera quality (0-100)
- `setResolution(width, height)`: Change camera resolution

### Microphone (`yutautil.media.Microphone`)

The Microphone class provides audio capture with visual feedback:

- **Audio Capture**: Captures audio from the default microphone
- **Volume Analysis**: Real-time volume level analysis
- **Visual Feedback**: Multiple visualization modes for FlxSprite objects
- **Activity Detection**: Detects voice activity and silence

#### Visual Modes:

- `VOLUME_BAR`: Scale sprite height based on volume
- `VOLUME_WIDTH`: Scale sprite width based on volume  
- `COLOR_INTENSITY`: Change sprite alpha based on volume
- `PEAK_FLASH`: Flash colors based on peak detection
- `WAVE_SIMULATION`: Simulate wave motion

#### Basic Usage:

```haxe
var microphone = new Microphone(44100, 75); // sample rate, gain
microphone.start();

var visualizer = microphone.createVisualizerSprite(VOLUME_BAR);
add(visualizer);
```

#### Methods:

- `start()`: Start microphone capture
- `stop()`: Stop microphone capture
- `addVisualTarget(sprite, mode)`: Add visual feedback to a sprite
- `setGain(gain)`: Set microphone gain (0-100)
- `getAudioLevels()`: Get current audio level information

### MediaCombo (`yutautil.media.MediaCombo`)

The MediaCombo class combines camera and microphone functionality:

- **Synchronized Operation**: Manages both camera and microphone together
- **Combined Effects**: Audio-reactive video effects
- **Threshold Control**: Configurable audio threshold for triggering effects
- **Multiple Effect Modes**: Various synchronized audio-visual effects

#### Combined Effect Modes:

- `AUDIO_REACTIVE_VIDEO`: Video scales/reacts to audio levels
- `VIDEO_WITH_AUDIO_BORDER`: Video with audio-reactive colored borders
- `AUDIO_TRIGGERED_EFFECTS`: Various effects triggered by audio threshold
- `SOUND_VISUALIZATION_OVERLAY`: Audio visualization overlaid on video
- `MIRROR_WITH_EFFECTS`: Mirrored video with audio-reactive rotation

#### Basic Usage:

```haxe
var mediaCombo = new MediaCombo(320, 240, 30, 44100);
mediaCombo.start();

var reactiveSprite = mediaCombo.createCombinedSprite(AUDIO_REACTIVE_VIDEO);
add(reactiveSprite);
```

#### Methods:

- `start()`: Start both camera and microphone
- `stop()`: Stop both components
- `addCombinedTarget(sprite, mode)`: Add sprite with combined effects
- `setAudioThreshold(threshold)`: Set audio level threshold for effects
- `setCameraEnabled(enabled)`: Enable/disable camera component
- `setMicrophoneEnabled(enabled)`: Enable/disable microphone component

## Test States

Three test states are included to demonstrate the functionality:

### CameraTestState

Tests camera functionality with:
- Live video feed display
- Multiple preview windows
- Quality and resolution controls
- Frame capture toggling

**Controls:**
- SPACE: Start/Stop Camera
- F: Toggle Frame Capture
- 1-4: Set Quality (25%, 50%, 75%, 100%)
- R: Change Resolution
- C/A: Clear/Add Transmission Targets

### MicrophoneTestState

Tests microphone functionality with:
- Real-time audio level display
- Multiple visual feedback modes
- Audio visualizer bars
- Gain and threshold controls

**Controls:**
- SPACE: Start/Stop Microphone
- 1-5: Set Gain (20%, 40%, 60%, 80%, 100%)
- S: Change Silence Level
- E: Toggle Enhanced Capture
- C/A: Clear/Add Visual Targets

### MediaComboTestState

Tests combined functionality with:
- Multiple synchronized effect modes
- Real-time audio and video status
- Combined effect demonstrations
- Threshold adjustment

**Controls:**
- SPACE: Start/Stop Media
- C: Toggle Camera
- M: Toggle Microphone  
- 1-5: Change Effect Mode
- T: Adjust Audio Threshold

## Access from Debug Menu

All test states are accessible from the Debug State Menu under the "Media" category:
1. Open Debug State Menu (usually F12 or debug console)
2. Navigate to the "Media" category
3. Select desired test state

## Technical Notes

- **Platform Support**: Designed for platforms with camera/microphone support
- **Performance**: Frame capture can be disabled to improve performance
- **Error Handling**: Includes proper error handling for device availability
- **Memory Management**: Includes dispose methods for proper cleanup
- **Thread Safety**: Uses timers for safe UI updates from audio callbacks

## Dependencies

- OpenFL media classes (Camera, Microphone, Video)
- Flixel framework
- Haxe Timer for frame capture timing

## Future Enhancements

Potential future improvements:
- Recording functionality
- Multiple camera selection
- Audio effects processing
- Network streaming capabilities
- Custom shader effects for video processing
