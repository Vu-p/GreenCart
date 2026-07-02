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

        var primaryResponse = response;

        // Nếu model chính gặp lỗi (429 Rate Limit, 404, 503), chuyển sang model dự phòng ổn định (stable universal models)
        if (!response.IsSuccessStatusCode)
        {
            await Task.Delay(500, cancellationToken);
            var fallbackModel = "gemini-1.5-flash";
            var fallbackUrl = $"https://generativelanguage.googleapis.com/v1beta/models/{fallbackModel}:generateContent?key={apiKey}";
            using var retryContent = new StringContent(contentString, Encoding.UTF8, "application/json");
            response = await httpClient.PostAsync(fallbackUrl, retryContent, cancellationToken);

            if (!response.IsSuccessStatusCode)
            {
                await Task.Delay(500, cancellationToken);
                fallbackModel = "gemini-1.5-flash-8b";
                var secondFallbackUrl = $"https://generativelanguage.googleapis.com/v1beta/models/{fallbackModel}:generateContent?key={apiKey}";
                using var secondRetryContent = new StringContent(contentString, Encoding.UTF8, "application/json");
                response = await httpClient.PostAsync(secondFallbackUrl, secondRetryContent, cancellationToken);
            }

            // Nếu tất cả các model đều lỗi và model chính ban đầu bị 429 (hết quota phút RPM), trả về đúng mã 429 để app hiện thông báo đợi
            if (!response.IsSuccessStatusCode && primaryResponse.StatusCode == System.Net.HttpStatusCode.TooManyRequests)
            {
                response = primaryResponse;
            }
        }

        var responseString = await response.Content.ReadAsStringAsync(cancellationToken);
        return StatusCode((int)response.StatusCode, responseString);
    }
}
