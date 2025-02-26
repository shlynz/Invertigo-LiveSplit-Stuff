state("Invertigo") {}

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
            vars.Helper["IsRunning"] = mono.Make<bool>("ScoreManager", 1, "_instance", "_running");
            vars.Helper["IsPaused"] = mono.Make<bool>("PauseManager", 1, "_instance", "Paused");
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
    current.DidReset = old.Timer != null && old.Timer > current.Timer;
    if (current.DidReset)
    {
        current.PrevTimes += old.Timer;
    }
}

start
{
    return current.Scene == vars.CoffeeBreakName && current.IsRunning;
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
    if (current.Scene == null) {
        current.Scene = old.Scene;
    }
    if (current.Scene != old.Scene) {
        current.PrevLevels += current.PrevTimes + current.Timer;
        current.PrevTimes = 0.0;
        return true;
    }
}

isLoading
{
    return !current.IsRunning || current.IsPaused;
}