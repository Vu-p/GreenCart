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
        var responseString = await response.Content.ReadAsStringAsync(cancellationToken);

        return StatusCode((int)response.StatusCode, responseString);
    }
}
