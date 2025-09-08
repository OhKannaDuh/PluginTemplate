using Ocelot.Windows;

namespace PluginTemplate.Windows;

[OcelotMainWindow]
public class MainWindow(Plugin plugin, Config config) : OcelotMainWindow(plugin, config)
{
    protected override void Render(RenderContext context)
    {
        Plugin.Modules.RenderMainUi(context);
    }
}
