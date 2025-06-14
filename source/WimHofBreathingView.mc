import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Attention;
import Toybox.Lang;


class WimHofBreathingView extends WatchUi.View {

    // ==================== CUSTOMIZABLE SETTINGS ====================
    // Easy to modify - just change these values!
    
    private var _breathCount as Number = 30;           // Number of breathing cycles
    private var _inhaleTime as Number = 3000;          // 3 seconds inhale (ms)
    private var _exhaleTime as Number = 1500;          // 1.5 seconds exhale (ms)
    private var _holdReminderInterval as Number = 30000; // Hold reminder every 30s
    private var _recoveryHoldTime as Number = 15000;   // 15 seconds recovery hold
    
    // Phase constants
    private const PHASE_READY = 0;
    private const PHASE_INHALE = 1;
    private const PHASE_EXHALE = 2;
    private const PHASE_HOLD = 3;
    private const PHASE_RECOVERY = 4;
    private const PHASE_COMPLETE = 5;
    
    // Vibration patterns (intensity: 0-100, duration in ms)
    // Inhale: 3 quick taps (tap-tap-tap) for clear distinction
    private var _vibeInhale as Array<Attention.VibeProfile> = [
        new Attention.VibeProfile(60, 80),   // Tap 1
        new Attention.VibeProfile(0, 60),    // Gap
        new Attention.VibeProfile(60, 80),   // Tap 2
        new Attention.VibeProfile(0, 60),    // Gap
        new Attention.VibeProfile(60, 80)    // Tap 3
    ];
    
    // Exhale: 1 smooth long buzz for clear contrast
    private var _vibeExhale as Array<Attention.VibeProfile> = [
        new Attention.VibeProfile(70, 400)  // Smooth wave
    ];
    
    // Milestone vibration: Strong pulse for every 10th breath
    private var _vibeMilestone as Array<Attention.VibeProfile> = [
        new Attention.VibeProfile(100, 200), // Strong pulse
        new Attention.VibeProfile(0, 150)    // Gap before inhale pattern
    ];
    
    // Warning tick: Added after exhale for last 5 breaths before hold
    private var _vibeWarningTick as Array<Attention.VibeProfile> = [
        new Attention.VibeProfile(0, 100),   // Small gap after exhale
        new Attention.VibeProfile(80, 100)   // Warning tick
    ];
    
    // Finale pattern: Drumroll for final breath (SDK max: 8 VibeProfile objects)
    private var _vibeFinale as Array<Attention.VibeProfile> = [
        new Attention.VibeProfile(60, 80),
        new Attention.VibeProfile(0, 80),
        new Attention.VibeProfile(80, 80),
        new Attention.VibeProfile(0, 80),
        new Attention.VibeProfile(100, 100),
        new Attention.VibeProfile(0, 80),
        new Attention.VibeProfile(100, 150),
        new Attention.VibeProfile(100, 250)   // Strong finale buzz
    ];
    
    private var _vibeHoldStart as Array<Attention.VibeProfile> = [
        new Attention.VibeProfile(100, 500) // Long buzz for hold start
    ];
    
    private var _vibeHoldReminder as Array<Attention.VibeProfile> = [
        new Attention.VibeProfile(80, 300),  // Double long buzz pattern
        new Attention.VibeProfile(0, 100),   // Gap
        new Attention.VibeProfile(80, 300)
    ];
    
    private var _vibeRecoveryStart as Array<Attention.VibeProfile> = [
        new Attention.VibeProfile(60, 150),  // Triple buzz pattern
        new Attention.VibeProfile(0, 100),   // Gap
        new Attention.VibeProfile(60, 150),
        new Attention.VibeProfile(0, 100),   // Gap
        new Attention.VibeProfile(60, 150)
    ];
    
    private var _vibeComplete as Array<Attention.VibeProfile> = [
        new Attention.VibeProfile(100, 200), // Celebration pattern
        new Attention.VibeProfile(0, 100),
        new Attention.VibeProfile(100, 200),
        new Attention.VibeProfile(0, 100),
        new Attention.VibeProfile(100, 200)
    ];

    // ==================== SESSION STATE ====================
    private var _phase as Number = PHASE_READY;
    private var _currentBreath as Number = 0;
    private var _sessionActive as Boolean = false;
    
    // Timers
    private var _sessionTimer as Timer.Timer?;
    private var _holdReminderTimer as Timer.Timer?;

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    // ==================== GETTERS ====================
    function isSessionActive() as Boolean {
        return _sessionActive;
    }

    function getPhase() as Number {
        return _phase;
    }

    function onUpdate(dc as Dc) as Void {
        // Clear the screen with black background
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        // Call parent onUpdate to draw the layout
        View.onUpdate(dc);
        
        var statusLabel = View.findDrawableById("StatusLabel") as WatchUi.Text;
        var counterLabel = View.findDrawableById("CounterLabel") as WatchUi.Text;
        var instructionLabel = View.findDrawableById("InstructionLabel") as WatchUi.Text;
        
        if (statusLabel != null && counterLabel != null && instructionLabel != null) {
            switch (_phase) {
                case PHASE_READY:
                    statusLabel.setText("Wim Hof");
                    counterLabel.setText("Press START");
                    instructionLabel.setText(_breathCount + " breaths + hold");
                    break;
                    
                case PHASE_INHALE:
                    statusLabel.setText("INHALE");
                    counterLabel.setText(_currentBreath.toString() + "/" + _breathCount.toString());
                    instructionLabel.setText("Breathe in deeply");
                    break;
                    
                case PHASE_EXHALE:
                    statusLabel.setText("EXHALE");
                    counterLabel.setText(_currentBreath.toString() + "/" + _breathCount.toString());
                    instructionLabel.setText("Let it go");
                    break;
                    
                case PHASE_HOLD:
                    statusLabel.setText("HOLD");
                    counterLabel.setText("Breath retained");
                    instructionLabel.setText("Press SELECT\nwhen ready");
                    break;
                    
                case PHASE_RECOVERY:
                    statusLabel.setText("RECOVERY");
                    counterLabel.setText("Hold for 15s");
                    instructionLabel.setText("Deep breath & hold");
                    break;
                    
                case PHASE_COMPLETE:
                    statusLabel.setText("COMPLETE!");
                    counterLabel.setText("Round finished");
                    instructionLabel.setText("Well done!");
                    break;
            }
        }
    }

    // ==================== VIBRATION FUNCTIONS ====================
    function vibrate(pattern as Array<Attention.VibeProfile>) as Void {
        if (Attention has :vibrate) {
            Attention.vibrate(pattern);
        }
    }

    // ==================== SESSION CONTROL ====================
    function startSession() as Void {
        if (_sessionActive) {
            return;
        }
        
        _sessionActive = true;
        _currentBreath = 1;
        _phase = PHASE_INHALE;
        
        // Force multiple update requests to ensure display refreshes
        WatchUi.requestUpdate();
        
        // Schedule vibration after a tiny delay
        var vibeTimer = new Timer.Timer();
        vibeTimer.start(method(:doInitialVibrate), 50, false);
        
        // Schedule exhale
        _sessionTimer = new Timer.Timer();
        _sessionTimer.start(self.method(:prepareExhale), _inhaleTime - 50, false);
    }
    
    function doInitialVibrate() as Void {
        if (_sessionActive && _phase == PHASE_INHALE) {
            self.vibrate(_vibeInhale);
            WatchUi.requestUpdate(); // Request another update after vibration
        }
    }
    
    function prepareExhale() as Void {
        if (!_sessionActive) {
            return;
        }
        
        // Change phase first
        _phase = PHASE_EXHALE;
        WatchUi.requestUpdate();
        
        // Then vibrate after a tiny delay
        var vibeTimer = new Timer.Timer();
        vibeTimer.start(method(:doExhaleVibrate), 50, false);
        
        // Schedule next phase
        _sessionTimer = new Timer.Timer();
        _sessionTimer.start(self.method(:nextBreathOrHold), _exhaleTime, false);
    }
    
    function doExhaleVibrate() as Void {
        if (_sessionActive && _phase == PHASE_EXHALE) {
            self.vibrate(_vibeExhale);
            
            // Add warning tick for last 5 breaths (except the final one which has finale)
            if (_currentBreath >= (_breathCount - 4) && _currentBreath < _breathCount) {
                var warningTimer = new Timer.Timer();
                warningTimer.start(method(:vibrateWarningTick), 500, false);
            }
            
            WatchUi.requestUpdate(); // Another update request
        }
    }
    
    function vibrateWarningTick() as Void {
        if (_sessionActive && _phase == PHASE_EXHALE) {
            self.vibrate(_vibeWarningTick);
        }
    }
    
    function stopSession() as Void {
        _sessionActive = false;
        _phase = PHASE_READY;
        _currentBreath = 0;
        
        self.clearAllTimers();
        WatchUi.requestUpdate();
    }
    
    private function clearAllTimers() as Void {
        if (_sessionTimer != null) {
            _sessionTimer.stop();
            _sessionTimer = null;
        }
        if (_holdReminderTimer != null) {
            _holdReminderTimer.stop();
            _holdReminderTimer = null;
        }
    }

    // ==================== BREATHING CYCLE ====================
    private function startBreathingCycle() as Void {
        if (!_sessionActive) {
            return;
        }
        
        _currentBreath++;
        
        if (_currentBreath > _breathCount) {
            self.startHoldPhase();
            return;
        }
        
        // Change phase and update display
        _phase = PHASE_INHALE;
        WatchUi.requestUpdate();
        
        // Vibrate after tiny delay
        var vibeTimer = new Timer.Timer();
        vibeTimer.start(method(:doInhaleVibrate), 50, false);
        
        // Schedule exhale preparation
        _sessionTimer = new Timer.Timer();
        _sessionTimer.start(self.method(:prepareExhale), _inhaleTime - 50, false);
    }
    
    function doInhaleVibrate() as Void {
        if (_sessionActive && _phase == PHASE_INHALE) {
            // Check for milestone breaths (every 10th) and finale
            if (_currentBreath == _breathCount) {
                // Final breath: Special finale pattern
                self.vibrate(_vibeFinale);
            } else if (_currentBreath % 10 == 0) {
                // Every 10th breath: Milestone pulse + inhale pattern
                self.vibrate(_vibeMilestone);
                var delayTimer = new Timer.Timer();
                delayTimer.start(method(:vibrateInhaleOnly), 350, false);
            } else {
                // Normal inhale pattern
                self.vibrate(_vibeInhale);
            }
            WatchUi.requestUpdate();
        }
    }
    
    function vibrateInhaleOnly() as Void {
        if (_sessionActive && _phase == PHASE_INHALE) {
            self.vibrate(_vibeInhale);
        }
    }
    
    function startExhale() as Void {
        // This function is no longer used - replaced by prepareExhale
    }
    
    function nextBreathOrHold() as Void {
        if (!_sessionActive) {
            return;
        }
        
        self.startBreathingCycle();
    }

    // ==================== HOLD PHASE ====================
    private function startHoldPhase() as Void {
        if (!_sessionActive) {
            return;
        }
        
        // Change phase and update display
        _phase = PHASE_HOLD;
        WatchUi.requestUpdate();
        
        // Vibrate after tiny delay
        var vibeTimer = new Timer.Timer();
        vibeTimer.start(method(:doHoldVibrate), 50, false);
    }
    
    function doHoldVibrate() as Void {
        if (_sessionActive && _phase == PHASE_HOLD) {
            self.vibrate(_vibeHoldStart);
            WatchUi.requestUpdate();
            
            // Set up reminder vibrations every 30 seconds
            self.scheduleHoldReminder();
        }
    }
    
    private function scheduleHoldReminder() as Void {
        _holdReminderTimer = new Timer.Timer();
        _holdReminderTimer.start(self.method(:holdReminderVibe), _holdReminderInterval, true);
    }
    
    function holdReminderVibe() as Void {
        if (_phase == PHASE_HOLD && _sessionActive) {
            self.vibrate(_vibeHoldReminder);
        }
    }
    
    function endHold() as Void {
        if (_phase != PHASE_HOLD) {
            return;
        }
        
        if (_holdReminderTimer != null) {
            _holdReminderTimer.stop();
            _holdReminderTimer = null;
        }
        
        self.startRecoveryPhase();
    }

    // ==================== RECOVERY PHASE ====================
    private function startRecoveryPhase() as Void {
        if (!_sessionActive) {
            return;
        }
        
        // Change phase and update display
        _phase = PHASE_RECOVERY;
        WatchUi.requestUpdate();
        
        // Vibrate after tiny delay
        var vibeTimer = new Timer.Timer();
        vibeTimer.start(method(:doRecoveryVibrate), 50, false);
    }
    
    function doRecoveryVibrate() as Void {
        if (_sessionActive && _phase == PHASE_RECOVERY) {
            self.vibrate(_vibeRecoveryStart);
            WatchUi.requestUpdate();
            
            // End recovery after set time
            _sessionTimer = new Timer.Timer();
            _sessionTimer.start(self.method(:completeSession), _recoveryHoldTime - 50, false);
        }
    }
    
    function completeSession() as Void {
        if (!_sessionActive) {
            return;
        }
        
        // Change phase and update display
        _phase = PHASE_COMPLETE;
        WatchUi.requestUpdate();
        
        // Vibrate after tiny delay
        var vibeTimer = new Timer.Timer();
        vibeTimer.start(method(:doCompleteVibrate), 50, false);
    }
    
    function doCompleteVibrate() as Void {
        if (_phase == PHASE_COMPLETE) {
            self.vibrate(_vibeComplete);
            WatchUi.requestUpdate();
            
            // Auto-stop after completion
            var stopTimer = new Timer.Timer();
            stopTimer.start(self.method(:stopSession), 3000, false);
        }
    }
}