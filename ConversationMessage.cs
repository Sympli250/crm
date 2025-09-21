namespace LutecIA;
public class ConversationMessage
{
    public string Sender { get; set; } = "";
    public string Text { get; set; } = "";
    public System.DateTime Timestamp { get; set; } = System.DateTime.UtcNow;
}
