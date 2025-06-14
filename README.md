# Wim Hof Breathing - Garmin Connect IQ App

A Garmin smartwatch app that guides you through the Wim Hof breathing technique using haptic feedback, allowing you to practice with your eyes closed.

## Overview

This Connect IQ app implements the classic Wim Hof breathing method with a focus on haptic guidance. The entire breathing session can be completed through vibration cues alone - no need to look at your watch.

The technique consists of:

- 30 deep breathing cycles (configurable)
- Breath retention phase with periodic reminders
- Recovery breath hold (15 seconds)
- Distinct vibration patterns guide you through each phase

> **Personal Note:** As someone who experiences acute RLS (Restless Legs Syndrome) episodes, I've found that Wim Hof breathing helps provide relief for reasons I don't fully understand.

## Usage

1. **Start Session**: Press START button or SELECT
2. **Close Your Eyes**: Let the vibrations guide you
   - 3 quick taps (tap-tap-tap) = Inhale deeply
   - 1 smooth long buzz = Exhale
   - Strong pulse every 10 breaths = Progress milestone
   - Extra tick after exhale (last 5 breaths) = Approaching hold phase
   - Drumroll on final breath = Last breath before hold
3. **Hold Phase**: After completing all breaths, a long vibration signals breath retention
   - Double vibrations every 30 seconds remind you you're still in the hold
   - Press SELECT when you need to breathe
4. **Recovery**: Triple vibration = take a deep breath and hold for 15 seconds
5. **Complete**: Celebration vibration pattern signals the end

## Customization

The timing can be adjusted in `source/WimHofBreathingView.mc`:

```monkey-c
private var _breathCount as Number = 30;           // Number of breathing cycles
private var _inhaleTime as Number = 3000;          // 3 seconds inhale (ms)
private var _exhaleTime as Number = 1500;          // 1.5 seconds exhale (ms)
private var _holdReminderInterval as Number = 30000; // Hold reminder every 30s
private var _recoveryHoldTime as Number = 15000;   // 15 seconds recovery hold
```

## Supported Devices

Currently configured for:

- Garmin Forerunner 955

(Can be adapted for other Connect IQ compatible devices)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Disclaimer

This app is not medical advice. The Wim Hof Method should be practiced safely and never in water or while driving. Consult with a healthcare provider before beginning any breathing practice, especially if you have any medical conditions.

## Acknowledgments

- Wim Hof for developing and sharing this breathing technique
- Garmin for the Connect IQ platform
- [Lucide Icons](https://lucide.dev) for the wind icon (ISC License)
