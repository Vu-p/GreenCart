using System.IO;
using System.Text;
using Microsoft.AspNetCore.Mvc;

namespace GreenCart.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public sealed class ChatController(IConfiguration configuration, HttpClient httpClient) : ControllerBase
{
    [HttpPost]
    public async Task<IActionResult> SendMessage(CancellationToken cancellationToken)
    {
        var apiKey = configuration["Gemini:ApiKey"];
        var model = configuration["Gemini:Model"] ?? "gemini-2.0-flash";

        if (string.IsNullOrEmpty(apiKey))
        {
            return BadRequest(new { message = "⚠️ Chưa cấu hình API Key Gemini trên máy chủ Backend." });
        }

        using var reader = new StreamReader(Request.Body, Encoding.UTF8);
        var contentString = await reader.ReadToEndAsync(cancellationToken);

        var url = $"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={apiKey}";
        using var content = new StringContent(contentString, Encoding.UTF8, "application/json");

        var response = await httpClient.PostAsync(url, content, cancellationToken);

        // Nếu model chính gặp 429 hoặc 503, thử chuyển ngay sang model dự phòng gemini-1.5-flash sau 1.5s (chỉ 1 lần duy nhất)
        if (response.StatusCode == System.Net.HttpStatusCode.TooManyRequests || response.StatusCode == System.Net.HttpStatusCode.ServiceUnavailable)
        {
            await Task.Delay(1500, cancellationToken);
            var fallbackModel = model == "gemini-2.0-flash" ? "gemini-1.5-flash" : "gemini-1.5-pro";
            var fallbackUrl = $"https://generativelanguage.googleapis.com/v1beta/models/{fallbackModel}:generateContent?key={apiKey}";
            using var retryContent = new StringContent(contentString, Encoding.UTF8, "application/json");
            response = await httpClient.PostAsync(fallbackUrl, retryContent, cancellationToken);
        }

        var responseString = await response.Content.ReadAsStringAsync(cancellationToken);
        return StatusCode((int)response.StatusCode, responseString);
    }
}
