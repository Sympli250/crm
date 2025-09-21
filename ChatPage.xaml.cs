using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using LutecIA.ViewModels;

namespace LutecIA;
public sealed partial class ChatPage : Page
{
    public ChatViewModel ViewModel { get; } = new ChatViewModel();

    public ChatPage()
    {
        this.InitializeComponent();
        this.DataContext = ViewModel;
    }

    private async void SendButton_Click(object sender, RoutedEventArgs e)
    {
        var text = InputBox.Text;
        if (string.IsNullOrWhiteSpace(text)) return;
        await ViewModel.SendMessageAsync(text);
        InputBox.Text = string.Empty;
    }
}
