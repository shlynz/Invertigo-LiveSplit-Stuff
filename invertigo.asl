state("Invertigo") {}

/*
 * v1.1 Additional checks to prevent adding time that should've been cleared instead
*/

startup
{
    //UnityASL setup thanks to Ero
    vars.Log = (Action<object>)(output => print("[Invertigo] " + output));
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.LoadSceneManager = true;

    settings.Add("resetMenu", true, "Automatically reset when in main menu.");
    settings.Add("resetCoffeeBreak", true, "Automatically reset when restarting while in Coffee Break.");

    if (timer.CurrentTimingMethod == TimingMethod.RealTime) {
        if (MessageBox.Show(
            "Invertigo uses the time spent in the level as the timing method.\n"+
            "LiveSplit is currently set to RTA, do you want to switch?",
            "Invertigo AutoSplitter",
            MessageBoxButtons.YesNo,
            MessageBoxIcon.Question
        ) == DialogResult.Yes) {
            timer.CurrentTimingMethod = TimingMethod.GameTime;
        }
    }
}

init
{
    vars.CoffeeBreakName = "2_coffee_break";
    vars.MenuName = "menu_v4";
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
        {
            //Thanks to CaptainRektbeard for figuring out the params...
            vars.Helper["Timer"] = mono.Make<float>("ScoreManager", 1, "_instance", "_timer");
            vars.Helper["IsTimerRunning"] = mono.Make<bool>("ScoreManager", 1, "_instance", "_running");
            vars.Helper["IsGamePaused"] = mono.Make<bool>("PauseManager", 1, "_instance", "Paused");
            return true;
        });
    //Init some vars
    current.PrevLevels = 0.0;
    current.PrevTimes = 0.0;
    current.Timer = 0.0;
    current.Scene = null;
}

gameTime
{
    return TimeSpan.FromSeconds(current.Timer + current.PrevTimes + current.PrevLevels);
}

update
{
    current.Scene = vars.Helper.Scenes.Active.Name;
    if (current.Scene == null) {
        current.Scene = old.Scene;
    }
    current.DidReset = old.Timer != null && old.Timer > current.Timer;
    current.DidLevelChange = current.Scene != old.Scene;
    if (current.DidReset && !current.DidLevelChange)
    {
        current.PrevTimes += old.Timer;
    }
}

start
{
    if (current.Scene == vars.CoffeeBreakName && current.IsTimerRunning)
    {
        current.PrevLevels = 0.0;
        current.PrevTimes = 0.0;
        return true;
    }
}

reset
{
    if ((settings["resetMenu"] && current.Scene == vars.MenuName)
        || (settings["resetCoffeeBreak"] && current.Scene == vars.CoffeeBreakName && current.DidReset))
    {
        current.PrevLevels = 0.0;
        current.PrevTimes = 0.0;
        return true;
    }
}

split
{
    if (current.DidLevelChange) {
        current.PrevLevels += current.PrevTimes + current.Timer;
        current.PrevTimes = 0.0;
        return true;
    }
}

isLoading
{
    return !current.IsTimerRunning || current.IsGamePaused;
}