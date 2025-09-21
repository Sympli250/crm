using CommunityToolkit.Mvvm.ComponentModel;
using System.Collections.ObjectModel;
using System.Threading.Tasks;


namespace LutecIA;
public partial class ChatViewModel : ObservableObject
{
    public ObservableCollection<ConversationMessage> Messages { get; } = new();

    private readonly LLMService _llm = new LLMService();

    public ChatViewModel()
    {
        Messages.Add(new ConversationMessage { Sender = "System", Text = "Bienvenue sur LutecIA"});
    }

    public async Task SendMessageAsync(string text)
    {
        Messages.Add(new ConversationMessage { Sender = "Vous", Text = text });
        var reply = await _llm.SendAsync(text);
        Messages.Add(new ConversationMessage { Sender = "LutecIA", Text = reply });
    }
}
