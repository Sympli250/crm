using Microsoft.UI.Xaml;

namespace LutecIA;
public partial class App : Application
{
    public App()
    {
        this.InitializeComponent();
    }

    protected override void OnLaunched(Microsoft.UI.Xaml.LaunchActivatedEventArgs args)
    {
        var window = new MainWindow();
        window.Activate();
    }
}
