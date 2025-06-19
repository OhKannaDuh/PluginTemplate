using Ocelot.Windows;

namespace PluginTemplate.Windows;

[OcelotConfigWindow]
public class ConfigWindow : OcelotConfigWindow
{
    public ConfigWindow(Plugin plugin, Config config)
        : base(plugin, config) { }
}
