import Toybox.WatchUi;
import Toybox.System;
import Toybox.Lang;

class WimHofBreathingDelegate extends WatchUi.BehaviorDelegate {

    private var _view as WimHofBreathingView?;

    function initialize() {
        BehaviorDelegate.initialize();
    }
    
    function setView(view as WimHofBreathingView) as Void {
        _view = view;
    }

    function onMenu() as Boolean {
        if (_view == null) {
            var viewArray = WatchUi.getCurrentView();
            if (viewArray != null && viewArray[0] != null) {
                _view = viewArray[0] as WimHofBreathingView;
            }
        }
        
        if (_view != null) {
            // MENU button - toggle session start/stop
            if (_view.isSessionActive()) {
                _view.stopSession();
            } else {
                _view.startSession();
            }
        }
        return true;
    }

    function onSelect() as Boolean {
        if (_view == null) {
            var viewArray = WatchUi.getCurrentView();
            if (viewArray != null && viewArray[0] != null) {
                _view = viewArray[0] as WimHofBreathingView;
            }
        }
        
        if (_view != null) {
            // SELECT button - end hold phase or start session
            if (_view.getPhase() == 3) { // PHASE_HOLD
                _view.endHold();
            } else if (_view.getPhase() == 0) { // PHASE_READY
                _view.startSession();
            }
        }
        return true;
    }

    function onBack() as Boolean {
        if (_view == null) {
            var viewArray = WatchUi.getCurrentView();
            if (viewArray != null && viewArray[0] != null) {
                _view = viewArray[0] as WimHofBreathingView;
            }
        }
        
        if (_view != null && _view.isSessionActive()) {
            _view.stopSession();
            return true;
        }
        return false; // Let the system handle back/exit
    }
}