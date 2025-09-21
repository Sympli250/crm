using System;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;

namespace LutecIA;
public class LLMService
{
    private readonly HttpClient _http = new();

    // NOTE: API key embedded for demo/training purposes as requested.
    // WARNING: do NOT keep sensitive keys in source for production use.
    private const string ApiKey = "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";
    private const string Endpoint = "https://api.openai.com/v1/chat/completions";

    public LLMService()
    {
    }

    public async Task<string> SendAsync(string input)
    {
        if (string.IsNullOrWhiteSpace(ApiKey) || string.IsNullOrWhiteSpace(Endpoint))
        {
            return "(LLM non configuré) Clé ou endpoint manquant.";
        }

        try
        {
            using var req = new HttpRequestMessage(HttpMethod.Post, Endpoint);
            req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", ApiKey);

            var payload = new
            {
                model = "gpt-4o-mini",
                messages = new[] { new { role = "user", content = input } },
                max_tokens = 1000
            };
            var json = JsonSerializer.Serialize(payload);
            req.Content = new StringContent(json, Encoding.UTF8, "application/json");

            var res = await _http.SendAsync(req);
            var s = await res.Content.ReadAsStringAsync();

            if (!res.IsSuccessStatusCode)
            {
                return $"Erreur API: {res.StatusCode} - {s}";
            }

            try
            {
                using var doc = JsonDocument.Parse(s);
                if (doc.RootElement.TryGetProperty("choices", out var choices) && choices.GetArrayLength() > 0)
                {
                    var messageElement = choices[0].GetProperty("message");
                    if (messageElement.TryGetProperty("content", out var content))
                    {
                        return content.GetString() ?? "(réponse vide)";
                    }
                }

                if (doc.RootElement.TryGetProperty("output", out var output))
                {
                    return output.ToString();
                }

                if (doc.RootElement.TryGetProperty("text", out var text))
                {
                    return text.GetString() ?? text.ToString();
                }
            }
            catch
            {
                // fallback: return raw JSON
            }

            return s;
        }
        catch (Exception ex)
        {
            return $"Exception: {ex.Message}";
        }
    }
}
