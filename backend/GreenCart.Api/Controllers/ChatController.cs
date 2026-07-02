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
        
        // Thử tối đa 3 lần với Exponential Backoff (chờ 3s -> 6s -> 10s) khi gặp 429 hoặc 503
        var delays = new[] { 3000, 6000, 10000 };
        HttpResponseMessage? response = null;

        for (int attempt = 0; attempt <= delays.Length; attempt++)
        {
            using var content = new StringContent(contentString, Encoding.UTF8, "application/json");
            response = await httpClient.PostAsync(url, content, cancellationToken);

            if (response.IsSuccessStatusCode)
            {
                break;
            }

            if ((response.StatusCode == System.Net.HttpStatusCode.TooManyRequests || 
                 response.StatusCode == System.Net.HttpStatusCode.ServiceUnavailable) && attempt < delays.Length)
            {
                await Task.Delay(delays[attempt], cancellationToken);
                
                // Nếu lần thử cuối cùng vẫn lỗi 429, thử chuyển tự động sang model gemini-1.5-flash làm phương án dự phòng
                if (attempt == delays.Length - 1 && model == "gemini-2.0-flash")
                {
                    url = $"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={apiKey}";
                }
            }
            else
            {
                break;
            }
        }

        var responseString = await response!.Content.ReadAsStringAsync(cancellationToken);
        return StatusCode((int)response.StatusCode, responseString);
    }
}
