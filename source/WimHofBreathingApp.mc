import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class WimHofBreathingApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        var view = new WimHofBreathingView();
        var delegate = new WimHofBreathingDelegate();
        delegate.setView(view);
        return [ view, delegate ];
    }

}

function getApp() as WimHofBreathingApp {
    return Application.getApp() as WimHofBreathingApp;
}