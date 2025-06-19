using Ocelot.Windows;

namespace PluginTemplate.Windows;

[OcelotMainWindow]
public class MainWindow : OcelotMainWindow
{
    public MainWindow(Plugin plugin, Config config)
        : base(plugin, config) { }

    public override void Draw() { }
}
