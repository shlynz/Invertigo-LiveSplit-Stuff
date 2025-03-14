state("Invertigo") { }

/*
 * v1.1 Additional checks to prevent adding time that should've been cleared instead
 * v1.2 Borked the times on splits, should be fixed
 */

startup
{
    vars.CoffeeBreakName = "2_coffee_break";
    vars.MenuName = "menu_v4";

    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "Invertigo";
    vars.Helper.LoadSceneManager = true;

    settings.Add("resetMenu", true, "Automatically reset when in main menu.");
    settings.Add("resetCoffeeBreak", true, "Automatically reset when restarting while in Coffee Break.");

    vars.Helper.AlertGameTime();
}

init
{
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        vars.Helper["Timer"] = mono.Make<float>("ScoreManager", 1, "_instance", "_timer");
        vars.Helper["IsTimerRunning"] = mono.Make<bool>("ScoreManager", 1, "_instance", "_running");

        return true;
    });

    vars.TotalTime = 0; 
}

update
{
    current.Scene = vars.Helper.Scenes.Active.Name ?? old.Scene;
}

start
{
    return current.Scene == vars.CoffeeBreakName && !old.IsTimerRunning && current.IsTimerRunning;
}

onStart
{
    vars.TotalTime = 0;
}

split
{
    return old.Scene != current.Scene;
}

reset
{
    return settings["resetMenu"] && old.Scene != current.Scene && current.Scene == vars.MenuName
        || settings["resetCoffeeBreak"] && current.Scene == vars.CoffeeBreakName && old.Timer > current.Timer;
}

gameTime
{
    if (old.Timer > current.Timer)
    {
        vars.TotalTime += old.Timer - current.Timer;
    }

    return TimeSpan.FromSeconds(vars.TotalTime + current.Timer);
}

isLoading
{
    return true;
}
