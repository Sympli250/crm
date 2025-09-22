using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Composition;
using Microsoft.UI.Xaml.Hosting;
using Windows.System.Profile;

namespace LutecIA;
public partial class MainWindow : Window
{
    public MainViewModel ViewModel { get; } = new MainViewModel();

    public MainWindow()
    {
        this.InitializeComponent();

        if (NavView.SettingsItem is NavigationViewItem settingsItem)
        {
            settingsItem.Content = "Paramètres";
            settingsItem.Icon = new SymbolIcon(Symbol.Setting);
        }

        this.DataContext = ViewModel;

        // Apply simple title bar integration for a modern look
        ExtendsContentIntoTitleBar = true;
        SetTitleBar();

        // Navigate to default page
        ContentFrame.Navigate(typeof(ChatPage));
    }

    void SetTitleBar()
    {
        // Attempts to enable a Mica-like effect where available.
        try
        {
            var hwnd = WinRT.Interop.WindowNative.GetWindowHandle(this);
            // For brevity we don't implement full DWM.Mica here; leaving TitleBar extension only.
        }
        catch { }
    }

    private void NavView_SelectionChanged(NavigationView sender, NavigationViewSelectionChangedEventArgs args)
    {
        if (args.IsSettingsSelected)
        {
            ContentFrame.Navigate(typeof(SettingsPage));
            return;
        }

        if (args.SelectedItemContainer is NavigationViewItem item && item.Tag is string tag)
        {
            switch (tag)
            {
                case "chat":
                    ContentFrame.Navigate(typeof(ChatPage));
                    break;
                case "documents":
                    ContentFrame.Navigate(typeof(DocumentsPage));
                    break;
                case "history":
                    ContentFrame.Navigate(typeof(HistoryPage));
                    break;
                case "users":
                    ContentFrame.Navigate(typeof(UsersPage));
                    break;
            }
        }
    }
}
