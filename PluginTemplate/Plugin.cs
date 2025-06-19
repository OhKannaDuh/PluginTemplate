using System;
using Dalamud.Game.ClientState.Conditions;
using Dalamud.Plugin;
using ECommons;
using ECommons.DalamudServices;
using ECommons.Reflection;
using Ocelot;
using Ocelot.Chain;

namespace PluginTemplate;

public sealed class Plugin : OcelotPlugin
{
    public override string Name
    {
        get => "PluginTemplate";
    }

    public Config config { get; init; }

    public override IOcelotConfig _config => config;

    public static ChainQueue Chain => ChainManager.Get("PluginTemplate##main");

    public Plugin(IDalamudPluginInterface plugin)
        : base(plugin, Module.DalamudReflector)
    {
        config = plugin.GetPluginConfig() as Config ?? new Config();

        I18N.SetDirectory(plugin.AssemblyLocation.Directory?.FullName!);
        I18N.LoadFromFile("en", "Translations/en.json");

        OcelotInitialize();

        ChainManager.Initialize();
    }


    public override bool ShouldTick() => true;

    public override void Dispose()
    {
        base.Dispose();
        ChainManager.Close();
    }
}
