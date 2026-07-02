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

        // Nếu model chính gặp lỗi (429 Rate Limit, 404, 503), chuyển sang model dự phòng theo thứ tự ưu tiên chuẩn Google AI Studio
        if (!response.IsSuccessStatusCode)
        {
            await Task.Delay(1000, cancellationToken);
            var fallbackModel = "gemini-2.0-flash-lite-preview-02-05";
            var fallbackUrl = $"https://generativelanguage.googleapis.com/v1beta/models/{fallbackModel}:generateContent?key={apiKey}";
            using var retryContent = new StringContent(contentString, Encoding.UTF8, "application/json");
            response = await httpClient.PostAsync(fallbackUrl, retryContent, cancellationToken);

            if (!response.IsSuccessStatusCode)
            {
                await Task.Delay(1000, cancellationToken);
                fallbackModel = "gemini-1.5-pro";
                var secondFallbackUrl = $"https://generativelanguage.googleapis.com/v1beta/models/{fallbackModel}:generateContent?key={apiKey}";
                using var secondRetryContent = new StringContent(contentString, Encoding.UTF8, "application/json");
                response = await httpClient.PostAsync(secondFallbackUrl, secondRetryContent, cancellationToken);
            }
        }

        var responseString = await response.Content.ReadAsStringAsync(cancellationToken);
        return StatusCode((int)response.StatusCode, responseString);
    }
}
